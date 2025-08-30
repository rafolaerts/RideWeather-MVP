//
//  DebugWeatherView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI

struct DebugWeatherView: View {
    @State private var weatherService = WeatherService()
    @State private var isTesting = false
    @State private var debugOutput = ""
    
    // Coördinaten van Heers, België
    private let heersLatitude = 50.7539
    private let heersLongitude = 5.2989
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Weather API Debug")
                    .font(.title)
                    .padding()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Test Location: Heers, België")
                        .font(.headline)
                    
                    Text("Latitude: \(heersLatitude)")
                    Text("Longitude: \(heersLongitude)")
                    Text("Test Time: 30 August 2025 14:00")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Button(action: {
                    testWeatherAPI()
                }) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "cloud.sun.fill")
                        }
                        Text(isTesting ? "Testing..." : "Test Weather API")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isTesting)
                
                ScrollView {
                    Text(debugOutput.isEmpty ? "Debug output will appear here..." : debugOutput)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug Weather")
        }
    }
    
    private func testWeatherAPI() {
        isTesting = true
        debugOutput = "Starting weather API test...\n"
        
        // Maak een test datum aan: 30 August 2025 14:00
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 8
        dateComponents.day = 30
        dateComponents.hour = 14
        dateComponents.minute = 0
        dateComponents.second = 0
        
        let calendar = Calendar.current
        guard let testDate = calendar.date(from: dateComponents) else {
            debugOutput += "❌ Could not create test date\n"
            isTesting = false
            return
        }
        
        Task {
            await weatherService.debugWeatherAPI(
                for: heersLatitude, 
                longitude: heersLongitude, 
                at: testDate
            )
            
            // Wacht even om alle print statements te laten verschijnen
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            DispatchQueue.main.async {
                isTesting = false
                debugOutput += "\n✅ Test completed. Check Xcode console for detailed output."
            }
        }
    }
}

#Preview {
    DebugWeatherView()
}
