import SwiftUI
import UniformTypeIdentifiers

struct EditTripView: View {
    let trip: Trip
    let onTripUpdated: (Trip) -> Void
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var tripName: String
    @State private var selectedDate: Date
    @State private var startTime: Date
    @State private var arrivalTime: Date
    @State private var showingFilePicker = false
    @State private var selectedGPXFile: GPXFile?
    @State private var gpxParser = GPXParser()
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingGPXPreview = false
    
    init(trip: Trip, onTripUpdated: @escaping (Trip) -> Void) {
        self.trip = trip
        self.onTripUpdated = onTripUpdated
        
        // Initialiseer state met bestaande trip data
        _tripName = State(initialValue: trip.name)
        _selectedDate = State(initialValue: trip.date)
        _startTime = State(initialValue: trip.startTime)
        _arrivalTime = State(initialValue: trip.arrivalTime)
    }
    
    var body: some View {
        Form {
            Section("Trip Information".localized) {
                TextField("Enter trip name".localized, text: $tripName)
                
                DatePicker("Date".localized, selection: $selectedDate, displayedComponents: .date)
                
                DatePicker("Start time".localized, selection: $startTime, displayedComponents: .hourAndMinute)
                
                DatePicker("Arrival time".localized, selection: $arrivalTime, displayedComponents: .hourAndMinute)
            }
            
            Section("Route File".localized) {
                // Toon huidige GPX bestand
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text(trip.gpxFileName)
                            .font(.headline)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
                            let distanceUnit = useMetricUnits ? "km" : "mi"
                            let distanceValue = useMetricUnits ? trip.distance : trip.distance * 0.621371
                            
                            Text("Distance: \(String(format: "%.1f", distanceValue)) \(distanceUnit)".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            let speedUnit = useMetricUnits ? "km/h" : "mph"
                            let speedValue = useMetricUnits ? trip.averageSpeed : trip.averageSpeed * 0.621371
                            
                            Text("Avg. speed: \(String(format: "%.0f", speedValue)) \(speedUnit)".localized)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(trip.routePoints.count) route points".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                // Nieuwe GPX selectie
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("New GPX file is being loaded...".localized)
                            .foregroundColor(.secondary)
                    }
                } else if let newGPXFile = selectedGPXFile {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .foregroundColor(.green)
                            Text("New GPX file selected:".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
                                let distanceUnit = useMetricUnits ? "km" : "mi"
                                let distanceValue = useMetricUnits ? newGPXFile.distance : newGPXFile.distance * 0.621371
                                
                                Text("Afstand: \(String(format: "%.1f", distanceValue)) \(distanceUnit)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Bereken nieuwe gemiddelde snelheid
                                let calendar = Calendar.current
                                let startDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: startTime),
                                                               minute: calendar.component(.minute, from: startTime),
                                                               second: 0,
                                                               of: selectedDate) ?? startTime
                                
                                let arrivalDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: arrivalTime),
                                                                  minute: calendar.component(.minute, from: arrivalTime),
                                                                  second: 0,
                                                                  of: selectedDate) ?? arrivalTime
                                
                                let duration = arrivalDateTime.timeIntervalSince(startDateTime)
                                let avgSpeed = duration > 0 ? (distanceValue / AppConstants.secondsToHours(duration)) : 0
                                let speedUnit = useMetricUnits ? "km/h" : "mph"
                                let speedValue = useMetricUnits ? avgSpeed : avgSpeed * 0.621371
                                
                                Text("Nieuwe gem. snelheid: \(String(format: "%.0f", speedValue)) \(speedUnit)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(newGPXFile.pointCount) waypoints gevonden")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(newGPXFile.routePoints.count) route punten gebruikt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Bekijk route preview") {
                            showingGPXPreview = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: { showingFilePicker = true }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text(selectedGPXFile == nil ? "Nieuw GPX Bestand Selecteren" : "Ander GPX Bestand Selecteren")
                    }
                }
                .foregroundColor(.blue)
            }
            
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Section {
                Button(action: updateTrip) {
                    HStack {
                        Spacer()
                        Text("Opslaan")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!canSave)
                .foregroundColor(canSave ? .blue : .gray)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "gpx")!],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showingGPXPreview) {
            if let gpxFile = selectedGPXFile {
                GPXPreviewView(gpxFile: gpxFile)
            }
        }
    }
    
    private var canSave: Bool {
        !tripName.isEmpty && 
        startTime < arrivalTime
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        isLoading = true
        errorMessage = ""
        
        let (gpxFile, error) = FileImportHandler.handleFileImport(result, gpxParser: gpxParser)
        
        if let error = error {
            errorMessage = error
            selectedGPXFile = nil
        } else {
            selectedGPXFile = gpxFile
        }
        
        isLoading = false
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
    
    private func updateTrip() {
        print("🔄 EditTripView.updateTrip() called")
        print("   - Trip name: \(tripName)")
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
        
        // Controleer of de tijden zijn gewijzigd
        let timesChanged = abs(startDateTime.timeIntervalSince(trip.startTime)) > 60 || 
                          abs(arrivalDateTime.timeIntervalSince(trip.arrivalTime)) > 60
        
        print("   - Times changed: \(timesChanged)")
        print("   - Start time difference: \(abs(startDateTime.timeIntervalSince(trip.startTime))/60) minutes")
        print("   - Arrival time difference: \(abs(arrivalDateTime.timeIntervalSince(trip.arrivalTime))/60) minutes")
        
        let updatedTrip: Trip
        
        if let newGPXFile = selectedGPXFile {
            // Genereer route punten met timing via TripTimingCalculator
            let routePoints = TripTimingCalculator.generateRoutePointsWithTiming(
                from: newGPXFile.routePoints,
                startTime: startDateTime,
                arrivalTime: arrivalDateTime,
                totalDistance: newGPXFile.distance
            )
            
            // Als tijden zijn gewijzigd, wis de weather data (wordt opnieuw opgehaald)
            let weatherData = timesChanged ? [] : trip.weatherData
            
            print("   - New GPX file selected, weather data: \(weatherData.count) entries")
            
            // Maak nieuwe trip met nieuwe GPX data, maar behoud originele ID
            updatedTrip = Trip(
                id: trip.id, // Behoud originele ID
                name: tripName,
                date: selectedDate,
                startTime: startDateTime,
                arrivalTime: arrivalDateTime,
                distance: newGPXFile.distance,
                gpxFileName: newGPXFile.fileName,
                routePoints: routePoints,
                weatherData: weatherData, // Leeg als tijden zijn gewijzigd
                createdAt: trip.createdAt, // Behoud originele creation date
                updatedAt: Date(), // Update timestamp
                rainFocusEnabled: trip.rainFocusEnabled // Behoud rain focus setting
            )
        } else {
            // Update alleen timing
            // Behoud de originele volgorde van route points door ze te sorteren op segmentIndex
            let sortedRoutePoints = trip.routePoints.sorted { $0.segmentIndex < $1.segmentIndex }
            
            let routePoints = TripTimingCalculator.generateRoutePointsWithTiming(
                from: sortedRoutePoints.map { routePoint in
                    GPXWaypoint(
                        latitude: routePoint.latitude,
                        longitude: routePoint.longitude,
                        elevation: nil,
                        time: nil,
                        name: ""
                    )
                },
                startTime: startDateTime,
                arrivalTime: arrivalDateTime,
                totalDistance: trip.distance
            )
            
            // Als tijden zijn gewijzigd, wis de weather data (wordt opnieuw opgehaald)
            let weatherData = timesChanged ? [] : trip.weatherData
            
            print("   - Only timing updated, weather data: \(weatherData.count) entries")
            print("   - Original route points count: \(trip.routePoints.count)")
            print("   - Sorted route points count: \(sortedRoutePoints.count)")
            print("   - Generated route points count: \(routePoints.count)")
            
            // Update alleen timing, behoud bestaande GPX data en ID
            updatedTrip = Trip(
                id: trip.id, // Behoud originele ID
                name: tripName,
                date: selectedDate,
                startTime: startDateTime,
                arrivalTime: arrivalDateTime,
                distance: trip.distance,
                gpxFileName: trip.gpxFileName,
                routePoints: routePoints,
                weatherData: weatherData, // Leeg als tijden zijn gewijzigd
                createdAt: trip.createdAt, // Behoud originele creation date
                updatedAt: Date(), // Update timestamp
                rainFocusEnabled: trip.rainFocusEnabled // Behoud rain focus setting
            )
        }
        
        print("   - Updated trip created:")
        print("     - Route points: \(updatedTrip.routePoints.count)")
        print("     - Weather data: \(updatedTrip.weatherData.count)")
        print("     - Start time: \(updatedTrip.startTime)")
        print("     - Arrival time: \(updatedTrip.arrivalTime)")
        
        // Roep de callback aan met de bijgewerkte trip
        onTripUpdated(updatedTrip)
    }
}



#Preview {
    let testTrip = Trip(
        name: "Test Trip",
        date: Date(),
        startTime: Date(),
        arrivalTime: Date().addingTimeInterval(AppConstants.Trip.defaultDuration),
        distance: 50.0,
        gpxFileName: "test.gpx"
    )
    
    EditTripView(trip: testTrip, onTripUpdated: { _ in })
        .environmentObject(LanguageManager.shared)
}
