//
//  WeatherError.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation

enum WeatherError: Error, LocalizedError {
    case invalidResponse
    case apiError(Int, String?)
    case noData
    case networkError(NetworkError)
    case invalidURL
    case decodingError(Error)
    case timeout
    case rateLimitExceeded
    case invalidAPIKey
    case locationServiceError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return LanguageManager.shared.localizedString(for: "Invalid response from weather service")
        case .apiError(let code, let message):
            if let message = message {
                return LanguageManager.shared.localizedString(for: "Weather service error \(code): \(message)")
            }
            return LanguageManager.shared.localizedString(for: "Weather service error: \(code)")
        case .noData:
            return LanguageManager.shared.localizedString(for: "No weather data available")
        case .networkError(let networkError):
            return LanguageManager.shared.localizedString(for: "Network error: \(networkError.localizedDescription)")
        case .invalidURL:
            return LanguageManager.shared.localizedString(for: "Invalid URL for weather API")
        case .decodingError(let error):
            return LanguageManager.shared.localizedString(for: "Error decoding weather data: \(error.localizedDescription)")
        case .timeout:
            return LanguageManager.shared.localizedString(for: "Timeout while fetching weather data")
        case .rateLimitExceeded:
            return LanguageManager.shared.localizedString(for: "Too many API calls, try again later")
        case .invalidAPIKey:
            return LanguageManager.shared.localizedString(for: "Invalid API key")
        case .locationServiceError(let error):
            return LanguageManager.shared.localizedString(for: "Location service error: \(error.localizedDescription)")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return LanguageManager.shared.localizedString(for: "Check your internet connection and try again")
        case .timeout:
            return LanguageManager.shared.localizedString(for: "The server is responding slowly, try again later")
        case .rateLimitExceeded:
            return LanguageManager.shared.localizedString(for: "Wait a few minutes before trying again")
        case .invalidAPIKey:
            return LanguageManager.shared.localizedString(for: "Contact the developer")
        case .apiError(let code, _):
            if code >= 500 {
                return LanguageManager.shared.localizedString(for: "Server problem, try again later")
            } else if code == 401 {
                return LanguageManager.shared.localizedString(for: "Authentication error, contact the developer")
            }
            return LanguageManager.shared.localizedString(for: "Try again later")
        default:
            return LanguageManager.shared.localizedString(for: "Try again")
        }
    }
}

enum NetworkError: Error, LocalizedError {
    case noConnection
    case connectionLost
    case serverUnreachable
    case dnsFailure
    case sslError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return LanguageManager.shared.localizedString(for: "No internet connection")
        case .connectionLost:
            return LanguageManager.shared.localizedString(for: "Connection lost")
        case .serverUnreachable:
            return LanguageManager.shared.localizedString(for: "Server unreachable")
        case .dnsFailure:
            return LanguageManager.shared.localizedString(for: "DNS lookup failed")
        case .sslError:
            return LanguageManager.shared.localizedString(for: "SSL/TLS error")
        case .unknown(let error):
            return LanguageManager.shared.localizedString(for: "Unknown network error: \(error.localizedDescription)")
        }
    }
}
