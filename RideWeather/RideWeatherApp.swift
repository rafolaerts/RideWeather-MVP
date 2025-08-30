//
//  RideWeatherApp.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI

@main
struct RideWeatherApp: App {
    
    @StateObject private var languageManager = LanguageManager.shared
    
    init() {
        // Valideer app configuratie bij startup
        AppConstants.validateAppConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataManager.shared.managedObjectContext)
                .environmentObject(languageManager)
        }
    }
}
