//
//  CoreDataWeatherOperations.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import CoreData

// MARK: - Weather Operations Extension
extension CoreDataManager {
    
    // MARK: - Weather Snapshot Operations
    
    func createWeatherSnapshot(from weatherSnapshot: WeatherSnapshot, for trip: TripEntity) -> WeatherSnapshotEntity {
        let entity = WeatherSnapshotEntity(context: context)
        
        entity.id = weatherSnapshot.id
        entity.fetchTime = weatherSnapshot.timestamp
        entity.chanceOfRain = weatherSnapshot.chanceOfRain
        entity.rainAmount = weatherSnapshot.rainAmount
        entity.temperature = weatherSnapshot.temperature
        entity.weatherDescription = weatherSnapshot.description
        entity.humidity = weatherSnapshot.humidity
        entity.windSpeed = weatherSnapshot.windSpeed
        entity.windDirection = weatherSnapshot.windDirection
        entity.icon = weatherSnapshot.icon
        entity.latitude = weatherSnapshot.latitude
        entity.longitude = weatherSnapshot.longitude
        entity.placeName = weatherSnapshot.placeName
        entity.trip = trip
        
        // Find and link to route point if possible (using coordinates instead of ID)
        if let routePointEntity = findRoutePoint(near: weatherSnapshot.latitude, longitude: weatherSnapshot.longitude, in: trip) {
            entity.routePoint = routePointEntity
        }
        
        return entity
    }
    
    func findRoutePoint(near latitude: Double, longitude: Double, in trip: TripEntity) -> RoutePointEntity? {
        guard let routePoints = trip.routePoints?.allObjects as? [RoutePointEntity] else {
            return nil
        }
        
        // Find the closest route point within 1km using CoordinateUtilities
        var closestPoint: RoutePointEntity?
        var closestDistance = Double.infinity
        
        for routePoint in routePoints {
            let targetCoord = CoordinateUtilities.toCLLocationCoordinate(latitude: latitude, longitude: longitude)
            let routeCoord = CoordinateUtilities.toCLLocationCoordinate(latitude: routePoint.latitude, longitude: routePoint.longitude)
            
            let distance = CoordinateUtilities.calculateDistanceInMeters(from: targetCoord, to: routeCoord)
            
            if distance < 1000 && distance < closestDistance {
                closestDistance = distance
                closestPoint = routePoint
            }
        }
        
        return closestPoint
    }
    
    // MARK: - Weather Data Management
    
    func updateWeatherData(for tripId: UUID, weatherData: [WeatherSnapshot]) -> Bool {
        print("🔍 Attempting to update weather data for trip ID: \(tripId)")
        
        // Debug: check what trips exist in Core Data
        let allTrips = fetchAllTrips()
        print("🔍 Found \(allTrips.count) trips in Core Data:")
        for trip in allTrips {
            print("   - Trip ID: \(trip.id?.uuidString ?? "nil") - Name: \(trip.name ?? "nil")")
        }
        
        guard let tripEntity = fetchTrip(withId: tripId) else { 
            print("❌ Trip not found for weather update: \(tripId)")
            return false 
        }
        
        // Remove existing weather data
        if let existingWeather = tripEntity.weatherData?.allObjects as? [WeatherSnapshotEntity] {
            for weather in existingWeather {
                context.delete(weather)
            }
        }
        
        // Add new weather data
        for weatherSnapshot in weatherData {
            let weatherEntity = createWeatherSnapshot(from: weatherSnapshot, for: tripEntity)
            tripEntity.addToWeatherData(weatherEntity)
        }
        
        tripEntity.updatedAt = Date()
        return saveWithRecovery()
    }
    
    func clearWeatherData(for tripId: UUID) -> Bool {
        guard let tripEntity = fetchTrip(withId: tripId) else { 
            print("❌ Trip not found for weather clear: \(tripId)")
            return false 
        }
        
        // Remove all weather data
        if let existingWeather = tripEntity.weatherData?.allObjects as? [WeatherSnapshotEntity] {
            for weather in existingWeather {
                context.delete(weather)
            }
        }
        
        tripEntity.updatedAt = Date()
        return saveWithRecovery()
    }
    
    // MARK: - Performance Optimizations
    
    func batchDeleteOldWeatherData(olderThan date: Date) {
        let request: NSFetchRequest<NSFetchRequestResult> = WeatherSnapshotEntity.fetchRequest()
        request.predicate = NSPredicate(format: "fetchTime < %@", date as CVarArg)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                print("✅ Deleted \(objectIDs.count) old weather records")
            }
        } catch {
            print("❌ Failed to batch delete old weather data: \(error)")
            let coreDataError = CoreDataError.deleteFailed(error)
            DispatchQueue.main.async {
                self.lastCoreDataError = coreDataError
                self.lastError = coreDataError.localizedDescription
            }
        }
    }
    
    // MARK: - Data Validation
    
    func validateWeatherData() -> [String] {
        var errors: [String] = []
        
        let request: NSFetchRequest<WeatherSnapshotEntity> = WeatherSnapshotEntity.fetchRequest()
        
        do {
            let weatherSnapshots = try context.fetch(request)
            
            for weather in weatherSnapshots {
                if weather.id == nil {
                    errors.append("Weather snapshot has no ID")
                }
                if weather.trip == nil {
                    errors.append("Weather snapshot has no associated trip")
                }
            }
        } catch {
            errors.append("Failed to validate weather data: \(error.localizedDescription)")
        }
        
        return errors
    }
}
