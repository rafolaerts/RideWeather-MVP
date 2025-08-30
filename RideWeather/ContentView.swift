//
//  ContentView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var tripStore = CoreDataTripStore()
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        ZStack {
            // Hoofdinhoud van de app
            TripListView(coreDataStore: tripStore)
                .onAppear {
                    // Eenvoudige initialisatie wanneer Core Data klaar is
                    if CoreDataManager.shared.isReady {
                        tripStore = CoreDataTripStore(
                            context: CoreDataManager.shared.managedObjectContext,
                            coreDataManager: CoreDataManager.shared
                        )
                    }
                }
            
            // Splash screen overlay
            SplashScreenView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LanguageManager.shared)
}
