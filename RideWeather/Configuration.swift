import Foundation

/// Centrale configuratie voor de RideWeather app
/// Bevat API keys en andere configuratie waarden die per build configuratie kunnen verschillen
struct Configuration {
    
    // MARK: - API Keys
    
    /// OpenWeatherMap API key voor weer data
    /// Haalt de API key op uit Core Data (gebruiker-specifiek) of fallback naar bundle info
    static var openWeatherMapAPIKey: String {
        // Eerst proberen API key uit Core Data te halen (gebruiker-specifiek)
        if let userAPIKey = CoreDataManager.shared.getAPIKey(), !userAPIKey.isEmpty {
            print("🔑 Using user-provided API key: \(String(userAPIKey.prefix(8)))...")
            return userAPIKey
        }
        
        // Fallback naar bundle info (voor ontwikkelaars die hun eigen key willen gebruiken)
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String,
              !apiKey.isEmpty else {
            // GEEN fallback - API key moet correct geconfigureerd zijn
            fatalError("OpenWeatherMap API key is niet geconfigureerd. Voeg OPENWEATHER_API_KEY toe aan je project configuratie of stel een API key in via de app settings.")
        }
        
        print("🔑 Using bundle API key: \(String(apiKey.prefix(8)))...")
        return apiKey
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
        if apiKey.count != 32 {
                    #if DEBUG
        print("⚠️ Waarschuwing: OpenWeatherMap API key heeft onverwacht formaat")
        #endif
        return false
    }
    
    #if DEBUG
    print("✅ Configuratie validatie geslaagd")
    print("   - Build configuratie: \(buildConfiguration)")
    print("   - API key: \(String(apiKey.prefix(8)))...")
    #endif
        
        return true
    }
}
