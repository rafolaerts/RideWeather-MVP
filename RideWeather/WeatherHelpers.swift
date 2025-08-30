//
//  WeatherHelpers.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation

// MARK: - Weather Data Factory

struct WeatherDataFactory {
    
    /// Maak een WeatherDataPoint aan van CurrentWeather data
    static func createWeatherDataPoint(from current: CurrentWeather) -> WeatherDataPoint {
        return WeatherDataPoint(
            temperature: current.temp,
            chanceOfRain: current.pop ?? 0.0,
            rainAmount: current.rain?.oneHour ?? 0.0,
            description: current.weather.first?.description ?? LanguageManager.shared.localizedString(for: "Unknown"),
            humidity: Double(current.humidity) / 100.0,
            windSpeed: current.windSpeed,
            windDirection: Double(current.windDeg),
            icon: current.weather.first?.icon ?? "questionmark.circle"
        )
    }
    
    /// Maak een WeatherDataPoint aan van HourlyForecast data
    static func createWeatherDataPoint(from hourly: HourlyForecast) -> WeatherDataPoint {
        return WeatherDataPoint(
            temperature: hourly.temp,
            chanceOfRain: hourly.pop,
            rainAmount: hourly.rain?.oneHour ?? 0.0,
            description: hourly.weather.first?.description ?? LanguageManager.shared.localizedString(for: "Unknown"),
            humidity: Double(hourly.humidity) / 100.0,
            windSpeed: hourly.windSpeed,
            windDirection: Double(hourly.windDeg),
            icon: hourly.weather.first?.icon ?? "questionmark.circle"
        )
    }
    
    /// Maak een fallback WeatherSnapshot aan
    static func createFallbackWeatherSnapshot(
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        placeName: String = LanguageManager.shared.localizedString(for: "Unknown location")
    ) -> WeatherSnapshot {
        return WeatherSnapshot(
            latitude: latitude,
            longitude: longitude,
            temperature: 0.0,
            humidity: 0.0,
            windSpeed: 0.0,
            windDirection: 0.0,
            chanceOfRain: 0.0,
            rainAmount: 0.0,
            description: LanguageManager.shared.localizedString(for: "No weather data available"),
            icon: "questionmark.circle",
            timestamp: timestamp,
            placeName: placeName
        )
    }
}

// MARK: - Weather Helper Methods

struct WeatherHelpers {
    
    /// Zoek de beste forecast data voor een gegeven tijdstip
    static func findBestForecastData(for targetTime: Date, in oneCallData: OneCallWeatherResponse) throws -> WeatherDataPoint {
        let targetTimeInterval = targetTime.timeIntervalSince1970
        let currentTime = Date().timeIntervalSince1970
        let timeDifference = targetTimeInterval - currentTime
        
        print("🎯 Finding best forecast data:")
        print("   - Target time: \(targetTime)")
        print("   - Target time UTC: \(targetTimeInterval)")
        print("   - Current time: \(Date())")
        print("   - Current time UTC: \(currentTime)")
        print("   - Time difference: \(timeDifference) seconds (\(timeDifference/60) minutes)")
        
        // Gebruik altijd hourly forecast voor temperatuur (minutely heeft geen temp data)
        print("   - Trying hourly forecast...")
        if let hourlyData = findClosestHourlyForecast(to: targetTimeInterval, in: oneCallData.hourly) {
            print("   - ✅ Found hourly forecast data")
            print("   - Selected forecast chance of rain: \(hourlyData.chanceOfRain * 100)%")
            print("   - Selected forecast humidity: \(hourlyData.humidity * 100)%")
            return hourlyData
        } else {
            print("   - ❌ No hourly forecast data found")
        }
        
        // Fallback naar current weather (voor huidige tijd of als beste benadering)
        print("   - Using current weather as fallback")
        guard let current = oneCallData.current else {
            // Als er geen current weather is, probeer de eerste beschikbare hourly forecast
            if let firstHourly = oneCallData.hourly?.first {
                print("   - Using first available hourly forecast as fallback")
                let fallbackData = WeatherDataFactory.createWeatherDataPoint(from: firstHourly)
                print("   - Fallback forecast chance of rain: \(fallbackData.chanceOfRain * 100)%")
                print("   - Fallback forecast humidity: \(fallbackData.humidity * 100)%")
                return fallbackData
            }
            
            // Geen weer data beschikbaar - gooi een fout
            print("   - ❌ No weather data available at all")
            throw WeatherError.noData
        }
        
        let currentData = WeatherDataFactory.createWeatherDataPoint(from: current)
        print("   - Current weather chance of rain: \(currentData.chanceOfRain * 100)%")
        print("   - Current weather humidity: \(currentData.humidity * 100)%")
        return currentData
    }
    
    /// Zoek de dichtstbijzijnde hourly forecast
    static func findClosestHourlyForecast(to targetTime: TimeInterval, in hourly: [HourlyForecast]?) -> WeatherDataPoint? {
        guard let hourly = hourly, !hourly.isEmpty else { 
            print("   - ❌ No hourly forecast data available")
            return nil 
        }
        
        print("   - Found \(hourly.count) hourly forecasts")
        
        // Debug info voor alle forecasts
        for (index, forecast) in hourly.enumerated() {
            let forecastTime = Date(timeIntervalSince1970: forecast.dt)
            let difference = targetTime - forecast.dt
            let isFuture = forecast.dt >= targetTime
            print("     - Hourly \(index): \(forecastTime) (diff: \(difference/60) min, future: \(isFuture))")
        }
        
        // Filter forecasts die na of op de target tijd liggen (toekomstige forecasts)
        let futureForecasts = hourly.filter { $0.dt >= targetTime }
        
        if !futureForecasts.isEmpty {
            // Gebruik de eerste toekomstige forecast (dichtstbij de target tijd)
            let closestForecast = futureForecasts[0]
            let difference = closestForecast.dt - targetTime
            let closestTime = Date(timeIntervalSince1970: closestForecast.dt)
            print("   - ✅ Found future forecast: \(closestTime) (diff: \(difference/60) min)")
            return WeatherDataFactory.createWeatherDataPoint(from: closestForecast)
        } else {
            // Als er geen toekomstige forecasts zijn, gebruik de laatste beschikbare
            let lastForecast = hourly.last!
            let difference = targetTime - lastForecast.dt
            let lastTime = Date(timeIntervalSince1970: lastForecast.dt)
            print("   - ⚠️ No future forecasts available, using last available: \(lastTime) (diff: \(difference/60) min)")
            return WeatherDataFactory.createWeatherDataPoint(from: lastForecast)
        }
    }
    
    /// Bouw One Call Weather API URL
    static func buildOneCallWeatherURL(latitude: Double, longitude: Double, apiKey: String) -> URL {
        var components = URLComponents(string: "https://api.openweathermap.org/data/3.0/onecall")!
        
        // Gebruik instellingen voor eenheden
        let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
        let units = useMetricUnits ? "metric" : "imperial"
        
        let queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.6f", latitude)),
            URLQueryItem(name: "lon", value: String(format: "%.6f", longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "lang", value: LanguageManager.shared.currentLanguage == .dutch ? "nl" : "en"), // Taal op basis van app instelling
            URLQueryItem(name: "exclude", value: "daily,alerts,minutely"), // Sluit daily forecast, alerts en minutely uit
            URLQueryItem(name: "mode", value: "json") // Zorg voor JSON response
        ]
        
        components.queryItems = queryItems
        
        let url = components.url!
        print("🌍 One Call Weather API URL: \(url)")
        print("   - Latitude: \(latitude)")
        print("   - Longitude: \(longitude)")
        print("   - Units: \(units)")
        print("   - Language: \(LanguageManager.shared.currentLanguage == .dutch ? "nl" : "en")")
        print("   - Exclude: daily,alerts,minutely")
        return url
    }
}
