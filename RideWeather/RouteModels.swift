//
//  RouteModels.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Coordinate Utilities

struct CoordinateUtilities {
    
    /// Bereken afstand tussen twee coördinaten in kilometers
    static func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2) / 1000.0 // Convert to kilometers
    }
    
    /// Bereken afstand tussen twee coördinaten in meters
    static func calculateDistanceInMeters(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
    
    /// Vind de dichtstbijzijnde coördinaat binnen een bepaalde afstand
    static func findClosestCoordinate(
        to target: CLLocationCoordinate2D,
        in coordinates: [CLLocationCoordinate2D],
        within maxDistance: Double
    ) -> CLLocationCoordinate2D? {
        var closestCoordinate: CLLocationCoordinate2D?
        var closestDistance = Double.infinity
        
        for coordinate in coordinates {
            let distance = calculateDistanceInMeters(from: target, to: coordinate)
            if distance <= maxDistance && distance < closestDistance {
                closestDistance = distance
                closestCoordinate = coordinate
            }
        }
        
        return closestCoordinate
    }
    
    /// Converteer coördinaten naar CLLocationCoordinate2D
    static func toCLLocationCoordinate(latitude: Double, longitude: Double) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Route Point Model

struct RoutePoint: Identifiable, Equatable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let distanceFromStart: Double
    let estimatedPassTime: Date
    let segmentIndex: Int
    let segmentDistance: Double
    
    var coordinate: CLLocationCoordinate2D {
        return CoordinateUtilities.toCLLocationCoordinate(latitude: latitude, longitude: longitude)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: estimatedPassTime)
    }
    
    var distanceString: String {
        return String(format: "%.1f km", distanceFromStart)
    }
}

// MARK: - Weather Snapshot Model

struct WeatherSnapshot: Identifiable, Equatable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: Double
    let chanceOfRain: Double
    let rainAmount: Double
    let description: String
    let icon: String
    let timestamp: Date
    let placeName: String
    
    var temperatureString: String {
        let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
        if useMetricUnits {
            return String(format: "%.1f°C", temperature)
        } else {
            let fahrenheit = temperature * 9/5 + 32
            return String(format: "%.1f°F", fahrenheit)
        }
    }
    
    var windSpeedString: String {
        let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
        if useMetricUnits {
            return String(format: "%.1f km/h", windSpeed)
        } else {
            let mph = windSpeed * 0.621371
            return String(format: "%.1f mph", mph)
        }
    }
    
    var rainChanceString: String {
        return String(format: "%.0f%%", chanceOfRain * 100)
    }
    
    var rainAmountString: String {
        return String(format: "%.1f mm", rainAmount)
    }
}

// MARK: - Weather Status Model

struct WeatherStatus {
    let icon: String
    let color: Color
    let description: String
}

// MARK: - GPX Waypoint Extension

extension GPXWaypoint {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
