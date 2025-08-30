//
//  TripListView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI

enum TripSortOption: String, CaseIterable {
    case dateDesc = "date_desc"
    case dateAsc = "date_asc"
    case nameAsc = "name_asc"
    case nameDesc = "name_desc"
    case distanceDesc = "distance_desc"
    case distanceAsc = "distance_asc"
    case timeDesc = "time_desc"
    case timeAsc = "time_asc"
    
    var displayName: String {
        switch self {
        case .dateDesc: return "Date (newest first)".localized
        case .dateAsc: return "Date (oldest first)".localized
        case .nameAsc: return "Name (A-Z)".localized
        case .nameDesc: return "Name (Z-A)".localized
        case .distanceDesc: return "Distance (longest first)".localized
        case .distanceAsc: return "Distance (shortest first)".localized
        case .timeDesc: return "Time (longest first)".localized
        case .timeAsc: return "Time (shortest first)".localized
        }
    }
    
    var icon: String {
        switch self {
        case .dateDesc, .dateAsc: return "calendar"
        case .nameAsc, .nameDesc: return "textformat"
        case .distanceDesc, .distanceAsc: return "ruler"
        case .timeDesc, .timeAsc: return "clock"
        }
    }
}

struct TripListView: View {
    let coreDataStore: CoreDataTripStore
    @State private var showingAddTrip = false
    @State private var showingSettings = false
    @State private var refreshTrigger = false // Trigger voor UI refresh
    @State private var sortOption: TripSortOption = .dateDesc
    @State private var showingSortOptions = false
    @State private var isEditMode = false
    @EnvironmentObject var languageManager: LanguageManager
    
    // API key status management
    @State private var apiKeyStatusManager = APIKeyStatusManager()
    @State private var weatherService = WeatherService()
    
    var sortedTrips: [Trip] {
        switch sortOption {
        case .dateDesc:
            return coreDataStore.trips.sorted { $0.date > $1.date }
        case .dateAsc:
            return coreDataStore.trips.sorted { $0.date < $1.date }
        case .nameAsc:
            return coreDataStore.trips.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            return coreDataStore.trips.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .distanceDesc:
            return coreDataStore.trips.sorted { $0.distance > $1.distance }
        case .distanceAsc:
            return coreDataStore.trips.sorted { $0.distance < $1.distance }
        case .timeDesc:
            return coreDataStore.trips.sorted { $0.startTime.distance(to: $0.arrivalTime) > $1.startTime.distance(to: $1.arrivalTime) }
        case .timeAsc:
            return coreDataStore.trips.sorted { $0.startTime.distance(to: $0.arrivalTime) < $1.startTime.distance(to: $1.arrivalTime) }
        }
    }
    
    /// Controleer of er een geldige API key is ingesteld
    var hasValidAPIKey: Bool {
        let status = apiKeyStatusManager.apiKeyStatus
        let result = switch status {
        case .valid:
            true
        case .invalid, .unknown:
            false
        }
        print("🔑 hasValidAPIKey check: status=\(status.description), result=\(result)")
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Logo en titel sectie
                HStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                    
                    Text("RideWeather".localized)
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                
                // Lijst met trips
                List {
                    if coreDataStore.trips.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No trips yet".localized)
                                .font(.title2)
                                .fontWeight(.medium)
                            Text("Add your first motorcycle trip to view weather along your route".localized)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(sortedTrips, id: \.id) { trip in
                            TripRowView(trip: trip, coreDataStore: coreDataStore)
                                .id("\(trip.id)-\(trip.updatedAt.timeIntervalSince1970)") // Force refresh wanneer trip wordt bijgewerkt
                        }
                        .onDelete(perform: deleteTrips)
                    }
                }
                .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
                
                // API Key Waarschuwing Balk
                if !hasValidAPIKey {
                    APIKeyWarningBanner(
                        showingSettings: $showingSettings,
                        apiKeyStatus: apiKeyStatusManager.apiKeyStatus
                    )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !coreDataStore.trips.isEmpty {
                            Menu {
                                Button(action: { showingSortOptions = true }) {
                                    Label("Sort".localized, systemImage: "arrow.up.arrow.down")
                                }
                                
                                Divider()
                                
                                ForEach(TripSortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        sortOption = option
                                    }) {
                                        Label(option.displayName, systemImage: option.icon)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundColor(.blue)
                            }
                            
                            Button(isEditMode ? "Done".localized : "Edit".localized) {
                                isEditMode.toggle()
                            }
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingAddTrip = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddTrip) {
                AddTripView(coreDataStore: coreDataStore)
                    .environmentObject(languageManager)
                    .onDisappear {
                        refreshTrigger.toggle() // Trigger refresh wanneer AddTripView sluit
                    }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(coreDataStore: coreDataStore)
                    .environmentObject(languageManager)
            }
            .onChange(of: showingSettings) { _, isShowing in
                // Update API key status wanneer settings sluit
                // Maar alleen als de status niet al Invalid is
                if !isShowing {
                    print("🔧 Settings closed, checking if we should update API key status")
                    if apiKeyStatusManager.apiKeyStatus != .invalid {
                        print("🔧 Settings closed, updating API key status")
                        apiKeyStatusManager.updateAPIKeyStatus()
                    } else {
                        print("🔒 Settings closed, but API key status is Invalid - not updating")
                    }
                }
            }
            .sheet(isPresented: $showingSortOptions) {
                SortOptionsView(selectedOption: $sortOption)
                    .environmentObject(languageManager)
            }
            .refreshable {
                // Alleen refresh wanneer gebruiker expliciet pull-to-refresh doet
                refreshData()
            }
            .onAppear {
                // Update API key status wanneer view verschijnt
                // Maar alleen als de status niet al Invalid is
                print("🔧 View appeared, checking if we should update API key status")
                if apiKeyStatusManager.apiKeyStatus != .invalid {
                    print("🔧 View appeared, updating API key status")
                    apiKeyStatusManager.updateAPIKeyStatus()
                } else {
                    print("🔒 View appeared, but API key status is Invalid - not updating")
                }
                
                // Stel delegate in voor API key status monitoring
                print("🔧 Setting API key status delegate...")
                weatherService.apiKeyStatusDelegate = apiKeyStatusManager
                print("🔧 Delegate set: \(weatherService.apiKeyStatusDelegate != nil ? "YES" : "NO")")
                
                // Refresh data alleen wanneer view voor het eerst verschijnt
                // Niet elke keer om de lokale state in detail views te behouden
                if coreDataStore.trips.isEmpty {
                    refreshData()
                }
            }
            .onChange(of: refreshTrigger) { _, _ in
                // Refresh data wanneer trigger verandert (bijvoorbeeld na het toevoegen van een trip)
                refreshData()
            }
        }
    }
    
    private func deleteTrips(offsets: IndexSet) {
        coreDataStore.deleteTrips(at: offsets)
        // Schakel edit mode uit na het verwijderen
        isEditMode = false
    }
    
    private func refreshData() {
        coreDataStore.refreshTrips()
    }
}

// MARK: - Sort Options View

struct SortOptionsView: View {
    @Binding var selectedOption: TripSortOption
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(TripSortOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        dismiss()
                    }) {
                        HStack {
                            Label(option.displayName, systemImage: option.icon)
                            Spacer()
                            if option == selectedOption {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Sort".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Trip Row View

struct TripRowView: View {
    let trip: Trip
    let coreDataStore: CoreDataTripStore
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        NavigationLink(destination: TripDetailView(trip: trip, coreDataStore: coreDataStore)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(trip.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(trip.startTime.formatted(date: .omitted, time: .shortened)) - \(trip.arrivalTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Weather summary
                if !trip.weatherData.isEmpty {
                    WeatherSummaryView(weatherData: trip.weatherData)
                }
                
                HStack {
                    Text(trip.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", trip.distance)) km")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Weather Summary View

struct WeatherSummaryView: View {
    let weatherData: [WeatherSnapshot]
    @EnvironmentObject var languageManager: LanguageManager
    
    private var hasHighRainChance: Bool {
        weatherData.contains { $0.chanceOfRain > 0.7 }
    }
    
    private var hasRain: Bool {
        weatherData.contains { $0.rainAmount > 0 }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if hasHighRainChance || hasRain {
                Image(systemName: "cloud.rain.fill")
                    .foregroundColor(.red)
                Text("High chance of rain".localized)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                Text("Goed weer")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    TripListView(coreDataStore: CoreDataTripStore())
        .environmentObject(LanguageManager.shared)
}

// MARK: - API Key Status

/// Status van de API key voor betere state management
enum APIKeyStatus {
    case unknown    // Nog niet gecontroleerd
    case valid      // API key is ingesteld en geldig
    case invalid    // API key is ingesteld maar ongeldig
    
    var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .valid:
            return "Valid"
        case .invalid:
            return "Invalid"
        }
    }
}

// MARK: - API Key Status Manager

@Observable
class APIKeyStatusManager: APIKeyStatusDelegate {
    var apiKeyStatus: APIKeyStatus = .unknown
    
    func apiKeyMarkedAsInvalid() {
        print("🔧 APIKeyStatusManager received API key invalid notification")
        print("🔧 Current status: \(apiKeyStatus.description)")
        apiKeyStatus = .invalid
        print("🔧 Status updated to: \(apiKeyStatus.description)")
    }
    
    func updateAPIKeyStatus() {
        // Als de status al Invalid is, overschrijf deze niet
        // Dit voorkomt dat een API error wordt genegeerd
        if apiKeyStatus == .invalid {
            print("🔒 API key status update: Status is already Invalid, not overwriting")
            return
        }
        
        if let apiKey = CoreDataManager.shared.getAPIKey(), !apiKey.isEmpty {
            print("🔑 API key status update: Valid key found (\(String(apiKey.prefix(8)))...)")
            apiKeyStatus = .valid
        } else {
            print("⚠️ API key status update: No valid API key found")
            apiKeyStatus = .unknown
        }
    }
    
    func markAPIKeyAsInvalid() {
        print("❌ API key marked as invalid due to API error")
        apiKeyStatus = .invalid
    }
}

// MARK: - API Key Warning Banner

struct APIKeyWarningBanner: View {
    @Binding var showingSettings: Bool
    let apiKeyStatus: APIKeyStatus
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        Button(action: {
            print("🔧 API key warning banner tapped - opening settings")
            showingSettings = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleText)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitleText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        switch apiKeyStatus {
        case .unknown:
            return "exclamationmark.triangle.fill"
        case .invalid:
            return "xmark.circle.fill"
        case .valid:
            return "checkmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch apiKeyStatus {
        case .unknown:
            return .orange
        case .invalid:
            return .red
        case .valid:
            return .green
        }
    }
    
    private var borderColor: Color {
        switch apiKeyStatus {
        case .unknown:
            return .orange.opacity(0.3)
        case .invalid:
            return .red.opacity(0.3)
        case .valid:
            return .green.opacity(0.3)
        }
    }
    
    private var titleText: String {
        switch apiKeyStatus {
        case .unknown:
            return "Weather functionality limited".localized
        case .invalid:
            return "Invalid API key detected".localized
        case .valid:
            return "API key configured".localized
        }
    }
    
    private var subtitleText: String {
        switch apiKeyStatus {
        case .unknown:
            return "No OpenWeatherMap API key configured".localized
        case .invalid:
            return "Your API key appears to be invalid".localized
        case .valid:
            return "Weather functionality is available".localized
        }
    }
}
