//
//  RoutePointRow.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI

struct RoutePointRow: View {
    let point: RoutePoint
    let weather: WeatherSnapshot?
    let showRainFocus: Bool
    let coreDataStore: CoreDataTripStore
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Tijd
            VStack(alignment: .leading) {
                Text(point.estimatedPassTime, style: .time)
                    .font(.headline)
                    .fontWeight(.medium)
                let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
                let distanceUnit = useMetricUnits ? "km" : "mi"
                let distanceValue = useMetricUnits ? point.distanceFromStart : point.distanceFromStart * 0.621371
                
                Text("\(String(format: "%.1f", distanceValue)) \(distanceUnit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            // Locatie indicator
            VStack {
                Circle()
                    .fill(showRainFocus && isRainy ? Color.red : Color.blue)
                    .frame(width: 12, height: 12)
                if point.id != UUID() { // Niet het laatste punt
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 20)
                }
            }
            
            // Weer informatie
            if let weather = weather {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
                        let tempUnit = useMetricUnits ? "°C" : "°F"
                        let tempValue = useMetricUnits ? weather.temperature : (weather.temperature * 9/5) + 32
                        
                        Text("\(Int(tempValue))\(tempUnit)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(round(weather.chanceOfRain * 100)))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(weather.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if weather.rainAmount > 0 {
                            let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
                            let rainUnit = useMetricUnits ? "mm" : "in"
                            let rainValue = useMetricUnits ? weather.rainAmount : weather.rainAmount * 0.0393701
                            
                            Text("\(String(format: "%.1f", rainValue)) \(rainUnit)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Locatie plaatsnaam
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .font(.caption2)
                        
                        Text(weather.placeName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
                .padding(.leading, 8)
            } else {
                VStack(alignment: .leading) {
                    Text("No weather data".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(showRainFocus && isRainy ? Color.red.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(showRainFocus && isRainy ? Color.red.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var isRainy: Bool {
        guard let weather = weather else { return false }
        
        // Lees de instellingen uit Core Data
        let settings = coreDataStore.getAppSettings()
        let rainRuleType = settings.rainRuleType
        let chanceThreshold = (settings.rainChanceThreshold / 100.0) // Converteer % naar decimaal
        let amountThreshold = settings.rainAmountThreshold
        
        print("🌧️ Checking if weather is rainy:")
        print("   - Weather chance of rain: \(weather.chanceOfRain * 100)%")
        print("   - Weather rain amount: \(weather.rainAmount) mm")
        print("   - Rain rule type: \(rainRuleType)")
        print("   - Chance threshold: \(settings.rainChanceThreshold)%")
        print("   - Amount threshold: \(amountThreshold) mm")
        
        let isRainy: Bool
        switch rainRuleType {
        case "BOTH":
            isRainy = weather.chanceOfRain >= chanceThreshold && weather.rainAmount >= amountThreshold
            print("   - BOTH rule: chance >= \(chanceThreshold) AND amount >= \(amountThreshold) = \(isRainy)")
        case "CHANCE_ONLY":
            isRainy = weather.chanceOfRain >= chanceThreshold
            print("   - CHANCE_ONLY rule: chance >= \(chanceThreshold) = \(isRainy)")
        case "AMOUNT_ONLY":
            isRainy = weather.rainAmount >= amountThreshold
            print("   - AMOUNT_ONLY rule: amount >= \(amountThreshold) = \(isRainy)")
        default:
            isRainy = weather.chanceOfRain >= chanceThreshold && weather.rainAmount >= amountThreshold
            print("   - DEFAULT rule: chance >= \(chanceThreshold) AND amount >= \(amountThreshold) = \(isRainy)")
        }
        
        print("   - Final result: \(isRainy)")
        return isRainy
    }
}
