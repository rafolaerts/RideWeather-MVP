import Foundation

// MARK: - App Constants
/// Centrale locatie voor alle app constanten om magic numbers te elimineren

struct AppConstants {
    
    // MARK: - Configuration Validation
    
    /// Valideer de app configuratie bij startup
    static func validateAppConfiguration() {
        #if DEBUG
        print("🔧 Valideren van app configuratie...")
        #endif
        _ = Configuration.validateConfiguration()
    }
    
    // MARK: - Time Constants
    struct Time {
        /// 1 uur in seconden
        static let oneHour: TimeInterval = 3600
        
        /// 30 minuten in seconden
        static let thirtyMinutes: TimeInterval = 1800
        
        /// 1 minuut in seconden
        static let oneMinute: TimeInterval = 60
        
        /// 2 seconden
        static let twoSeconds: TimeInterval = 2.0
        
        /// 30 seconden
        static let thirtySeconds: TimeInterval = 30.0
    }
    
    // MARK: - Weather Service Constants
    struct WeatherService {
        /// Maximum aantal retry pogingen voor netwerk calls
        static let maxRetries = 3
        
        /// Vertraging tussen retry pogingen in seconden
        static let retryDelay: TimeInterval = Time.twoSeconds
        
        /// Timeout voor netwerk requests in seconden
        static let requestTimeout: TimeInterval = Time.thirtySeconds
        
        /// Timeout voor volledige netwerk resources in seconden
        static let resourceTimeout: TimeInterval = requestTimeout * 2
        
        /// Cache vervaldatum in seconden (30 minuten)
        static let cacheExpirationInterval: TimeInterval = Time.thirtyMinutes
        
        /// Maximum aantal cache entries om geheugengebruik te beperken
        static let maxCacheEntries = 100
    }
    
    // MARK: - Trip Constants
    struct Trip {
        /// Standaard trip duur voor preview data (1 uur)
        static let defaultDuration: TimeInterval = Time.oneHour
        
        /// Minimum temperatuur voor koud weer waarschuwing in Celsius
        static let coldWeatherThreshold: Double = 5.0
        
        /// Standaard regen kans drempel in percentage
        static let defaultRainChanceThreshold: Double = 50.0
        
        /// Standaard regen hoeveelheid drempel in mm
        static let defaultRainAmountThreshold: Double = 0.3
    }
    
    // MARK: - Settings Constants
    struct Settings {
        /// Standaard weather cache TTL in seconden (1 uur)
        static let defaultWeatherCacheTTL: TimeInterval = Time.oneHour
        
        /// Standaard regen notificatie tijd in minuten
        static let defaultRainNotificationMinutes = 30
        
        /// Minimum regen hoeveelheid drempel in mm
        static let minRainAmountThreshold: Double = 0.1
        
        /// Maximum regen hoeveelheid drempel in mm
        static let maxRainAmountThreshold: Double = 5.0
        
        /// Stap grootte voor regen hoeveelheid slider
        static let rainAmountStep: Double = 0.1
    }
    
    // MARK: - UI Constants
    struct UI {
        /// Standaard padding waarde
        static let defaultPadding: CGFloat = 16
        
        /// Kleine padding waarde
        static let smallPadding: CGFloat = 8
        
        /// Grote padding waarde
        static let largePadding: CGFloat = 24
        
        /// Standaard corner radius
        static let defaultCornerRadius: CGFloat = 8
        
        /// Standaard animatie duur
        static let defaultAnimationDuration: Double = 0.3
    }
    
    // MARK: - Validation Constants
    struct Validation {
        /// Minimum geldige afstand in kilometers
        static let minDistance: Double = 0.1
        
        /// Maximum geldige afstand in kilometers
        static let maxDistance: Double = 10000.0
        
        /// Minimum geldige snelheid in km/h
        static let minSpeed: Double = 1.0
        
        /// Maximum geldige snelheid in km/h
        static let maxSpeed: Double = 200.0
        
        /// Minimum geldige temperatuur in Celsius
        static let minTemperature: Double = -50.0
        
        /// Maximum geldige temperatuur in Celsius
        static let maxTemperature: Double = 60.0
    }
    
    // MARK: - Network Constants
    struct Network {
        /// Maximum aantal gelijktijdige netwerk requests
        static let maxConcurrentRequests = 5
        
        /// Timeout voor connectiviteit check
        static let connectivityTimeout: TimeInterval = 5.0
        
        /// Maximum aantal redirects
        static let maxRedirects = 3
    }
    
    // MARK: - Core Data Constants
    struct CoreData {
        /// Batch size voor bulk operaties
        static let batchSize = 100
        
        /// Maximum aantal Core Data errors voordat recovery wordt geprobeerd
        static let maxErrorsBeforeRecovery = 5
        
        /// Timeout voor Core Data operaties
        static let operationTimeout: TimeInterval = 10.0
    }
}

// MARK: - Convenience Extensions

extension AppConstants {
    /// Converteer uren naar seconden
    static func hoursToSeconds(_ hours: Double) -> TimeInterval {
        return hours * Time.oneHour
    }
    
    /// Converteer minuten naar seconden
    static func minutesToSeconds(_ minutes: Double) -> TimeInterval {
        return minutes * Time.oneMinute
    }
    
    /// Converteer seconden naar uren
    static func secondsToHours(_ seconds: TimeInterval) -> Double {
        return seconds / Time.oneHour
    }
    
    /// Converteer seconden naar minuten
    static func secondsToMinutes(_ seconds: TimeInterval) -> Double {
        return seconds / Time.oneMinute
    }
}
