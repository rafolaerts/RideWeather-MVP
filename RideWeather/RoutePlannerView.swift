//
//  RoutePlannerView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct RoutePlannerView: View {
    @Environment(\.dismiss) private var dismiss
    let coreDataStore: CoreDataTripStore
    @EnvironmentObject var languageManager: LanguageManager
    
    @StateObject private var routeService = MapKitRouteService()
    @StateObject private var locationDelegate = LocationManagerDelegate()
    @State private var locationManager = CLLocationManager()
    
    init(coreDataStore: CoreDataTripStore, tripName: Binding<String>, selectedDate: Binding<Date>, startTime: Binding<Date>, arrivalTime: Binding<Date>, onSave: @escaping () -> Void) {
        self.coreDataStore = coreDataStore
        self._tripName = tripName
        self._selectedDate = selectedDate
        self._startTime = startTime
        self._arrivalTime = arrivalTime
        self.onSave = onSave
    }
    
    @Binding var tripName: String
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    @Binding var arrivalTime: Date
    let onSave: () -> Void
    
    // Route planning states
    @State private var startLocationType: LocationInputType = .custom
    @State private var startAddress = ""
    @State private var destinationAddress = ""
    @State private var waypoints: [String] = []
    @State private var routeType: RouteType = .fastest
    @State private var avoidHighways = false
    @State private var avoidTolls = false
    @State private var maxRoutePoints: Int = 10 // Aantal route punten voor weer data
    
    // UI states
    @State private var showingStartLocationPicker = false
    @State private var showingDestinationPicker = false
    @State private var showingWaypointPicker = false
    @State private var showingRoutePreview = false
    @State private var plannedRoute: PlannedRoute?
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    // POI search
    @State private var poiSearchQuery = ""
    @State private var poiSearchResults: [MKMapItem] = []
    @State private var isSearchingPOI = false
    
    var body: some View {
        NavigationView {
            Form {
                // Trip Information Section
                tripInformationSection
                
                // Route Planning Section
                routePlanningSection
                
                // Route Options Section
                routeOptionsSection
                
                // Route Points Configuration Section
                routePointsSection
                
                // Waypoints Section
                waypointsSection
                
                // POI Search Section
                poiSearchSection
                
                // Error Section
                if !errorMessage.isEmpty {
                    errorSection
                }
                
                // Loading Section
                if isLoading {
                    loadingSection
                }
            }
            .navigationTitle("Route Planning".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Plan Route".localized) {
                        planRoute()
                    }
                    .disabled(!canPlanRoute)
                }
            }
            .sheet(isPresented: $showingStartLocationPicker) {
                LocationPickerView(
                    title: "Start Locatie",
                    searchQuery: $startAddress,
                    onLocationSelected: { location in
                        startAddress = location
                        showingStartLocationPicker = false
                    }
                )
            }
            .sheet(isPresented: $showingDestinationPicker) {
                LocationPickerView(
                    title: "Bestemming",
                    searchQuery: $destinationAddress,
                    onLocationSelected: { location in
                        destinationAddress = location
                        showingDestinationPicker = false
                    }
                )
            }
            .sheet(isPresented: $showingWaypointPicker) {
                LocationPickerView(
                    title: "Waypoint Toevoegen",
                    searchQuery: .constant(""),
                    onLocationSelected: { location in
                        addWaypoint(location)
                        showingWaypointPicker = false
                    }
                )
            }
            .sheet(isPresented: $showingRoutePreview) {
                if let route = plannedRoute {
                    RoutePreviewView(
                        plannedRoute: route,
                        onConfirm: {
                            saveTrip()
                        },
                        onCancel: {
                            showingRoutePreview = false
                        }
                    )
                }
            }
            .onAppear {
                // Configureer location manager
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.delegate = locationDelegate
                requestLocationPermission()
            }
            .onReceive(locationDelegate.$authorizationStatus) { status in
                print("🔄 Locatie permissie status gewijzigd: \(status.rawValue)")
            }
        }
    }
    
    // MARK: - Trip Information Section
    
    private var tripInformationSection: some View {
        Section("Trip Informatie") {
            HStack {
                Text("Trip naam:")
                Spacer()
                TextField("Trip naam", text: $tripName)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Datum:")
                Spacer()
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
            }
            
            HStack {
                Text("Start tijd:")
                Spacer()
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            
            HStack {
                Text("Aankomst tijd:")
                Spacer()
                DatePicker("", selection: $arrivalTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        }
    }
    
    // MARK: - Route Planning Section
    
    private var routePlanningSection: some View {
        Section("ROUTE PLANNING") {
            // Start location
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Start locatie")
                        .font(.headline)
                    Spacer()
                    Picker("Start locatie type", selection: $startLocationType) {
                        Text("Huidige locatie").tag(LocationInputType.current)
                        Text("Aangepast adres").tag(LocationInputType.custom)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                if startLocationType == .custom {
                    HStack {
                        TextField("Start adres", text: $startAddress)
                        
                        Button(action: { showingStartLocationPicker = true }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Destination
            VStack(alignment: .leading, spacing: 8) {
                Text("Bestemming")
                    .font(.headline)
                
                HStack {
                    TextField("Bestemming adres", text: $destinationAddress)
                    
                    Button(action: { showingDestinationPicker = true }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Route Options Section
    
    private var routeOptionsSection: some View {
        Section("ROUTE OPTIES") {
            Picker("Route type", selection: $routeType) {
                ForEach(RouteType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)
            
            Toggle("Vermijd snelwegen", isOn: $avoidHighways)
            
            Toggle("Vermijd tolwegen", isOn: $avoidTolls)
        }
    }
    
    // MARK: - Route Points Configuration Section
    
    private var routePointsSection: some View {
        Section("ROUTE PUNTEN VOOR WEER DATA") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Aantal route punten")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(maxRoutePoints)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(minWidth: 40)
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { Double(maxRoutePoints) },
                                set: { 
                                    let newValue = Int($0)
                                    print("🔄 Slider moved: \(maxRoutePoints) -> \(newValue)")
                                    maxRoutePoints = newValue
                                }
                            ),
                            in: 2...20,
                            step: 1
                        )
                        .accentColor(.blue)
                        
                        HStack {
                            Text("2")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("20")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 120)
                }
                
                Text("Deze punten worden proportioneel verdeeld over de route voor weer data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Waypoints Section
    
    private var waypointsSection: some View {
        Section("WAYPOINTS") {
            if waypoints.isEmpty {
                Text("Geen waypoints toegevoegd")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(waypoints.enumerated()), id: \.offset) { index, waypoint in
                    HStack {
                        Text("\(index + 1).")
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(waypoint)
                        
                        Spacer()
                        
                        Button(action: { removeWaypoint(at: index) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Button(action: { showingWaypointPicker = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Waypoint Toevoegen")
                }
                .foregroundColor(.blue)
            }
            .disabled(waypoints.count >= 20) // Max 20 waypoints
        }
    }
    
    // MARK: - POI Search Section
    
    private var poiSearchSection: some View {
        Section("POI ZOEKEN") {
            HStack {
                TextField("Zoek naar plaatsen...", text: $poiSearchQuery)
                
                Button(action: searchPOIs) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                }
                .disabled(poiSearchQuery.isEmpty)
            }
            
            if isSearchingPOI {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Zoeken...")
                        .foregroundColor(.secondary)
                }
            }
            
            if !poiSearchResults.isEmpty {
                ForEach(poiSearchResults, id: \.self) { item in
                    Button(action: { selectPOI(item) }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Onbekende locatie")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            if let address = item.placemark.thoroughfare {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
    
    // MARK: - Error Section
    
    private var errorSection: some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        Section {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Route berekenen...")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canPlanRoute: Bool {
        !tripName.isEmpty && 
        !destinationAddress.isEmpty &&
        (startLocationType == .current || (startLocationType == .custom && !startAddress.isEmpty))
    }
    
    // MARK: - Helper Methods
    
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        
        // Controleer permissie status
        switch locationDelegate.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Locatie permissie verleend")
        case .denied, .restricted:
            print("❌ Locatie permissie geweigerd")
        case .notDetermined:
            print("⏳ Locatie permissie nog niet bepaald")
        @unknown default:
            print("❓ Onbekende locatie permissie status")
        }
    }
    
    private func addWaypoint(_ location: String) {
        guard waypoints.count < 20 else { return }
        waypoints.append(location)
    }
    
    private func removeWaypoint(at index: Int) {
        waypoints.remove(at: index)
    }
    
    private func searchPOIs() {
        guard !poiSearchQuery.isEmpty else { return }
        
        isSearchingPOI = true
        poiSearchResults.removeAll()
        
        Task {
            do {
                let results = try await routeService.searchPOIs(query: poiSearchQuery)
                await MainActor.run {
                    poiSearchResults = results
                    isSearchingPOI = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "POI zoeken mislukt: \(error.localizedDescription)"
                    isSearchingPOI = false
                }
            }
        }
    }
    
    private func selectPOI(_ item: MKMapItem) {
        let address = formatAddress(from: item.placemark)
        
        if destinationAddress.isEmpty {
            destinationAddress = address
        } else if startAddress.isEmpty && startLocationType == .custom {
            startAddress = address
        } else {
            addWaypoint(address)
        }
        
        poiSearchQuery = ""
        poiSearchResults.removeAll()
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            components.append(subThoroughfare)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func planRoute() {
        guard canPlanRoute else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Maak route request
                let request = try await createRouteRequest()
                
                // Plan route
                let route = try await routeService.planRoute(request: request)
                
                await MainActor.run {
                    plannedRoute = route
                    isLoading = false
                    showingRoutePreview = true
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Route plannen mislukt: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func createRouteRequest() async throws -> RouteRequest {
        // Bepaal start locatie
        let startLocation: RouteLocation
        
        if startLocationType == .current {
            let currentCoord = try await routeService.getCurrentLocation()
            startLocation = RouteLocation(
                coordinate: currentCoord,
                address: nil,
                name: "Huidige locatie"
            )
        } else {
            startLocation = RouteLocation(
                coordinate: nil,
                address: startAddress,
                name: nil
            )
        }
        
        // Maak bestemming
        let destination = RouteLocation(
            coordinate: nil,
            address: destinationAddress,
            name: nil
        )
        
        // Maak waypoints
        let routeWaypoints = waypoints.map { waypoint in
            RouteLocation(coordinate: nil, address: waypoint, name: nil)
        }
        
        return RouteRequest(
            startLocation: startLocation,
            destination: destination,
            waypoints: routeWaypoints,
            routeType: routeType,
            avoidHighways: avoidHighways,
            avoidTolls: avoidTolls,
            maxRoutePoints: maxRoutePoints
        )
    }
    
    // Helper functie om tijd componenten te combineren met geselecteerde datum
    private func combineDateWithTime(_ time: Date, on date: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = 0
        
        return calendar.date(from: combinedComponents) ?? time
    }
    
    private func saveTrip() {
        guard let route = plannedRoute else { return }
        
        print("🔄 RoutePlannerView.saveTrip() called")
        print("   - Selected date: \(selectedDate)")
        print("   - Start time from DatePicker (local): \(startTime)")
        print("   - Arrival time from DatePicker (local): \(arrivalTime)")
        
        // Combineer de geselecteerde datum met de gekozen tijden
        let startDateTime = combineDateWithTime(startTime, on: selectedDate)
        let arrivalDateTime = combineDateWithTime(arrivalTime, on: selectedDate)
        
        print("   - Combined start date/time: \(startDateTime)")
        print("   - Combined arrival date/time: \(arrivalDateTime)")
        
        // De DatePicker geeft al lokale tijd door, dus geen conversie nodig
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        
        print("   - Current timezone: \(timeZone.identifier)")
        print("   - DatePicker times are already in local time")
        
        // Haal de tijd componenten op uit de gecombineerde tijden
        let startHour = calendar.component(.hour, from: startDateTime)
        let startMinute = calendar.component(.minute, from: startDateTime)
        let arrivalHour = calendar.component(.hour, from: arrivalDateTime)
        let arrivalMinute = calendar.component(.minute, from: arrivalDateTime)
        
        print("   - Extracted start time (local): \(startHour):\(startMinute)")
        print("   - Extracted arrival time (local): \(arrivalHour):\(arrivalMinute)")
        
        print("   - Using start date/time (local): \(startDateTime)")
        print("   - Using arrival date/time (local): \(arrivalDateTime)")
        print("   - Start timezone: \(timeZone.identifier)")
        print("   - Arrival timezone: \(timeZone.identifier)")
        
        // Genereer route punten met timing
        let routePoints = TripTimingCalculator.generateRoutePointsWithTiming(
            from: route.routePoints,
            startTime: startDateTime,
            arrivalTime: arrivalDateTime,
            totalDistance: route.distance
        )
        
        // Maak nieuwe trip
        let newTrip = Trip(
            name: tripName,
            date: selectedDate,
            startTime: startDateTime,
            arrivalTime: arrivalDateTime,
            distance: route.distance,
            gpxFileName: "Geplande route", // Geen GPX bestand
            routePoints: routePoints
        )
        
        // Sla op in Core Data
        coreDataStore.addTrip(newTrip)
        
        // Call onSave callback
        onSave()
    }
}

// MARK: - Location Input Type

enum LocationInputType {
    case current
    case custom
}

// MARK: - Location Picker View

struct LocationPickerView: View {
    let title: String
    @Binding var searchQuery: String
    let onLocationSelected: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Zoek naar adres...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Zoeken") {
                        searchLocations()
                    }
                    .disabled(searchText.isEmpty)
                }
                .padding()
                
                // Search results
                if isSearching {
                    HStack {
                        ProgressView()
                        Text("Zoeken...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        Button(action: { selectLocation(item) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Onbekende locatie")
                                    .font(.body)
                                
                                let address = formatAddress(from: item.placemark)
                                if !address.isEmpty {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } else if !searchText.isEmpty {
                    Text("Geen resultaten gevonden")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchLocations() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchResults.removeAll()
        
        Task {
            do {
                let results = try await MapKitRouteService().searchPOIs(query: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        let address = formatAddress(from: item.placemark)
        onLocationSelected(address)
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            components.append(subThoroughfare)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - Location Manager Delegate

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates if needed
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error)")
    }
}

#Preview {
    RoutePlannerView(
        coreDataStore: CoreDataTripStore(),
        tripName: .constant("Test Trip"),
        selectedDate: .constant(Date()),
        startTime: .constant(Date()),
        arrivalTime: .constant(Date().addingTimeInterval(3600)),
        onSave: {}
    )
    .environmentObject(LanguageManager.shared)
}
