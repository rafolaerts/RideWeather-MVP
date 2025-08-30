//
//  LocationService.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import CoreLocation

class LocationService: ObservableObject {
    private let geocoder = CLGeocoder()
    private var placeNameCache: [String: String] = [:] // Cache voor plaatsnamen
    
    /// Haal plaatsnaam op voor gegeven coördinaten
    func getPlaceName(for latitude: Double, longitude: Double) async -> String {
        let cacheKey = "\(latitude),\(longitude)"
        
        // Controleer cache eerst
        if let cachedName = placeNameCache[cacheKey] {
            return cachedName
        }
        
        do {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                let placeName = formatPlaceName(from: placemark)
                placeNameCache[cacheKey] = placeName
                return placeName
            }
        } catch {
            print("❌ Reverse geocoding error: \(error)")
        }
        
        // Fallback: gebruik coördinaten als plaatsnaam niet beschikbaar is
        let fallbackName = String(format: "%.2f°, %.2f°", latitude, longitude)
        placeNameCache[cacheKey] = fallbackName
        return fallbackName
    }
    
    /// Format plaatsnaam uit placemark data
    private func formatPlaceName(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        // Voeg plaatsnaam toe als beschikbaar
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        // Voeg administratieve gebied toe als beschikbaar
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        // Voeg land toe als beschikbaar
        if let country = placemark.country {
            components.append(localizeCountryName(country))
        }
        
        // Als geen componenten beschikbaar zijn, gebruik sublocality
        if components.isEmpty, let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        
        // Als nog steeds leeg, gebruik thoroughfare
        if components.isEmpty, let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        // Combineer componenten
        if components.isEmpty {
            return LanguageManager.shared.localizedString(for: "Unknown location")
        } else {
            return components.joined(separator: ", ")
        }
    }
    
    /// Leeg cache (bijvoorbeeld bij app restart)
    func clearCache() {
        placeNameCache.removeAll()
    }
    
    /// Lokaliseer landnamen naar de huidige app taal
    private func localizeCountryName(_ countryName: String) -> String {
        switch countryName.lowercased() {
        case "belgië", "belgium":
            return LanguageManager.shared.currentLanguage == .dutch ? "België" : "Belgium"
        case "nederland", "netherlands":
            return LanguageManager.shared.currentLanguage == .dutch ? "Nederland" : "Netherlands"
        case "duitsland", "germany":
            return LanguageManager.shared.currentLanguage == .dutch ? "Duitsland" : "Germany"
        case "frankrijk", "france":
            return LanguageManager.shared.currentLanguage == .dutch ? "Frankrijk" : "France"
        case "luxemburg", "luxembourg":
            return LanguageManager.shared.currentLanguage == .dutch ? "Luxemburg" : "Luxembourg"
        case "zwitserland", "switzerland":
            return LanguageManager.shared.currentLanguage == .dutch ? "Zwitserland" : "Switzerland"
        case "oostenrijk", "austria":
            return LanguageManager.shared.currentLanguage == .dutch ? "Oostenrijk" : "Austria"
        case "italië", "italy":
            return LanguageManager.shared.currentLanguage == .dutch ? "Italië" : "Italy"
        case "spanje", "spain":
            return LanguageManager.shared.currentLanguage == .dutch ? "Spanje" : "Spain"
        case "portugal":
            return LanguageManager.shared.currentLanguage == .dutch ? "Portugal" : "Portugal"
        default:
            return countryName
        }
    }
}
