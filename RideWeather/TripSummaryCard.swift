//
//  TripSummaryCard.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI

struct TripSummaryCard: View {
    let trip: Trip
    let weatherData: [WeatherSnapshot]
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(trip.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(trip.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let weatherStatus = calculateWeatherStatus(from: weatherData) {
                    VStack(alignment: .trailing) {
                        Image(systemName: weatherStatus.icon)
                            .font(.title2)
                            .foregroundColor(weatherStatus.color)
                        Text(weatherStatus.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Start".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trip.startTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("Distance".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
                    let distanceUnit = useMetricUnits ? "km" : "mi"
                    let distanceValue = useMetricUnits ? trip.distance : trip.distance * 0.621371
                    
                    Text("\(String(format: "%.1f", distanceValue)) \(distanceUnit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Arrival".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trip.arrivalTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Average speed".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
                    let speedUnit = useMetricUnits ? "km/h" : "mph"
                    let speedValue = useMetricUnits ? trip.averageSpeed : trip.averageSpeed * 0.621371
                    
                    Text("\(String(format: "%.0f", speedValue)) \(speedUnit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Route file".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trip.gpxFileName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func calculateWeatherStatus(from weatherData: [WeatherSnapshot]) -> WeatherStatus? {
        guard !weatherData.isEmpty else { return nil }
        
        let hasRain = weatherData.contains { $0.chanceOfRain >= 0.5 && $0.rainAmount >= 0.3 }
        let hasHighChance = weatherData.contains { $0.chanceOfRain >= 0.8 }
        
        if hasHighChance {
            return WeatherStatus(icon: "cloud.rain.fill", color: .red, description: "High chance of rain".localized)
        } else if hasRain {
            return WeatherStatus(icon: "cloud.drizzle.fill", color: .orange, description: "Chance of rain".localized)
        } else {
            return WeatherStatus(icon: "sun.max.fill", color: .yellow, description: "Good weather".localized)
        }
    }
}

// WeatherStatus struct already exists in Trip.swift
