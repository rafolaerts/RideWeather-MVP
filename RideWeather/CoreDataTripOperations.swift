//
//  CoreDataTripOperations.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import CoreData

// MARK: - Trip Operations Extension
extension CoreDataManager {
    
    func createTrip(from trip: Trip) -> TripEntity? {
        // Check if trip with same ID already exists
        if let existingTrip = fetchTrip(withId: trip.id) {
            print("⚠️ Trip with ID \(trip.id) already exists, updating instead")
            return updateExistingTrip(trip, entity: existingTrip)
        }
        
        let entity = TripEntity(context: context)
        
        entity.id = trip.id
        entity.name = trip.name
        entity.date = trip.date
        entity.startTime = trip.startTime
        entity.arrivalTime = trip.arrivalTime
        entity.distance = trip.distance
        entity.averageSpeed = trip.averageSpeed
        entity.gpxFileName = trip.gpxFileName
        entity.createdAt = trip.createdAt
        entity.updatedAt = trip.updatedAt
        entity.rainFocusEnabled = trip.rainFocusEnabled
        
        // Create route points
        for routePoint in trip.routePoints {
            let routePointEntity = createRoutePoint(from: routePoint, for: entity)
            entity.addToRoutePoints(routePointEntity)
        }
        
        // Create weather data
        for weatherSnapshot in trip.weatherData {
            let weatherEntity = createWeatherSnapshot(from: weatherSnapshot, for: entity)
            entity.addToWeatherData(weatherEntity)
        }
        
        _ = saveWithRecovery()
        return entity
    }
    
    func updateExistingTrip(_ trip: Trip, entity: TripEntity) -> TripEntity {
        entity.name = trip.name
        entity.date = trip.date
        entity.startTime = trip.startTime
        entity.arrivalTime = trip.arrivalTime
        entity.distance = trip.distance
        entity.averageSpeed = trip.averageSpeed
        entity.gpxFileName = trip.gpxFileName
        entity.rainFocusEnabled = trip.rainFocusEnabled
        entity.updatedAt = Date()
        
        // Clear existing relationships and recreate
        entity.removeFromRoutePoints(entity.routePoints ?? NSSet())
        entity.removeFromWeatherData(entity.weatherData ?? NSSet())
        
        // Create new route points
        for routePoint in trip.routePoints {
            let routePointEntity = createRoutePoint(from: routePoint, for: entity)
            entity.addToRoutePoints(routePointEntity)
        }
        
        // Create new weather data
        for weatherSnapshot in trip.weatherData {
            let weatherEntity = createWeatherSnapshot(from: weatherSnapshot, for: entity)
            entity.addToWeatherData(weatherEntity)
        }
        
        _ = saveWithRecovery()
        return entity
    }
    
    func fetchTrip(withId id: UUID) -> TripEntity? {
        let request: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("❌ Failed to fetch trip: \(error)")
            let coreDataError = CoreDataError.fetchFailed(error)
            DispatchQueue.main.async {
                self.lastCoreDataError = coreDataError
                self.lastError = coreDataError.localizedDescription
            }
            return nil
        }
    }
    
    func fetchAllTrips() -> [TripEntity] {
        let request: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TripEntity.date, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch trips: \(error)")
            let coreDataError = CoreDataError.fetchFailed(error)
            DispatchQueue.main.async {
                self.lastCoreDataError = coreDataError
                self.lastError = coreDataError.localizedDescription
            }
            return []
        }
    }
    
    func updateTrip(_ trip: Trip) -> Bool {
        guard let entity = fetchTrip(withId: trip.id) else {
            print("❌ Trip not found for update: \(trip.id)")
            return false
        }
        
        entity.name = trip.name
        entity.date = trip.date
        entity.startTime = trip.startTime
        entity.arrivalTime = trip.arrivalTime
        entity.distance = trip.distance
        entity.averageSpeed = trip.averageSpeed
        entity.gpxFileName = trip.gpxFileName
        entity.rainFocusEnabled = trip.rainFocusEnabled
        entity.updatedAt = Date()
        
        print("✅ Trip updated in Core Data: \(trip.name)")
        print("   - rainFocusEnabled: \(trip.rainFocusEnabled)")
        
        return saveWithRecovery()
    }
    
    func deleteTrip(withId id: UUID) -> Bool {
        guard let entity = fetchTrip(withId: id) else {
            print("❌ Trip not found for deletion: \(id)")
            return false
        }
        
        context.delete(entity)
        return saveWithRecovery()
    }
    
    // MARK: - Route Point Operations
    
    func createRoutePoint(from routePoint: RoutePoint, for trip: TripEntity) -> RoutePointEntity {
        let entity = RoutePointEntity(context: context)
        
        entity.id = routePoint.id
        entity.latitude = routePoint.latitude
        entity.longitude = routePoint.longitude
        entity.distanceFromStart = routePoint.distanceFromStart
        entity.estimatedPassTime = routePoint.estimatedPassTime
        entity.segmentIndex = Int32(routePoint.segmentIndex)
        entity.segmentDistance = routePoint.segmentDistance
        entity.trip = trip
        
        return entity
    }
    
    // MARK: - Performance Optimizations
    
    func fetchTripsWithWeatherData() -> [TripEntity] {
        let request: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TripEntity.date, ascending: false)]
        
        // Prefetch relationships for better performance
        request.relationshipKeyPathsForPrefetching = ["routePoints", "weatherData"]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch trips with weather data: \(error)")
            let coreDataError = CoreDataError.fetchFailed(error)
            DispatchQueue.main.async {
                self.lastCoreDataError = coreDataError
                self.lastError = coreDataError.localizedDescription
            }
            return []
        }
    }
    
    // MARK: - Data Validation
    
    func validateTripData() -> [String] {
        var errors: [String] = []
        
        let request: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()
        
        do {
            let trips = try context.fetch(request)
            
            for trip in trips {
                if trip.id == nil {
                    errors.append("Trip '\(trip.name ?? "Unknown")' has no ID")
                }
                if trip.name?.isEmpty ?? true {
                    errors.append("Trip with ID \(trip.id?.uuidString ?? "Unknown") has no name")
                }
                if trip.date == nil {
                    errors.append("Trip '\(trip.name ?? "Unknown")' has no date")
                }
            }
        } catch {
            errors.append("Failed to validate trip data: \(error.localizedDescription)")
        }
        
        return errors
    }
    
    func validateRoutePointData() -> [String] {
        var errors: [String] = []
        
        let request: NSFetchRequest<RoutePointEntity> = RoutePointEntity.fetchRequest()
        
        do {
            let routePoints = try context.fetch(request)
            
            for routePoint in routePoints {
                if routePoint.id == nil {
                    errors.append("Route point has no ID")
                }
                if routePoint.trip == nil {
                    errors.append("Route point has no associated trip")
                }
            }
        } catch {
            errors.append("Failed to validate route point data: \(error.localizedDescription)")
        }
        
        return errors
    }
}
