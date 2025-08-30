//
//  CoreDataTripStore.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import SwiftUI
import CoreData
import Observation

@Observable
class CoreDataTripStore {
    var trips: [Trip] = []
    var isLoading = false
    var error: Error?
    
    private let context: NSManagedObjectContext
    private let coreDataManager: CoreDataManager
    
    init(context: NSManagedObjectContext? = nil, 
         coreDataManager: CoreDataManager? = nil) {
        // Gebruik dependency injection of fallback naar shared instance
        self.coreDataManager = coreDataManager ?? CoreDataManager.shared
        self.context = context ?? self.coreDataManager.managedObjectContext
        loadTrips()
    }
    
    // MARK: - Trip Management
    
    func addTrip(_ trip: Trip) {
        // Add to Core Data
        if let _ = coreDataManager.createTrip(from: trip) {
            // Add to local array
            trips.append(trip)
            print("✅ Trip added to Core Data: \(trip.name) - \(trip.date)")
        } else {
            print("❌ Failed to add trip to Core Data: \(trip.name)")
        }
    }
    
    func updateTrip(_ trip: Trip) {
        print("🔄 CoreDataTripStore.updateTrip() called for trip: \(trip.name)")
        
        // Update in Core Data
        if coreDataManager.updateTrip(trip) {
            // Update local array
            if let index = trips.firstIndex(where: { $0.id == trip.id }) {
                trips[index] = trip
                print("✅ Trip updated in Core Data: \(trip.name)")
            } else {
                print("❌ Trip not found in local array: \(trip.id)")
            }
        } else {
            print("❌ Failed to update trip in Core Data: \(trip.name)")
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        // Delete from Core Data
        if coreDataManager.deleteTrip(withId: trip.id) {
            // Remove from local array
            trips.removeAll { $0.id == trip.id }
            print("🗑️ Trip deleted from Core Data: \(trip.name)")
        } else {
            print("❌ Failed to delete trip from Core Data: \(trip.name)")
        }
    }
    
    func deleteTrips(at offsets: IndexSet) {
        let tripsToDelete = offsets.map { trips[$0] }
        for trip in tripsToDelete {
            deleteTrip(trip)
        }
    }
    
    func replaceGPXForTrip(_ trip: Trip, with newGPXFile: GPXFile) -> Trip? {
        // Genereer route punten met timing via TripTimingCalculator
        let routePoints = TripTimingCalculator.generateRoutePointsWithTiming(
            from: newGPXFile.routePoints,
            startTime: trip.startTime,
            arrivalTime: trip.arrivalTime,
            totalDistance: newGPXFile.distance
        )
        
        // Create updated trip with new GPX data, behoud bestaande instellingen en ID
        let updatedTrip = Trip(
            id: trip.id, // Behoud originele ID
            name: trip.name,
            date: trip.date,
            startTime: trip.startTime,
            arrivalTime: trip.arrivalTime,
            distance: newGPXFile.distance,
            gpxFileName: newGPXFile.fileName,
            routePoints: routePoints,
            weatherData: trip.weatherData, // Behoud bestaande weather data
            createdAt: trip.createdAt, // Behoud originele creation date
            updatedAt: Date(), // Update timestamp
            rainFocusEnabled: trip.rainFocusEnabled // Behoud rain focus setting
        )
        
        print("🔄 Replacing GPX for trip: \(trip.name)")
        print("   - Preserved rainFocusEnabled: \(updatedTrip.rainFocusEnabled)")
        
        // Update in Core Data
        if coreDataManager.updateTrip(updatedTrip) {
            // Update local array
            if let index = trips.firstIndex(where: { $0.id == trip.id }) {
                trips[index] = updatedTrip
                print("✅ GPX replaced for trip: \(trip.name)")
                return updatedTrip
            }
        }
        
        print("❌ Failed to replace GPX for trip: \(trip.name)")
        return nil
    }
    
    // MARK: - Data Loading
    
    private func loadTrips() {
        print("📱 Loading trips from Core Data...")
        
        // Fetch all trips with their relationships
        let tripEntities = coreDataManager.fetchTripsWithWeatherData()
        
        // Convert Core Data entities to Trip models
        trips = tripEntities.compactMap { entity in
            convertToTrip(from: entity)
        }
        
        print("📱 Loaded \(trips.count) trips from Core Data")
    }
    
    private func convertToTrip(from entity: TripEntity) -> Trip? {
        guard let id = entity.id,
              let name = entity.name,
              let date = entity.date,
              let startTime = entity.startTime,
              let arrivalTime = entity.arrivalTime,
              let gpxFileName = entity.gpxFileName,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            print("❌ Invalid trip entity data")
            return nil
        }
        
        // Convert route points
        let routePoints = (entity.routePoints?.allObjects as? [RoutePointEntity])?.compactMap { routePointEntity in
            convertToRoutePoint(from: routePointEntity)
        } ?? []
        
        // Convert weather data
        let weatherData = (entity.weatherData?.allObjects as? [WeatherSnapshotEntity])?.compactMap { weatherEntity in
            convertToWeatherSnapshot(from: weatherEntity)
        } ?? []
        
        // Haal rainFocusEnabled op uit Core Data (standaard false als niet ingesteld)
        let rainFocusEnabled = entity.rainFocusEnabled
        
        // Create Trip object met bestaande Core Data ID
        let trip = Trip(
            id: id,  // Belangrijk: gebruik de bestaande Core Data ID!
            name: name,
            date: date,
            startTime: startTime,
            arrivalTime: arrivalTime,
            distance: entity.distance,
            gpxFileName: gpxFileName,
            routePoints: routePoints,
            weatherData: weatherData,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rainFocusEnabled: rainFocusEnabled
        )
        
        return trip
    }
    
    private func convertToRoutePoint(from entity: RoutePointEntity) -> RoutePoint? {
        guard let _ = entity.id,
              let estimatedPassTime = entity.estimatedPassTime else {
            return nil
        }
        
        return RoutePoint(
            latitude: entity.latitude,
            longitude: entity.longitude,
            distanceFromStart: entity.distanceFromStart,
            estimatedPassTime: estimatedPassTime,
            segmentIndex: Int(entity.segmentIndex),
            segmentDistance: entity.segmentDistance
        )
    }
    
    private func convertToWeatherSnapshot(from entity: WeatherSnapshotEntity) -> WeatherSnapshot? {
        guard let _ = entity.id,
              let fetchTime = entity.fetchTime,
              let description = entity.weatherDescription,
              let _ = entity.icon else {
            return nil
        }
        
        return WeatherSnapshot(
            latitude: entity.latitude,
            longitude: entity.longitude,
            temperature: entity.temperature,
            humidity: entity.humidity,
            windSpeed: entity.windSpeed,
            windDirection: entity.windDirection,
            chanceOfRain: entity.chanceOfRain,
            rainAmount: entity.rainAmount,
            description: description,
            icon: entity.icon ?? "questionmark.circle",
            timestamp: fetchTime,
            placeName: entity.placeName ?? "Onbekende locatie"
        )
    }
    
    // MARK: - Trip Search
    
    func trip(withId id: UUID) -> Trip? {
        return trips.first { $0.id == id }
    }
    
    func trips(forDate date: Date) -> [Trip] {
        let calendar = Calendar.current
        return trips.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    // MARK: - Weather Data Management
    
    func updateWeatherData(for tripId: UUID, weatherData: [WeatherSnapshot]) {
        print("🌤️ Updating weather data for trip ID: \(tripId)")
        print("🌤️ Current trips in store:")
        for trip in trips {
            print("   - Trip ID: \(trip.id) - Name: \(trip.name)")
        }
        
        // Update in Core Data
        if coreDataManager.updateWeatherData(for: tripId, weatherData: weatherData) {
            // Update local array
            if let index = trips.firstIndex(where: { $0.id == tripId }) {
                trips[index].weatherData = weatherData
                trips[index].updatedAt = Date()
                print("✅ Weather data updated in Core Data for trip: \(trips[index].name)")
            }
        } else {
            print("❌ Failed to update weather data in Core Data for trip ID: \(tripId)")
        }
    }
    
    func clearWeatherData(for tripId: UUID) {
        print("🌤️ Clearing weather data for trip ID: \(tripId)")
        
        // Clear in Core Data
        if coreDataManager.clearWeatherData(for: tripId) {
            // Update local array
            if let index = trips.firstIndex(where: { $0.id == tripId }) {
                trips[index].weatherData = []
                trips[index].updatedAt = Date()
                print("✅ Weather data cleared in Core Data for trip: \(trips[index].name)")
            }
        } else {
            print("❌ Failed to clear weather data in Core Data for trip ID: \(tripId)")
        }
    }
    
    // MARK: - Performance Optimizations
    
    func refreshTrips() {
        print("🔄 Refreshing trips from Core Data...")
        // Reset trips array en opnieuw laden
        trips = []
        loadTrips()
    }
    
    func cleanupOldWeatherData() {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        coreDataManager.batchDeleteOldWeatherData(olderThan: oneWeekAgo)
    }
    
    // MARK: - Settings Integration
    
    func getAppSettings() -> (useMetricUnits: Bool, weatherCacheTTL: Int, rainRuleType: String, rainChanceThreshold: Double, rainAmountThreshold: Double) {
        let settings = coreDataManager.getAppSettings()
        return (
            useMetricUnits: settings.useMetricUnits,
            weatherCacheTTL: Int(settings.weatherCacheTTL),
            rainRuleType: settings.rainRuleType ?? "BOTH",
            rainChanceThreshold: settings.rainChanceThreshold,
            rainAmountThreshold: settings.rainAmountThreshold
        )
    }
    
    func updateAppSettings(useMetricUnits: Bool, weatherCacheTTL: Int32, rainRuleType: String, rainChanceThreshold: Double, rainAmountThreshold: Double) {
        coreDataManager.updateAppSettings(
            useMetricUnits: useMetricUnits,
            weatherCacheTTL: weatherCacheTTL,
            rainRuleType: rainRuleType,
            rainChanceThreshold: rainChanceThreshold,
            rainAmountThreshold: rainAmountThreshold
        )
    }
    
    /// Update API key in app settings
    func updateAPIKey(_ apiKey: String?) {
        coreDataManager.updateAPIKey(apiKey)
    }
    
    /// Get current API key from app settings
    func getAPIKey() -> String? {
        return coreDataManager.getAPIKey()
    }
    
    // MARK: - Data Validation
    
    func validateData() -> [String] {
        return coreDataManager.validateTripData()
    }
}

// MARK: - Trip Extension for Core Data Compatibility

extension Trip {
    // Add a computed property to check if this trip exists in Core Data
    var existsInCoreData: Bool {
        // This will be implemented when we add Core Data support
        return false
    }
}
