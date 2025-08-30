//
//  Trip.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import CoreData

// MARK: - Trip Model (Core Data Compatible)

struct Trip: Identifiable, Equatable {
    let id: UUID
    var name: String
    var date: Date
    var startTime: Date
    var arrivalTime: Date
    var distance: Double // in kilometers
    var averageSpeed: Double // in km/h
    var gpxFileName: String
    var routePoints: [RoutePoint]
    var weatherData: [WeatherSnapshot]
    var createdAt: Date
    var updatedAt: Date
    var rainFocusEnabled: Bool // Nieuwe property voor Regen Focus staat
    
    init(name: String, date: Date, startTime: Date, arrivalTime: Date, distance: Double, gpxFileName: String, routePoints: [RoutePoint] = [], weatherData: [WeatherSnapshot] = [], createdAt: Date = Date(), updatedAt: Date = Date(), rainFocusEnabled: Bool = false) {
        #if DEBUG
        print("🔄 Trip initializer called with:")
        print("   - Name: \(name)")
        print("   - Date: \(date)")
        print("   - Start time: \(startTime)")
        print("   - Arrival time: \(arrivalTime)")
        print("   - Distance: \(distance)")
        print("   - GPX filename: \(gpxFileName)")
        print("   - Route points count: \(routePoints.count)")
        print("   - Weather data count: \(weatherData.count)")
        print("   - Rain focus enabled: \(rainFocusEnabled)")
        #endif
        
        // Deze initializer wordt alleen gebruikt voor nieuwe trips, dus genereer nieuwe ID
        self.id = UUID()
        self.name = name
        self.date = date
        self.startTime = startTime
        self.arrivalTime = arrivalTime
        self.distance = distance
        self.gpxFileName = gpxFileName
        self.weatherData = weatherData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rainFocusEnabled = rainFocusEnabled
        
        #if DEBUG
        print("✅ Trip created with:")
        print("   - Created at: \(self.createdAt)")
        print("   - Updated at: \(self.updatedAt)")
        print("   - Rain focus enabled: \(self.rainFocusEnabled)")
        #endif
        
        // Bereken gemiddelde snelheid
        let duration = arrivalTime.timeIntervalSince(startTime)
        self.averageSpeed = duration > 0 ? (distance / AppConstants.secondsToHours(duration)) : 0
        
        #if DEBUG
        print("   - Duration: \(duration) seconds")
        print("   - Average speed: \(self.averageSpeed) km/h")
        #endif
        
        // Als er bestaande route punten zijn, genereer nieuwe timing
        if !routePoints.isEmpty {
            // Converteer bestaande RoutePoint naar GPXWaypoint voor hergebruik
            let gpxWaypoints = routePoints.map { routePoint in
                GPXWaypoint(
                    latitude: routePoint.latitude,
                    longitude: routePoint.longitude,
                    elevation: nil,
                    time: nil,
                    name: ""
                )
            }
            
            // Genereer nieuwe route punten met bijgewerkte timing
            self.routePoints = TripTimingCalculator.generateRoutePointsWithTiming(
                from: gpxWaypoints,
                startTime: startTime,
                arrivalTime: arrivalTime,
                totalDistance: distance
            )
            
            #if DEBUG
            print("   - Generated \(self.routePoints.count) route points with new timing")
            #endif
        } else {
            self.routePoints = []
            #if DEBUG
            print("   - No route points to process")
            #endif
        }
        
        #if DEBUG
        print("✅ Trip initialization complete")
        #endif
    }
    
    /// Custom initializer voor het laden van bestaande trips uit Core Data
    init(id: UUID, name: String, date: Date, startTime: Date, arrivalTime: Date, distance: Double, gpxFileName: String, routePoints: [RoutePoint] = [], weatherData: [WeatherSnapshot] = [], createdAt: Date, updatedAt: Date, rainFocusEnabled: Bool = false) {
        #if DEBUG
        print("🔄 Trip Core Data initializer called with:")
        print("   - ID: \(id)")
        print("   - Name: \(name)")
        print("   - Date: \(date)")
        print("   - Current timezone: \(TimeZone.current.identifier)")
        print("   - Start time: \(startTime)")
        print("   - Start time UTC: \(startTime.timeIntervalSince1970)")
        print("   - Arrival time: \(arrivalTime)")
        print("   - Arrival time UTC: \(arrivalTime.timeIntervalSince1970)")
        print("   - Distance: \(distance)")
        print("   - GPX filename: \(gpxFileName)")
        print("   - Route points count: \(routePoints.count)")
        print("   - Weather data count: \(weatherData.count)")
        print("   - Created at: \(createdAt)")
        print("   - Updated at: \(updatedAt)")
        print("   - Rain focus enabled: \(rainFocusEnabled)")
        #endif
        
        self.id = id
        self.name = name
        self.date = date
        self.startTime = startTime
        self.arrivalTime = arrivalTime
        self.distance = distance
        self.gpxFileName = gpxFileName
        self.routePoints = routePoints
        self.weatherData = weatherData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rainFocusEnabled = rainFocusEnabled
        
        // Bereken gemiddelde snelheid
        let duration = arrivalTime.timeIntervalSince(startTime)
        self.averageSpeed = duration > 0 ? (distance / AppConstants.secondsToHours(duration)) : 0
        
        #if DEBUG
        print("✅ Trip Core Data initialization complete")
        print("   - Average speed: \(self.averageSpeed) km/h")
        print("   - Final start time: \(self.startTime)")
        print("   - Final arrival time: \(self.arrivalTime)")
        #endif
    }
    
    // MARK: - Computed Properties
    
    var duration: TimeInterval {
        return arrivalTime.timeIntervalSince(startTime)
    }
    
    var durationString: String {
        let hours = Int(duration) / Int(AppConstants.Time.oneHour)
        let minutes = Int(duration) % Int(AppConstants.Time.oneHour) / 60
        
        if hours > 0 {
            let hourText = LanguageManager.shared.localizedString(for: "h")
            let minuteText = LanguageManager.shared.localizedString(for: "m")
            return "\(hours)\(hourText) \(minutes)\(minuteText)"
        } else {
            let minuteText = LanguageManager.shared.localizedString(for: "m")
            return "\(minutes)\(minuteText)"
        }
    }
    
    var distanceString: String {
        return String(format: "%.1f km", distance)
    }
    
    var weatherStatus: WeatherStatus? {
        guard !weatherData.isEmpty else { return nil }
        
        // Gebruik Core Data instellingen via CoreDataManager
        let settings = CoreDataManager.shared.getAppSettings()
        let rainRuleType = settings.rainRuleType
        let chanceThreshold = settings.rainChanceThreshold / 100.0 // Converteer % naar decimaal
        let amountThreshold = settings.rainAmountThreshold
        
        let hasHighRainChance = weatherData.contains { $0.chanceOfRain >= chanceThreshold }
        let hasRain = weatherData.contains { $0.rainAmount >= amountThreshold }
        let hasLowTemp = weatherData.contains { $0.temperature < AppConstants.Trip.coldWeatherThreshold }
        
        // Bepaal of er slecht weer is op basis van de gekozen regel
        let isBadWeather: Bool
        switch rainRuleType {
        case "BOTH":
            isBadWeather = hasHighRainChance && hasRain
        case "CHANCE_ONLY":
            isBadWeather = hasHighRainChance
        case "AMOUNT_ONLY":
            isBadWeather = hasRain
        default:
            isBadWeather = hasHighRainChance && hasRain
        }
        
        if isBadWeather {
            return WeatherStatus(
                icon: "cloud.rain.fill",
                color: Color.red,
                description: LanguageManager.shared.localizedString(for: "High chance of rain")
            )
        } else if hasLowTemp {
            return WeatherStatus(
                icon: "thermometer.snowflake",
                color: Color.blue,
                description: LanguageManager.shared.localizedString(for: "Cold temperature")
            )
        } else {
            return WeatherStatus(
                icon: "sun.max.fill",
                color: Color.yellow,
                description: LanguageManager.shared.localizedString(for: "Good weather")
            )
        }
    }
}

// MARK: - Preview Data

#Preview {
    let testTrip = Trip(
        name: "Test Trip",
        date: Date(),
        startTime: Date(),
        arrivalTime: Date().addingTimeInterval(AppConstants.Trip.defaultDuration),
        distance: 50.0,
        gpxFileName: "test.gpx"
    )
    
    return VStack {
        Text("Trip: \(testTrip.name)")
        Text("Distance: \(testTrip.distanceString)")
        Text("Duration: \(testTrip.durationString)")
    }
    .padding()
}
