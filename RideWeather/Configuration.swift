import Foundation

/// Centrale configuratie voor de RideWeather app
/// Bevat API keys en andere configuratie waarden die per build configuratie kunnen verschillen
struct Configuration {
    
    // MARK: - API Keys
    
    /// OpenWeatherMap API key voor weer data
    /// Haalt de API key op uit Core Data (gebruiker-specifiek)
    static var openWeatherMapAPIKey: String {
        // Haal API key op uit Core Data (gebruiker-specifiek)
        if let userAPIKey = CoreDataManager.shared.getAPIKey(), !userAPIKey.isEmpty {
            return userAPIKey
        }
        
        // Geen API key gevonden - return lege string
        return ""
    }
    
    // MARK: - API Endpoints
    
    /// Base URL voor OpenWeatherMap API
    static let openWeatherMapBaseURL = "https://api.openweathermap.org/data/3.0"
    
    // MARK: - Build Configuration
    
    /// Huidige build configuratie
    static var buildConfiguration: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }
    
    /// Of we in debug mode zijn
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Validation
    
    /// Valideer of de configuratie correct is ingesteld
    static func validateConfiguration() -> Bool {
        let apiKey = openWeatherMapAPIKey
        
        // Controleer of de API key een geldig formaat heeft (32 karakters voor OpenWeatherMap)
        if apiKey.count != 32 && !apiKey.isEmpty {
            return false
        }
        
        return true
    }
}
