//
//  TripTimingCalculator.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import CoreLocation

// MARK: - Trip Timing Calculator

struct TripTimingCalculator {
    
    /// Genereer route punten met timing op basis van start- en aankomsttijd
    static func generateRoutePointsWithTiming(
        from waypoints: [GPXWaypoint],
        startTime: Date,
        arrivalTime: Date,
        totalDistance: Double
    ) -> [RoutePoint] {
        print("🔄 TripTimingCalculator.generateRoutePointsWithTiming called")
        print("   - Waypoints count: \(waypoints.count)")
        print("   - Current timezone: \(TimeZone.current.identifier)")
        print("   - Start time: \(startTime)")
        print("   - Start time UTC: \(startTime.timeIntervalSince1970)")
        print("   - Arrival time: \(arrivalTime)")
        print("   - Arrival time UTC: \(arrivalTime.timeIntervalSince1970)")
        print("   - Total distance: \(totalDistance) km")
        
        guard !waypoints.isEmpty else { 
            print("   - No waypoints provided, returning empty array")
            return [] 
        }
        
        var routePoints: [RoutePoint] = []
        
        // Bereken afstanden voor alle waypoints op basis van totale afstand
        let distances = calculateDistancesForWaypoints(waypoints, totalDistance: totalDistance)
        
        for (index, waypoint) in waypoints.enumerated() {
            let distanceFromStart = distances[index]
            
            // Bereken geschatte passage tijd op basis van totale reistijd en afstand
            let estimatedPassTime = calculateEstimatedPassTime(
                startTime: startTime,
                arrivalTime: arrivalTime,
                distanceFromStart: distanceFromStart,
                totalDistance: totalDistance
            )
            
            // Bereken segment afstand
            let segmentDistance = index < waypoints.count - 1 ? 
                distances[index + 1] - distances[index] : 0
            
            let routePoint = RoutePoint(
                latitude: waypoint.latitude,
                longitude: waypoint.longitude,
                distanceFromStart: distanceFromStart,
                estimatedPassTime: estimatedPassTime,
                segmentIndex: index, // Behoud de originele volgorde
                segmentDistance: segmentDistance
            )
            
            routePoints.append(routePoint)
        }
        
        // Corrigeer de laatste route punt om exact op aankomsttijd te komen
        if routePoints.count > 1 {
            var correctedLastPoint = routePoints[routePoints.count - 1]
            correctedLastPoint = RoutePoint(
                latitude: correctedLastPoint.latitude,
                longitude: correctedLastPoint.longitude,
                distanceFromStart: totalDistance, // Zorg dat het laatste punt altijd op totalDistance uitkomt
                estimatedPassTime: arrivalTime,
                segmentIndex: correctedLastPoint.segmentIndex,
                segmentDistance: correctedLastPoint.segmentDistance
            )
            routePoints[routePoints.count - 1] = correctedLastPoint
            print("   - Corrected last point distance from \(routePoints[routePoints.count - 1].distanceFromStart) km to \(totalDistance) km")
        }
        
        print("   - Generated \(routePoints.count) route points")
        print("   - Route points order preserved: \(routePoints.map { $0.segmentIndex })")
        return routePoints
    }
    
    /// Bereken afstanden voor waypoints op basis van totale afstand
    private static func calculateDistancesForWaypoints(_ waypoints: [GPXWaypoint], totalDistance: Double) -> [Double] {
        guard waypoints.count > 1 else { return [0.0] }
        
        var distances: [Double] = []
        
        // Eerste punt is altijd op 0.0 km
        distances.append(0.0)
        
        // Bereken afstanden voor tussenliggende punten
        let numberOfSegments = waypoints.count - 1
        let distancePerSegment = totalDistance / Double(numberOfSegments)
        
        for i in 1..<waypoints.count {
            let distance = distancePerSegment * Double(i)
            distances.append(distance)
        }
        
        // Zorg dat het laatste punt exact op totalDistance uitkomt
        if distances.count > 1 {
            distances[distances.count - 1] = totalDistance
        }
        
        return distances
    }
    
    /// Genereer route punten met timing op basis van gemiddelde snelheid (oude methode - behouden voor backward compatibility)
    static func generateRoutePointsWithTiming(
        from waypoints: [GPXWaypoint],
        startTime: Date,
        averageSpeed: Double
    ) -> [RoutePoint] {
        guard !waypoints.isEmpty else { return [] }
        
        var routePoints: [RoutePoint] = []
        var totalDistance: Double = 0
        
        for (index, waypoint) in waypoints.enumerated() {
            // Bereken afstand vanaf start
            if index > 0 {
                let previousWaypoint = waypoints[index - 1]
                let segmentDistance = calculateDistance(
                    from: previousWaypoint.coordinate,
                    to: waypoint.coordinate
                )
                totalDistance += segmentDistance
            }
            
            // Bereken geschatte passage tijd
            let estimatedPassTime = calculateEstimatedPassTime(
                startTime: startTime,
                distanceFromStart: totalDistance,
                averageSpeed: averageSpeed
            )
            
            // Bereken segment afstand
            let segmentDistance = index < waypoints.count - 1 ? 
                calculateDistance(from: waypoint.coordinate, to: waypoints[index + 1].coordinate) : 0
            
            let routePoint = RoutePoint(
                latitude: waypoint.latitude,
                longitude: waypoint.longitude,
                distanceFromStart: totalDistance,
                estimatedPassTime: estimatedPassTime,
                segmentIndex: index,
                segmentDistance: segmentDistance
            )
            
            routePoints.append(routePoint)
        }
        
        return routePoints
    }
    
    /// Bereken afstand tussen twee coördinaten in kilometers
    private static func calculateDistance(
        from coord1: CLLocationCoordinate2D,
        to coord2: CLLocationCoordinate2D
    ) -> Double {
        return CoordinateUtilities.calculateDistance(from: coord1, to: coord2)
    }
    
    /// Bereken geschatte passage tijd op basis van starttijd, afstand en gemiddelde snelheid
    private static func calculateEstimatedPassTime(
        startTime: Date,
        distanceFromStart: Double,
        averageSpeed: Double
    ) -> Date {
        guard averageSpeed > 0 else { return startTime }
        
        // Tijd = afstand / snelheid (in uren)
        let travelTimeHours = distanceFromStart / averageSpeed
        
        // Converteer naar seconden en voeg toe aan starttijd
        let travelTimeSeconds = travelTimeHours * AppConstants.Time.oneHour
        
        return startTime.addingTimeInterval(travelTimeSeconds)
    }
    
    /// Bereken geschatte passage tijd op basis van start- en aankomsttijd en afstand
    private static func calculateEstimatedPassTime(
        startTime: Date,
        arrivalTime: Date,
        distanceFromStart: Double,
        totalDistance: Double
    ) -> Date {
        guard totalDistance > 0 else { return startTime }
        
        // Bereken totale reistijd
        let totalTravelTime = arrivalTime.timeIntervalSince(startTime)
        
        // Bereken proportionele tijd op basis van afstand
        let proportionalTime = (distanceFromStart / totalDistance) * totalTravelTime
        
        return startTime.addingTimeInterval(proportionalTime)
    }
}
