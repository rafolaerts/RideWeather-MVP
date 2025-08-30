//
//  ErrorHandlingView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI

struct ErrorHandlingView: View {
    @State private var weatherService = WeatherService()
    @State private var coreDataManager = CoreDataManager.shared
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var showingErrorAlert = false
    @State private var currentError: String = ""
    @State private var recoverySuggestion: String = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("Weather Service Error Handling".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: weatherService.isNetworkAvailable ? "wifi" : "wifi.slash")
                                .foregroundColor(weatherService.isNetworkAvailable ? .green : .red)
                            Text("Network Status".localized)
                            Spacer()
                            Text(weatherService.isNetworkAvailable ? "Available".localized : "Not available".localized)
                                .foregroundColor(weatherService.isNetworkAvailable ? .green : .red)
                        }
                        
                        if let lastError = weatherService.lastError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Last Error".localized)
                                Spacer()
                                Text(lastError)
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        Button("Test Network Error".localized) {
                            testNetworkError()
                        }
                        .buttonStyle(.bordered)
                        .disabled(weatherService.isLoading)
                    }
                }
                
                Section("Core Data Error Handling".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: coreDataManager.isReady ? "checkmark.circle" : "xmark.circle")
                                .foregroundColor(coreDataManager.isReady ? .green : .red)
                            Text("Core Data Status".localized)
                            Spacer()
                            Text(coreDataManager.isReady ? "Ready".localized : "Loading...".localized)
                                .foregroundColor(coreDataManager.isReady ? .green : .red)
                        }
                        
                        if let lastError = coreDataManager.lastError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Last Error".localized)
                                Spacer()
                                Text(lastError)
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        if let lastCoreDataError = coreDataManager.lastCoreDataError {
                            HStack {
                                Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                Text("Recovery Suggestion".localized)
                                Spacer()
                                Text(lastCoreDataError.recoverySuggestion ?? "No suggestion".localized)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        HStack {
                            Button("Validate Data".localized) {
                                validateData()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Try Recovery".localized) {
                                attemptRecovery()
                            }
                            .buttonStyle(.bordered)
                            .disabled(coreDataManager.isLoading)
                        }
                    }
                }
                
                Section("Error Recovery Actions".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Clear All Errors".localized) {
                            clearAllErrors()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Refresh Context".localized) {
                            coreDataManager.refreshContext()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Test Save Recovery".localized) {
                            testSaveRecovery()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Error Handling".localized)
            .alert("Error".localized, isPresented: $showingErrorAlert) {
                Button("OK".localized) { }
            } message: {
                Text(currentError)
            }
        }
    }
    
    // MARK: - Test Methods
    
    private func testNetworkError() {
        // Simuleer een netwerk fout
        weatherService.lastError = LanguageManager.shared.localizedString(for: "Test network error - no internet connection")
    }
    
    private func validateData() {
        let errors = coreDataManager.validateAllData()
        if errors.isEmpty {
            currentError = LanguageManager.shared.localizedString(for: "✅ All data is valid")
        } else {
            currentError = LanguageManager.shared.localizedString(for: "❌ Validation errors found:\n") + errors.joined(separator: "\n")
        }
        showingErrorAlert = true
    }
    
    private func attemptRecovery() {
        let success = coreDataManager.attemptRecovery()
        if success {
            currentError = LanguageManager.shared.localizedString(for: "✅ Recovery successful")
        } else {
            currentError = LanguageManager.shared.localizedString(for: "❌ Recovery failed")
        }
        showingErrorAlert = true
    }
    
    private func clearAllErrors() {
        weatherService.lastError = nil
        coreDataManager.clearError()
    }
    
    private func testSaveRecovery() {
        let success = coreDataManager.saveWithRecovery()
        if success {
            currentError = LanguageManager.shared.localizedString(for: "✅ Save recovery successful")
        } else {
            currentError = LanguageManager.shared.localizedString(for: "❌ Save recovery failed")
        }
        showingErrorAlert = true
    }
}

#Preview {
    ErrorHandlingView()
        .environmentObject(LanguageManager.shared)
}
