//
//  TripDetailView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI
import CoreLocation
import MapKit

struct TripDetailView: View {
    let trip: Trip
    let coreDataStore: CoreDataTripStore
    @EnvironmentObject var languageManager: LanguageManager

    @State private var isRefreshing = false
    @State private var showingEditTrip = false
    @State private var isEditingTrip = false
    @State private var showingRainFocus = false // Lokale state voor de toggle
    @State private var weatherService = WeatherService()
    @State private var apiKeyStatusManager = APIKeyStatusManager()
    @State private var weatherData: [WeatherSnapshot] = []
    @State private var currentTrip: Trip // Lokale kopie van de trip die kan worden bijgewerkt
    
    init(trip: Trip, coreDataStore: CoreDataTripStore) {
        self.trip = trip
        self.coreDataStore = coreDataStore
        self._currentTrip = State(initialValue: trip)
    }
    
    var body: some View {
        Group {
            if isEditingTrip {
                // Toon EditTripView inline
                EditTripView(trip: currentTrip, onTripUpdated: { updatedTrip in
                    print("🔄 TripDetailView onTripUpdated callback triggered")
                    print("   - Updated trip ID: \(updatedTrip.id)")
                    print("   - Updated trip name: \(updatedTrip.name)")
                    print("   - Current isEditingTrip state: \(isEditingTrip)")
                    
                    // Update trip in TripStore
                    coreDataStore.updateTrip(updatedTrip)
                    print("✅ Trip updated in TripStore")
                    
                    // Update local trip reference
                    currentTrip = updatedTrip
                    print("✅ Local trip reference updated")
                    
                    // Ga terug naar detail view
                    print("🔄 Setting isEditingTrip to false")
                    isEditingTrip = false
                    print("✅ isEditingTrip set to false")
                    
                    // Trigger weather refresh
                    print("🔄 Triggering weather refresh")
                    Task {
                        await refreshWeatherAsync()
                    }
                })
                .navigationTitle("Edit Trip".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel".localized) {
                            isEditingTrip = false
                        }
                    }

                }
            } else {
                // Toon normale detail view
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Trip Samenvatting
                        TripSummaryCard(trip: currentTrip, weatherData: weatherData)
                        
                        // Route Kaart
                        if !currentTrip.routePoints.isEmpty {
                            RouteMapView(trip: currentTrip)
                                .frame(height: 250)
                                .padding(.horizontal)
                        }
                        
                        // Rain Focus Toggle
                        HStack {
                            Button(action: {
                                print("🔄 Rain focus button tapped")
                                print("   - Current showingRainFocus: \(showingRainFocus)")
                                print("   - Current trip rainFocusEnabled: \(currentTrip.rainFocusEnabled)")
                                
                                // Toggle de lokale state
                                showingRainFocus.toggle()
                                print("   - New showingRainFocus: \(showingRainFocus)")
                                
                                // Update de trip met de nieuwe waarde
                                currentTrip.rainFocusEnabled = showingRainFocus
                                print("   - Updated trip rainFocusEnabled: \(currentTrip.rainFocusEnabled)")
                                
                                // Sla de trip op in de store
                                coreDataStore.updateTrip(currentTrip)
                                print("   - Trip update completed")
                                
                                // Haal de bijgewerkte trip op uit de store om te controleren
                                if let updatedTrip = coreDataStore.trip(withId: currentTrip.id) {
                                    print("   - Store trip rainFocusEnabled: \(updatedTrip.rainFocusEnabled)")
                                    print("   - Local showingRainFocus: \(showingRainFocus)")
                                    print("   - Local trip rainFocusEnabled: \(currentTrip.rainFocusEnabled)")
                                } else {
                                    print("❌ Could not retrieve updated trip from store")
                                }
                                
                                print("✅ Rain focus update completed")
                            }) {
                                HStack {
                                    Image(systemName: showingRainFocus ? "eye.fill" : "eye.slash")
                                        .foregroundColor(showingRainFocus ? .blue : .gray)
                                    Text("Rain Focus".localized)
                                        .foregroundColor(showingRainFocus ? .blue : .primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            Button(action: refreshWeather) {
                                HStack {
                                    if isRefreshing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("Refresh".localized)
                                }
                                .foregroundColor(.blue)
                            }
                            .disabled(isRefreshing)
                        }
                        .padding(.horizontal)
                        
                        // Route Punten
                        if currentTrip.routePoints.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "map")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No route points".localized)
                                    .font(.headline)
                                Text("Route points are calculated after GPX import".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(currentTrip.routePoints.sorted { $0.segmentIndex < $1.segmentIndex }) { point in
                                    RoutePointRow(
                                        point: point,
                                        weather: weatherForPoint(point),
                                        showRainFocus: showingRainFocus,
                                        coreDataStore: coreDataStore
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle(currentTrip.name)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit".localized) {
                            isEditingTrip = true
                        }
                    }
                }
            }
        }
        .refreshable {
            await refreshWeatherAsync()
        }

        .onAppear {
            print("📱 TripDetailView appeared for trip: \(currentTrip.name)")
            print("   - Current trip start time: \(currentTrip.startTime)")
            print("   - Current trip arrival time: \(currentTrip.arrivalTime)")
            print("   - Current trip date: \(currentTrip.date)")
            print("   - Current trip rainFocusEnabled: \(currentTrip.rainFocusEnabled)")
            print("   - Local showingRainFocus: \(showingRainFocus)")
            print("   - isEditingTrip state: \(isEditingTrip)")
            
            // Stel delegate in voor API key status monitoring
            print("🔧 TripDetailView: Setting API key status delegate...")
            weatherService.apiKeyStatusDelegate = apiKeyStatusManager
            print("🔧 TripDetailView: Delegate set: \(weatherService.apiKeyStatusDelegate != nil ? "YES" : "NO")")
            
            // Synchroniseer altijd de lokale state met de opgeslagen waarde uit Core Data
            synchronizeRainFocusState()
        }
        .onChange(of: coreDataStore.trips) { _, _ in
            // Synchroniseer de lokale state wanneer trips in de store veranderen
            print("🔄 Trips in store changed, synchronizing rain focus state")
            synchronizeRainFocusState()
        }
    }
    
    private func weatherForPoint(_ point: RoutePoint) -> WeatherSnapshot? {
        return weatherData.first { weather in
            let weatherLocation = CLLocation(latitude: weather.latitude, longitude: weather.longitude)
            let pointLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
            let distance = weatherLocation.distance(from: pointLocation)
            return distance < 1000 // Binnen 1km van het route punt
        }
    }
    
    private func synchronizeRainFocusState() {
        print("🔄 Synchronizing rain focus state...")
        
        // Probeer eerst opgeslagen trip data te laden uit Core Data
        if let savedTrip = coreDataStore.trip(withId: currentTrip.id) {
            print("🔄 Found saved trip in store, updating currentTrip")
            print("   - Store trip rainFocusEnabled: \(savedTrip.rainFocusEnabled)")
            
            // Update currentTrip met data uit store
            currentTrip = savedTrip
            
            // Synchroniseer de lokale showingRainFocus state
            showingRainFocus = savedTrip.rainFocusEnabled
            
            print("✅ Current trip updated from store")
            print("   - Updated trip rainFocusEnabled: \(currentTrip.rainFocusEnabled)")
            print("   - Updated local showingRainFocus: \(showingRainFocus)")
            
            // Laad ook de weerdata direct uit de opgeslagen trip
            weatherData = savedTrip.weatherData
            print("📱 Loaded weather data from saved trip: \(weatherData.count) snapshots")
            
            // Als er geen weather data is, haal deze dan automatisch op
            if weatherData.isEmpty {
                print("🔄 No weather data available, automatically fetching weather")
                Task {
                    await refreshWeatherAsync()
                }
            }
        } else {
            print("❌ No saved trip found in store for ID: \(currentTrip.id)")
            print("   - Available trips in store: \(coreDataStore.trips.map { $0.id })")
            
            // Als er geen opgeslagen trip is gevonden, probeer dan de trip te vinden in de trips array
            if let tripFromArray = coreDataStore.trips.first(where: { $0.id == currentTrip.id }) {
                print("🔄 Found trip in trips array, updating currentTrip")
                print("   - Array trip rainFocusEnabled: \(tripFromArray.rainFocusEnabled)")
                
                currentTrip = tripFromArray
                showingRainFocus = tripFromArray.rainFocusEnabled
                
                print("✅ Current trip updated from trips array")
                print("   - Updated trip rainFocusEnabled: \(currentTrip.rainFocusEnabled)")
                print("   - Updated local showingRainFocus: \(showingRainFocus)")
                
                // Laad weather data uit de trip uit de array
                weatherData = tripFromArray.weatherData
                print("📱 Loaded weather data from array trip: \(weatherData.count) snapshots")
                
                // Als er geen weather data is, haal deze dan automatisch op
                if weatherData.isEmpty {
                    print("🔄 No weather data available, automatically fetching weather")
                    Task {
                        await refreshWeatherAsync()
                    }
                }
            }
        }
    }
    
    private func refreshWeather() {
        Task {
            await refreshWeatherAsync()
        }
    }
    
    private func refreshWeatherAsync() async {
        isRefreshing = true
        
        print("🔄 Starting weather refresh for trip: \(currentTrip.name)")
        print("   - Current weather data count: \(weatherData.count)")
        print("   - Current trip ID: \(currentTrip.id)")
        print("   - Current trip name: \(currentTrip.name)")
        
        do {
            let newWeatherData = try await weatherService.fetchWeatherForTrip(currentTrip)
            
            print("✅ Weather data received from service:")
            print("   - New weather data count: \(newWeatherData.count)")
            for (index, weather) in newWeatherData.enumerated() {
                print("      - \(index + 1): \(weather.description) at (\(String(format: "%.4f", weather.latitude)), \(String(format: "%.4f", weather.longitude)))")
            }
            
            await MainActor.run {
                print("📱 Updating local weather data on main thread")
                print("   - Old weather data count: \(weatherData.count)")
                
                // Update alleen de lokale weather data, niet de TripStore
                weatherData = newWeatherData
                
                print("📱 Updated local weather data: \(weatherData.count) items")
                print("   - New weather data count: \(weatherData.count)")
                
                // Sla weather data op in TripStore ZONDER UI update te triggeren
                // Dit voorkomt dat de onChange handler wordt getriggerd
                print("💾 Saving weather data to TripStore (silent update)")
                coreDataStore.updateWeatherData(for: currentTrip.id, weatherData: newWeatherData)
                print("💾 Weather data saved to TripStore for trip: \(currentTrip.id)")
                
                isRefreshing = false
                print("✅ Weather refresh completed successfully")
            }
        } catch {
            await MainActor.run {
                isRefreshing = false
                // Toon foutmelding aan gebruiker
                print("❌ Fout bij vernieuwen weer: \(error)")
            }
        }
    }
}

// TripSummaryCard moved to TripSummaryCard.swift

// RoutePointRow moved to RoutePointRow.swift

// RouteMapView and related components moved to RouteMapView.swift

// Preview removed - components are now in separate files

// Commented preview code removed

// TripDetailView gebruikt de bestaande APIKeyStatusManager uit TripListView
