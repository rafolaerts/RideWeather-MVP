//
//  AddTripView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreLocation

// MARK: - AddTripView

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss
    let coreDataStore: CoreDataTripStore
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var tripName = ""
    @State private var selectedDate = Date()
    @State private var startTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var arrivalTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    
    // Tab selection
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Route Type", selection: $selectedTab) {
                    Text("GPX Import").tag(0)
                    Text("Route Planning").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    GPXImportTab(
                        tripName: $tripName,
                        selectedDate: $selectedDate,
                        startTime: $startTime,
                        arrivalTime: $arrivalTime,
                        coreDataStore: coreDataStore,
                        onSave: { dismiss() }
                    )
                } else {
                    RoutePlannerTab(
                        coreDataStore: coreDataStore,
                        tripName: $tripName,
                        selectedDate: $selectedDate,
                        startTime: $startTime,
                        arrivalTime: $arrivalTime,
                        onSave: { dismiss() }
                    )
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - GPX Import Tab

struct GPXImportTab: View {
    @Binding var tripName: String
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    @Binding var arrivalTime: Date
    let coreDataStore: CoreDataTripStore
    let onSave: () -> Void
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var showingFilePicker = false
    @State private var selectedGPXFile: GPXFile?
    @State private var gpxParser = GPXParser()
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var distanceBetweenPoints: Double = 10.0 // Afstand tussen routepunten in km
    
    // Bereken het aantal routepunten op basis van afstand tussen punten
    private var calculatedRoutePoints: Int {
        guard let gpxFile = selectedGPXFile else { return 0 }
        return Int(floor(gpxFile.distance / distanceBetweenPoints)) + 1
    }
    
    // Valideer of de gekozen afstand geldig is
    private var isDistanceValid: Bool {
        guard let gpxFile = selectedGPXFile else { return true }
        return distanceBetweenPoints <= gpxFile.distance
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
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Trip name:")
                    Spacer()
                    TextField("Enter trip name", text: $tripName)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Date:")
                    Spacer()
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                }
                
                HStack {
                    Text("Start time:")
                    Spacer()
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                HStack {
                    Text("Arrival time:")
                    Spacer()
                    DatePicker("", selection: $arrivalTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            } header: {
                Text("Trip Information")
            }
            
            Section {
                if let gpxFile = selectedGPXFile {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("GPX file loaded: \(gpxFile.fileName)")
                                .font(.headline)
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total distance: \(String(format: "%.1f", gpxFile.distance)) km")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                let avgSpeed = 60.0 // Standaard snelheid voor preview
                                let speedUnit = "km/h"
                                Text("Estimated avg. speed: \(String(format: "%.0f", avgSpeed)) \(speedUnit)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(gpxFile.pointCount) waypoints found")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(gpxFile.routePoints.count) route points used")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Route punten instelling - Afstandsgebaseerd
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Route points setting")
                            .font(.headline)
                        
                        // Afstand tussen routepunten slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Distance between route points:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(String(format: "%.0f", distanceBetweenPoints)) km")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            Slider(
                                value: $distanceBetweenPoints,
                                in: 10...100,
                                step: 1
                            )
                            .accentColor(.blue)
                            .onChange(of: distanceBetweenPoints) { _, newValue in
                                print("🔄 Distance between points changed to: \(newValue) km")
                                // Herverwerk GPX bestand met nieuwe afstand
                                Task {
                                    await reprocessGPXFile(with: newValue)
                                }
                            }
                            
                            HStack {
                                Text("10 km")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("100 km")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Resultaat en validatie
                        VStack(alignment: .leading, spacing: 8) {
                            if isDistanceValid {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Route points: \(calculatedRoutePoints)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("This will create \(calculatedRoutePoints) route points with \(String(format: "%.0f", distanceBetweenPoints)) km spacing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Route length must be larger than point spacing")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                                
                                Text("Please reduce the distance between points")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(isDistanceValid ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button("Select different GPX file") {
                        showingFilePicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                } else {
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Select GPX File")
                        }
                    }
                    
                    // Help sectie voor permissie problemen
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Tips voor GPX import:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("• Zorg dat je GPX bestand toegankelijk is in de Bestanden app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Controleer of je toegang hebt tot de bestanden")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Probeer het bestand opnieuw te importeren")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            } header: {
                Text("ROUTE FILE")
            }
            
            if isLoading {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("GPX bestand verwerken...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !errorMessage.isEmpty {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Save button
            Section {
                Button("Trip Opslaan") {
                    saveTrip()
                }
                .disabled(tripName.isEmpty || selectedGPXFile == nil)
                .frame(maxWidth: .infinity)
                .padding()
                .background(tripName.isEmpty || selectedGPXFile == nil ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "gpx")!],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            isLoading = true
            errorMessage = ""
            
            // Start background processing
            Task {
                do {
                    let gpxFile = try gpxParser.parseGPXFile(from: url, distanceBetweenPoints: distanceBetweenPoints)
                    
                    await MainActor.run {
                        selectedGPXFile = gpxFile
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Fout bij het laden van GPX bestand: \(error.localizedDescription)"
                        isLoading = false
                    }
                }
            }
            
        case .failure(let error):
            errorMessage = "Error selecting file: \(error.localizedDescription)"
        }
    }
    
    private func reprocessGPXFile(with newDistanceBetweenPoints: Double) async {
        guard let gpxFile = selectedGPXFile else { 
            print("⚠️ Geen GPX bestand geselecteerd voor herverwerking")
            return 
        }
        
        print("🔄 Herverwerken GPX bestand met \(newDistanceBetweenPoints) km tussen routepunten")
        print("   - Originele punten: \(gpxFile.originalPoints.count)")
        print("   - Huidige route punten: \(gpxFile.routePoints.count)")
        
        isLoading = true
        
        do {
            // Herverwerk het bestaande GPX bestand met nieuwe afstand tussen routepunten
            let reprocessedGPXFile = try gpxParser.reprocessGPXFile(gpxFile, with: newDistanceBetweenPoints)
            
            print("✅ GPX bestand herverwerkt:")
            print("   - Nieuwe route punten: \(reprocessedGPXFile.routePoints.count)")
            print("   - Originele punten behouden: \(reprocessedGPXFile.originalPoints.count)")
            
            await MainActor.run {
                selectedGPXFile = reprocessedGPXFile
                isLoading = false
            }
        } catch {
            print("❌ Fout bij herverwerken GPX bestand: \(error)")
            await MainActor.run {
                errorMessage = "Error reprocessing GPX file: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func saveTrip() {
        guard let gpxFile = selectedGPXFile else { return }
        
        print("🔄 GPXImportTab.saveTrip() called")
        print("   - GPX file: \(gpxFile.fileName)")
        print("   - GPX route points count: \(gpxFile.routePoints.count)")
        print("   - GPX original points count: \(gpxFile.originalPoints.count)")
        print("   - GPX distance: \(gpxFile.distance) km")
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
        
        // Gebruik de originele GPX punten als de route punten leeg zijn
        let waypointsToUse = gpxFile.routePoints.isEmpty ? gpxFile.originalPoints : gpxFile.routePoints
        print("   - Using waypoints count: \(waypointsToUse.count)")
        
        // Genereer route punten met timing via TripTimingCalculator
        let routePoints = TripTimingCalculator.generateRoutePointsWithTiming(
            from: waypointsToUse,
            startTime: startDateTime,
            arrivalTime: arrivalDateTime,
            totalDistance: gpxFile.distance
        )
        
        print("   - Generated route points count: \(routePoints.count)")
        
        // Create new trip
        let newTrip = Trip(
            name: tripName,
            date: selectedDate,
            startTime: startDateTime,
            arrivalTime: arrivalDateTime,
            distance: gpxFile.distance,
            gpxFileName: gpxFile.fileName,
            routePoints: routePoints
        )
        
        print("   - New trip route points count: \(newTrip.routePoints.count)")
        
        // Save to Core Data
        coreDataStore.addTrip(newTrip)
        
        // Call onSave callback
        onSave()
    }
}

// MARK: - Route Planner Tab

struct RoutePlannerTab: View {
    let coreDataStore: CoreDataTripStore
    @Binding var tripName: String
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    @Binding var arrivalTime: Date
    let onSave: () -> Void
    
    var body: some View {
        RoutePlannerView(
            coreDataStore: coreDataStore,
            tripName: $tripName,
            selectedDate: $selectedDate,
            startTime: $startTime,
            arrivalTime: $arrivalTime,
            onSave: onSave
        )
    }
}

#Preview {
    AddTripView(coreDataStore: CoreDataTripStore())
        .environmentObject(LanguageManager.shared)
}
