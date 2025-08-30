//
//  LanguageManager.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            updateAppLanguage()
        }
    }
    
    enum Language: String, CaseIterable {
        case dutch = "nl"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .dutch:
                return NSLocalizedString("Dutch", comment: "Dutch language name")
            case .english:
                return NSLocalizedString("English", comment: "English language name")
            }
        }
        
        var locale: Locale {
            return Locale(identifier: self.rawValue)
        }
    }
    
    private init() {
        // Load saved language or default to Dutch
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Default to Dutch
            self.currentLanguage = .dutch
        }
        
        // Set initial language
        updateAppLanguage()
    }
    
    private func updateAppLanguage() {
        // Update the app's language
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Post notification for language change
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    func localizedString(for key: String, comment: String = "") -> String {
        let bundle = Bundle.main
        let language = currentLanguage.rawValue
        
        if let languagePath = bundle.path(forResource: language, ofType: "lproj"),
           let languageBundle = Bundle(path: languagePath) {
            return languageBundle.localizedString(forKey: key, value: key, table: nil)
        }
        
        // Fallback to main bundle
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(for: self)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    func localizedText(_ key: String, comment: String = "") -> some View {
        let text = LanguageManager.shared.localizedString(for: key, comment: comment)
        return self.modifier(LocalizedTextModifier(text: text))
    }
}

struct LocalizedTextModifier: ViewModifier {
    let text: String
    
    func body(content: Content) -> some View {
        content
    }
}
