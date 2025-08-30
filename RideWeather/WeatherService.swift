//
//  WeatherService.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import CoreLocation
import Network

// MARK: - API Key Status Delegate

protocol APIKeyStatusDelegate: AnyObject {
    func apiKeyMarkedAsInvalid()
}

@Observable
class WeatherService {
    private let apiKey = Configuration.openWeatherMapAPIKey
    private let locationService = LocationService()
    private let networkMonitor = NWPathMonitor()
    private let session: URLSession
    weak var apiKeyStatusDelegate: APIKeyStatusDelegate?
    
    // Weather data cache om duplicatie te voorkomen
    private var weatherCache: [String: WeatherSnapshot] = [:]
    private let cacheExpirationInterval: TimeInterval = AppConstants.WeatherService.cacheExpirationInterval
    
    var isLoading = false
    var lastError: String?
    var isNetworkAvailable = true
    
    // Retry configuratie
    private let maxRetries = AppConstants.WeatherService.maxRetries
    private let retryDelay: TimeInterval = AppConstants.WeatherService.retryDelay
    private let timeoutInterval: TimeInterval = AppConstants.WeatherService.requestTimeout
    
    init() {
        // Configureer URLSession met timeout en caching
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = AppConstants.WeatherService.resourceTimeout
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: config)
        
        // Start network monitoring
        startNetworkMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                if path.status != .satisfied {
                    self?.lastError = LanguageManager.shared.localizedString(for: "No internet connection available")
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global())
    }
    
    // MARK: - Weather Fetching with Enhanced Error Handling
    
    /// Haal weer data op voor een specifiek route punt met One Call API 3.0
    func fetchWeather(for routePoint: RoutePoint, at time: Date) async throws -> WeatherSnapshot {
        // Controleer of er een API key is geconfigureerd
        guard !apiKey.isEmpty else {
            throw WeatherError.noAPIKey
        }
        
        // Controleer netwerk beschikbaarheid
        guard isNetworkAvailable else {
            throw WeatherError.networkError(.noConnection)
        }
        
        // Controleer cache eerst
        let cacheKey = createCacheKey(for: routePoint, at: time)
        if let cachedWeather = getCachedWeather(for: cacheKey) {
            print("🌤️ Weather data found in cache for route point \(routePoint.id)")
            return cachedWeather
        }
        
        let weather = try await withRetry(maxRetries: maxRetries) {
            try await self.performWeatherFetch(for: routePoint, at: time)
        }
        
        // Cache de nieuwe weather data
        cacheWeather(weather, for: cacheKey)
        
        return weather
    }
    
    private func performWeatherFetch(for routePoint: RoutePoint, at time: Date) async throws -> WeatherSnapshot {
        let url = WeatherHelpers.buildOneCallWeatherURL(
            latitude: routePoint.latitude, 
            longitude: routePoint.longitude, 
            apiKey: apiKey
        )
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.invalidResponse
            }
            
            // Handle verschillende HTTP status codes
            switch httpResponse.statusCode {
            case 200:
                break // Success
            case 401:
                // Notify delegate dat API key ongeldig is
                print("🔑 401 Unauthorized - API key ongeldig, notifying delegate...")
                Task { @MainActor in
                    if let delegate = self.apiKeyStatusDelegate {
                        print("🔑 Delegate found, calling apiKeyMarkedAsInvalid()")
                        delegate.apiKeyMarkedAsInvalid()
                    } else {
                        print("⚠️ No delegate set for API key status")
                    }
                }
                throw WeatherError.invalidAPIKey
            case 429:
                throw WeatherError.rateLimitExceeded
            case 500...599:
                throw WeatherError.apiError(httpResponse.statusCode, "Server fout")
            default:
                let errorMessage = String(data: data, encoding: .utf8)
                throw WeatherError.apiError(httpResponse.statusCode, errorMessage)
            }
            
            let oneCallData: OneCallWeatherResponse
            do {
                oneCallData = try JSONDecoder().decode(OneCallWeatherResponse.self, from: data)
            } catch {
                print("❌ JSON Parsing Error: \(error)")
                print("   Raw data: \(String(data: data, encoding: .utf8) ?? "Onleesbaar")")
                throw WeatherError.decodingError(error)
            }
            
            // Debug informatie over de API response
            print("🌤️ One Call API Response voor punt \(routePoint.id):")
            print("   - API Response bevat:")
            print("     - Current weather: \(oneCallData.current != nil ? "✅" : "❌")")
            print("     - Hourly forecast: \(oneCallData.hourly?.count ?? 0) entries")
            
            // Zoek de beste forecast data voor het gegeven tijdstip
            let weatherData = try WeatherHelpers.findBestForecastData(for: time, in: oneCallData)
            
            // Haal plaatsnaam op via reverse geocoding
            let placeName = await locationService.getPlaceName(for: routePoint.latitude, longitude: routePoint.longitude)
            
            // Maak WeatherSnapshot aan
            return WeatherSnapshot(
                latitude: routePoint.latitude,
                longitude: routePoint.longitude,
                temperature: weatherData.temperature,
                humidity: weatherData.humidity,
                windSpeed: weatherData.windSpeed,
                windDirection: weatherData.windDirection,
                chanceOfRain: weatherData.chanceOfRain,
                rainAmount: weatherData.rainAmount,
                description: weatherData.description,
                icon: weatherData.icon,
                timestamp: time,
                placeName: placeName
            )
            
        } catch {
            print("❌ Weather fetch error for route point \(routePoint.id): \(error)")
            throw error
        }
    }
    
    // MARK: - Retry Mechanism
    
    private func withRetry<T>(maxRetries: Int, operation: () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Stop retrying voor bepaalde error types
                if let weatherError = error as? WeatherError {
                    switch weatherError {
                    case .invalidAPIKey, .rateLimitExceeded:
                        throw weatherError // Geen retry voor deze errors
                    default:
                        break
                    }
                }
                
                if attempt < maxRetries {
                    print("⚠️ Attempt \(attempt) failed, retrying in \(retryDelay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? WeatherError.networkError(.unknown(NSError()))
    }
    
    // MARK: - Weather Caching
    
    private func createCacheKey(for routePoint: RoutePoint, at time: Date) -> String {
        let roundedTime = round(time.timeIntervalSince1970 / AppConstants.Time.oneHour) * AppConstants.Time.oneHour // Rond af naar uur
        return "\(routePoint.latitude),\(routePoint.longitude),\(roundedTime)"
    }
    
    private func getCachedWeather(for cacheKey: String) -> WeatherSnapshot? {
        guard let cached = weatherCache[cacheKey] else { return nil }
        
        // Controleer of cache nog geldig is
        let age = Date().timeIntervalSince(cached.timestamp)
        if age < cacheExpirationInterval {
            return cached
        } else {
            // Verwijder verlopen cache entry
            weatherCache.removeValue(forKey: cacheKey)
            return nil
        }
    }
    
    private func cacheWeather(_ weather: WeatherSnapshot, for cacheKey: String) {
        weatherCache[cacheKey] = weather
        print("🌤️ Weather data cached for key: \(cacheKey)")
        
        // Beperk cache grootte
        if weatherCache.count > AppConstants.WeatherService.maxCacheEntries {
            let oldestKey = weatherCache.keys.first
            if let key = oldestKey {
                weatherCache.removeValue(forKey: key)
                print("🗑️ Oldest cache entry removed to limit memory usage")
            }
        }
    }
    
    // MARK: - Error Conversion
    
    private func convertURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .cannotConnectToHost, .cannotFindHost:
            return .serverUnreachable
        case .dnsLookupFailed:
            return .dnsFailure
        case .secureConnectionFailed, .serverCertificateUntrusted:
            return .sslError
        default:
            return .unknown(error)
        }
    }
    
    /// Haal weer data op voor alle route punten van een trip
    func fetchWeatherForTrip(_ trip: Trip) async throws -> [WeatherSnapshot] {
        var weatherSnapshots: [WeatherSnapshot] = []
        
        print("🌤️ Start fetching weather for trip: \(trip.name)")
        print("   - Number of route points: \(trip.routePoints.count)")
        
        for (index, routePoint) in trip.routePoints.enumerated() {
            do {
                print("   - Fetching weather for point \(index + 1)/\(trip.routePoints.count): \(routePoint.id)")
                print("      - Location: \(routePoint.latitude), \(routePoint.longitude)")
                print("      - Time: \(routePoint.estimatedPassTime)")
                
                let weather = try await fetchWeather(for: routePoint, at: routePoint.estimatedPassTime)
                weatherSnapshots.append(weather)
                
                print("      - ✅ Weather data received: \(weather.description)")
                
                // Kleine pauze tussen API calls om rate limiting te voorkomen
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconden
                
            } catch {
                print("❌ Fout bij ophalen weer voor punt \(routePoint.id): \(error)")
                
                // Probeer een bredere locatie als fallback
                print("   - 🔄 Trying broader location as fallback...")
                if let fallbackWeather = await tryBroaderLocation(for: routePoint, at: routePoint.estimatedPassTime) {
                    print("   - ✅ Fallback weather data found with broader location")
                    weatherSnapshots.append(fallbackWeather)
                } else {
                    print("   - ❌ No fallback weather data available")
                    // Maak een fallback weather snapshot aan
                    let fallbackWeather = WeatherDataFactory.createFallbackWeatherSnapshot(
                        latitude: routePoint.latitude,
                        longitude: routePoint.longitude,
                        timestamp: routePoint.estimatedPassTime
                    )
                    weatherSnapshots.append(fallbackWeather)
                }
            }
        }
        
        print("✅ Weather fetching completed for trip: \(trip.name)")
        print("   - Total weather snapshots: \(weatherSnapshots.count)")
        
        return weatherSnapshots
    }
    
    /// Probeer weer data op te halen voor een bredere locatie als fallback
    private func tryBroaderLocation(for routePoint: RoutePoint, at time: Date) async -> WeatherSnapshot? {
        // Probeer eerst met een bredere radius rond de locatie
        let broaderLocations = [
            (routePoint.latitude + 0.01, routePoint.longitude + 0.01),
            (routePoint.latitude - 0.01, routePoint.longitude - 0.01),
            (routePoint.latitude + 0.02, routePoint.longitude + 0.02),
            (routePoint.latitude - 0.02, routePoint.longitude - 0.02)
        ]
        
        for (index, (lat, lon)) in broaderLocations.enumerated() {
            do {
                print("     - Trying broader location \(index + 1): \(lat), \(lon)")
                
                let url = WeatherHelpers.buildOneCallWeatherURL(
                    latitude: lat, 
                    longitude: lon, 
                    apiKey: apiKey
                )
                
                let (data, response) = try await session.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continue
                }
                
                let oneCallData = try JSONDecoder().decode(OneCallWeatherResponse.self, from: data)
                let weatherData = try WeatherHelpers.findBestForecastData(for: time, in: oneCallData)
                
                let placeName = await locationService.getPlaceName(for: lat, longitude: lon)
                
                return WeatherSnapshot(
                    latitude: routePoint.latitude, // Behoud originele coördinaten
                    longitude: routePoint.longitude,
                    temperature: weatherData.temperature,
                    humidity: weatherData.humidity,
                    windSpeed: weatherData.windSpeed,
                    windDirection: weatherData.windDirection,
                    chanceOfRain: weatherData.chanceOfRain,
                    rainAmount: weatherData.rainAmount,
                    description: weatherData.description,
                    icon: weatherData.icon,
                    timestamp: time,
                    placeName: placeName
                )
                
            } catch {
                print("       - ❌ Error for location \(index + 1): \(error)")
                continue
            }
        }
        
        print("     - ❌ No weather data found for any broader location")
        return nil
    }
    
    // MARK: - Debug Functions
    
    /// Debug functie om de exacte API call te testen
    func debugWeatherAPI(for latitude: Double, longitude: Double, at time: Date) async {
        print("🔍 DEBUG: Testing weather API call")
        print("   - Latitude: \(latitude)")
        print("   - Longitude: \(longitude)")
        print("   - Time: \(time)")
        
        let url = WeatherHelpers.buildOneCallWeatherURL(
            latitude: latitude, 
            longitude: longitude, 
            apiKey: apiKey
        )
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return
            }
            
            print("   - HTTP Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let rawResponse = String(data: data, encoding: .utf8) ?? "Onleesbaar"
                print("   - Raw API Response:")
                print(rawResponse)
                
                // Probeer te decoderen
                do {
                    let oneCallData = try JSONDecoder().decode(OneCallWeatherResponse.self, from: data)
                    print("   - Decoded successfully:")
                    print("     - Current weather: \(oneCallData.current != nil ? "✅" : "❌")")
                    print("     - Hourly forecasts: \(oneCallData.hourly?.count ?? 0)")
                    
                    if let hourly = oneCallData.hourly {
                        print("   - Hourly forecasts:")
                        for (index, forecast) in hourly.enumerated() {
                            let forecastTime = Date(timeIntervalSince1970: forecast.dt)
                            let timeDiff = time.timeIntervalSince(forecastTime) / 60.0
                            print("     \(index): \(forecastTime) (diff: \(timeDiff) min)")
                            print("       - Temp: \(forecast.temp)°C")
                            print("       - Description: \(forecast.weather.first?.description ?? "Unknown")")
                            print("       - Clouds: \(forecast.clouds)%")
                            print("       - Rain chance: \(forecast.pop * 100)%")
                        }
                    }
                    
                    // Test de findBestForecastData functie
                    do {
                        let weatherData = try WeatherHelpers.findBestForecastData(for: time, in: oneCallData)
                        print("   - Best forecast data selected:")
                        print("     - Temperature: \(weatherData.temperature)°C")
                        print("     - Description: \(weatherData.description)")
                        print("     - Rain chance: \(weatherData.chanceOfRain * 100)%")
                    } catch {
                        print("   - ❌ Error finding best forecast: \(error)")
                    }
                    
                } catch {
                    print("   - ❌ JSON decode error: \(error)")
                }
            } else {
                let errorMessage = String(data: data, encoding: .utf8)
                print("   - ❌ API Error: \(errorMessage ?? "Unknown")")
            }
            
        } catch {
            print("   - ❌ Network error: \(error)")
        }
    }
}

