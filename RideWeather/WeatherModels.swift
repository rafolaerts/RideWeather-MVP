//
//  WeatherModels.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation

// MARK: - One Call API 3.0 Response Models

struct OneCallWeatherResponse: Codable {
    let lat: Double
    let lon: Double
    let timezone: String
    let timezoneOffset: Int
    let current: CurrentWeather?
    let hourly: [HourlyForecast]?
    
    enum CodingKeys: String, CodingKey {
        case lat, lon, timezone, current, hourly
        case timezoneOffset = "timezone_offset"
    }
}

struct CurrentWeather: Codable {
    let dt: TimeInterval
    let temp: Double
    let feelsLike: Double
    let pressure: Int
    let humidity: Int
    let dewPoint: Double
    let uvi: Double
    let clouds: Int
    let visibility: Int? // Optional omdat niet altijd aanwezig in API response
    let windSpeed: Double
    let windDeg: Int
    let weather: [WeatherCondition]
    let pop: Double?
    let rain: RainData?
    
    enum CodingKeys: String, CodingKey {
        case dt, temp, pressure, humidity, uvi, clouds, visibility, weather, pop, rain
        case feelsLike = "feels_like"
        case dewPoint = "dew_point"
        case windSpeed = "wind_speed"
        case windDeg = "wind_deg"
    }
}

struct HourlyForecast: Codable {
    let dt: TimeInterval
    let temp: Double
    let feelsLike: Double
    let pressure: Int
    let humidity: Int
    let dewPoint: Double
    let uvi: Double
    let clouds: Int
    let visibility: Int? // Optional omdat niet altijd aanwezig in API response
    let windSpeed: Double
    let windDeg: Int
    let weather: [WeatherCondition]
    let pop: Double
    let rain: RainData?
    
    enum CodingKeys: String, CodingKey {
        case dt, temp, pressure, humidity, uvi, clouds, visibility, weather, pop, rain
        case feelsLike = "feels_like"
        case dewPoint = "dew_point"
        case windSpeed = "wind_speed"
        case windDeg = "wind_deg"
    }
}

struct WeatherCondition: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct RainData: Codable {
    let oneHour: Double?
    
    enum CodingKeys: String, CodingKey {
        case oneHour = "1h"
    }
}

// MARK: - Weather Data Point

struct WeatherDataPoint {
    let temperature: Double
    let chanceOfRain: Double
    let rainAmount: Double
    let description: String
    let humidity: Double
    let windSpeed: Double
    let windDirection: Double
    let icon: String
}
