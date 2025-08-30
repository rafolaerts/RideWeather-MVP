import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let coreDataStore: CoreDataTripStore
    
    // Vervang @AppStorage door @State properties
    @State private var useMetricUnits = true
    @State private var rainRuleType = "BOTH"
    @State private var rainChanceThreshold = 50.0
    @State private var rainAmountThreshold = 0.3
    @State private var rainNotificationMinutes = 10
    
    // API key management
    @State private var apiKey = ""
    @State private var showingAPIKeyAlert = false
    @State private var apiKeyAlertMessage = ""
    @State private var apiKeyAlertTitle = ""
    
    // Language management
    @EnvironmentObject var languageManager: LanguageManager
    
    private let rainRuleTypeOptions = [
        ("BOTH", "Rain chance AND amount".localized),
        ("CHANCE_ONLY", "Rain chance only".localized),
        ("AMOUNT_ONLY", "Rain amount only".localized)
    ]
    
    private let rainNotificationOptions = [
        (5, "5 minutes before departure".localized),
        (10, "10 minutes before departure".localized),
        (15, "15 minutes before departure".localized),
        (30, "30 minutes before departure".localized)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API CONFIGURATION".localized)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenWeatherMap API Key".localized)
                            .font(.headline)
                        Text("Enter your own OpenWeatherMap API key for weather data".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("API Key".localized)
                        Spacer()
                        Button("Get Free Key".localized) {
                            if let url = URL(string: "https://home.openweathermap.org/users/sign_up") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    SecureField("Enter your API key here".localized, text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: apiKey) { _, newValue in
                            // Remove spaces and validate format
                            let cleanedKey = newValue.replacingOccurrences(of: " ", with: "")
                            if cleanedKey != newValue {
                                apiKey = cleanedKey
                            }
                        }
                    
                    HStack {
                        Button("Save API Key".localized) {
                            saveAPIKey()
                        }
                        .disabled(apiKey.isEmpty)
                        .buttonStyle(.borderedProminent)
                        
                        Button("Remove API Key".localized) {
                            removeAPIKey()
                        }
                        .disabled(apiKey.isEmpty)
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                    
                    if !apiKey.isEmpty {
                        HStack {
                            Text("Current Key".localized)
                            Spacer()
                            Text("\(String(apiKey.prefix(8)))...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("WEATHER SETTINGS".localized)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rain marking rule".localized)
                            .font(.headline)
                        Text("Determine when a route is marked as 'bad weather'".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Rain rule type".localized, selection: $rainRuleType) {
                        ForEach(rainRuleTypeOptions, id: \.0) { value, description in
                            Text(description).tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: rainRuleType) { _, _ in saveSettingsToCoreData() }
                    
                    if rainRuleType == "BOTH" || rainRuleType == "CHANCE_ONLY" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rain chance threshold".localized)
                                .font(.headline)
                            Text("Minimum rain chance (%) to mark as 'bad weather'".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Rain chance threshold".localized)
                            Spacer()
                            Text("\(Int(rainChanceThreshold))%")
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $rainChanceThreshold, in: 1...100, step: 1)
                            .accentColor(.blue)
                            .onChange(of: rainChanceThreshold) { _, _ in saveSettingsToCoreData() }
                    }
                    
                    if rainRuleType == "BOTH" || rainRuleType == "AMOUNT_ONLY" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rain amount threshold".localized)
                                .font(.headline)
                            Text("Minimum rain amount (mm) to mark as 'bad weather'".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Rain amount threshold".localized)
                            Spacer()
                            Text("\(String(format: "%.1f", rainAmountThreshold)) mm")
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $rainAmountThreshold, in: AppConstants.Settings.minRainAmountThreshold...AppConstants.Settings.maxRainAmountThreshold, step: AppConstants.Settings.rainAmountStep)
                            .accentColor(.blue)
                            .onChange(of: rainAmountThreshold) { _, _ in saveSettingsToCoreData() }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rain notification".localized)
                            .font(.headline)
                        Text("When you want to be warned about rain".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Notification time".localized, selection: $rainNotificationMinutes) {
                        ForEach(rainNotificationOptions, id: \.0) { value, description in
                            Text(description).tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: rainNotificationMinutes) { _, _ in saveSettingsToCoreData() }
                }
                
                Section(header: Text("GENERAL SETTINGS".localized)) {
                    Toggle("Metric units".localized, isOn: $useMetricUnits)
                        .onChange(of: useMetricUnits) { _, _ in saveSettingsToCoreData() }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metric units".localized)
                            .font(.headline)
                        Text("Use kilometers and Celsius instead of miles and Fahrenheit".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("LANGUAGE SETTINGS".localized)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("App language".localized)
                            .font(.headline)
                        Text("Choose the language for the app interface".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("App language".localized, selection: $languageManager.currentLanguage) {
                        ForEach(LanguageManager.Language.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: languageManager.currentLanguage) { _, _ in
                        // Language change will trigger app restart notification
                        showLanguageChangeAlert()
                    }
                }
                
                Section(header: Text("APP INFORMATION".localized)) {
                    HStack {
                        Text("Version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build".localized)
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("ERROR HANDLING".localized)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error management".localized)
                            .font(.headline)
                        Text("Monitor and resolve app errors and data issues".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: ErrorHandlingView()) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Open Error Handling".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                

            }
            .navigationTitle("Settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSettingsFromCoreData()
            }
            .alert("Language changed".localized, isPresented: $showingLanguageChangeAlert) {
                Button("OK") {
                    // User acknowledged the language change
                }
            } message: {
                Text("The app language has been changed. Restart the app to apply all changes.".localized)
            }
            .alert(apiKeyAlertTitle, isPresented: $showingAPIKeyAlert) {
                Button("OK") {
                    // User acknowledged the API key alert
                }
            } message: {
                Text(apiKeyAlertMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    
    @State private var showingLanguageChangeAlert = false
    
    private func showLanguageChangeAlert() {
        showingLanguageChangeAlert = true
    }
    
    private func saveSettingsToCoreData() {
        coreDataStore.updateAppSettings(
            useMetricUnits: useMetricUnits,
            weatherCacheTTL: Int32(AppConstants.Settings.defaultWeatherCacheTTL), // Standaard waarde
            rainRuleType: rainRuleType,
            rainChanceThreshold: rainChanceThreshold,
            rainAmountThreshold: rainAmountThreshold,
            rainNotificationMinutes: Int32(rainNotificationMinutes)
        )
    }
    
    private func loadSettingsFromCoreData() {
        let settings = coreDataStore.getAppSettings()
        
        // Update @State waarden met Core Data waarden
        useMetricUnits = settings.useMetricUnits
        rainRuleType = settings.rainRuleType
        rainChanceThreshold = settings.rainChanceThreshold
        rainAmountThreshold = settings.rainAmountThreshold
        rainNotificationMinutes = settings.rainNotificationMinutes
        
        // Load API key from Core Data
        apiKey = coreDataStore.getAPIKey() ?? ""
    }
    
    // MARK: - API Key Management
    
    private func saveAPIKey() {
        // Validate API key format
        guard apiKey.count == 32 else {
            showAPIKeyAlert(
                title: "Invalid API Key Format".localized,
                message: "OpenWeatherMap API keys must be exactly 32 characters long.".localized
            )
            return
        }
        
        // Save to Core Data
        coreDataStore.updateAPIKey(apiKey)
        
        showAPIKeyAlert(
            title: "API Key Saved".localized,
            message: "Your OpenWeatherMap API key has been saved successfully.".localized
        )
        
        print("🔑 API key saved: \(String(apiKey.prefix(8)))...")
    }
    
    private func removeAPIKey() {
        coreDataStore.updateAPIKey(nil)
        apiKey = ""
        
        showAPIKeyAlert(
            title: "API Key Removed".localized,
            message: "Your OpenWeatherMap API key has been removed. The app will use the default API key if available.".localized
        )
        
        print("🗑️ API key removed")
    }
    
    private func showAPIKeyAlert(title: String, message: String) {
        apiKeyAlertTitle = title
        apiKeyAlertMessage = message
        showingAPIKeyAlert = true
    }
}

#Preview {
    SettingsView(coreDataStore: CoreDataTripStore())
        .environmentObject(LanguageManager.shared)
}

