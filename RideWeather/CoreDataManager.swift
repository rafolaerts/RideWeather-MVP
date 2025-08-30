//
//  CoreDataManager.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import CoreData
import SwiftUI
import Combine

// LanguageManager is available in the same module

enum CoreDataError: Error, LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case validationFailed([String])
    case contextError(Error)
    case modelError(String)
    case migrationError(Error)
    case corruptionError(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Opslaan mislukt: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Ophalen data mislukt: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Verwijderen mislukt: \(error.localizedDescription)"
        case .validationFailed(let errors):
            return "Validatie fout: \(errors.joined(separator: ", "))"
        case .contextError(let error):
            return "Context fout: \(error.localizedDescription)"
        case .modelError(let message):
            return "Model fout: \(message)"
        case .migrationError(let error):
            return "Migratie fout: \(error.localizedDescription)"
        case .corruptionError(let message):
            return "Data corruptie: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed:
            return "Try again. If the problem persists, restart the app."
        case .fetchFailed:
            return "Check your internet connection and try again."
        case .deleteFailed:
            return "Try again or restart the app."
        case .validationFailed:
            return "Some data is invalid. Try restarting the app."
        case .contextError:
            return "Restart the app to restore the database."
        case .modelError:
            return "Contact the developer."
        case .migrationError:
            return "The app is trying to migrate your data. Wait a moment and try again."
        case .corruptionError:
            return "Your data is corrupted. Restart the app to try to fix this."
        }
    }
}

@Observable
class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let container: NSPersistentContainer
    let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    var isReady = false
    var isLoading = false
    var lastError: String?
    var lastCoreDataError: CoreDataError?
    
    // Public getter voor de context
    var managedObjectContext: NSManagedObjectContext {
        return context
    }
    
    private init() {
        container = NSPersistentContainer(name: "RideWeather")
        
        // Configure persistent store
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
                    // Voeg extra opties toe om entity conflicten te voorkomen
        #if os(iOS)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreFileProtectionKey)
        #endif
        }
        
        // Initialize context first
        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Voeg extra validatie toe
        context.shouldDeleteInaccessibleFaults = true
        
        // Setup notification handling
        setupNotificationHandling()
        
        isLoading = true
        container.loadPersistentStores { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    let coreDataError = CoreDataError.contextError(error)
                    self.lastCoreDataError = coreDataError
                    self.lastError = coreDataError.localizedDescription
                    self.isLoading = false
                }
                print("❌ Core Data failed to load: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self.isReady = true
                self.isLoading = false
                self.lastError = nil
                self.lastCoreDataError = nil
                print("✅ Core Data loaded successfully")
                print("   - Store type: \(self.container.persistentStoreDescriptions.first?.type ?? "Unknown")")
                print("   - Store URL: \(self.container.persistentStoreDescriptions.first?.url?.absoluteString ?? "Unknown")")
                print("   - Model entities: \(self.container.managedObjectModel.entities.count)")
                
                // Valideer het model (veilig)
                self.validateCoreDataModelSafely()
            }
        }
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationHandling() {
        // Handle Core Data save notifications
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] notification in
                guard let self = self,
                      let context = notification.object as? NSManagedObjectContext,
                      context !== self.context else { return }
                
                DispatchQueue.main.async {
                    self.context.mergeChanges(fromContextDidSave: notification)
                }
            }
            .store(in: &cancellables)
        
        // Handle persistent store remote change notifications
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.context.refreshAllObjects()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Cleanup
    
    deinit {
        cancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Context Management
    
    func save() throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("✅ Core Data context saved successfully")
            DispatchQueue.main.async {
                self.lastError = nil
                self.lastCoreDataError = nil
            }
        } catch {
            print("❌ Core Data save failed: \(error)")
            context.rollback()
            
            let coreDataError = CoreDataError.saveFailed(error)
            DispatchQueue.main.async {
                self.lastCoreDataError = coreDataError
                self.lastError = coreDataError.localizedDescription
            }
            
            throw coreDataError
        }
    }
    
    func saveWithRecovery() -> Bool {
        do {
            try save()
            return true
        } catch {
            // Probeer recovery door context te resetten
            print("🔄 Attempting Core Data recovery...")
            context.rollback()
            context.refreshAllObjects()
            
            // Probeer opnieuw te saven
            do {
                try context.save()
                print("✅ Core Data recovery successful")
                DispatchQueue.main.async {
                    self.lastError = nil
                    self.lastCoreDataError = nil
                }
                return true
            } catch {
                print("❌ Core Data recovery failed: \(error)")
                let coreDataError = CoreDataError.saveFailed(error)
                DispatchQueue.main.async {
                    self.lastCoreDataError = coreDataError
                    self.lastError = coreDataError.localizedDescription
                }
                return false
            }
        }
    }
    
    func saveAsync() async {
        await context.perform {
            _ = self.saveWithRecovery()
        }
    }
    
    // MARK: - Trip Operations
    // Moved to CoreDataTripOperations.swift
    
    // MARK: - Weather Operations  
    // Moved to CoreDataWeatherOperations.swift
    
    // MARK: - App Settings Operations
    
    func getAppSettings() -> AppSettingsEntity {
        let request: NSFetchRequest<AppSettingsEntity> = AppSettingsEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            if let existing = try context.fetch(request).first {
                return existing
            }
        } catch {
            print("❌ Failed to fetch app settings: \(error)")
            let coreDataError = CoreDataError.fetchFailed(error)
            DispatchQueue.main.async {
                self.lastCoreDataError = coreDataError
                self.lastError = coreDataError.localizedDescription
            }
        }
        
        // Create default settings if none exist
        let settings = AppSettingsEntity(context: context)
        settings.id = UUID()
        settings.pointDensity = 10
        settings.useMetricUnits = true
        settings.weatherCacheTTL = Int32(AppConstants.Settings.defaultWeatherCacheTTL)
        settings.rainRuleType = "BOTH"
        settings.rainChanceThreshold = 30.0
        settings.rainAmountThreshold = 0.3
        
        _ = saveWithRecovery()
        return settings
    }
    
    func updateAppSettings(useMetricUnits: Bool, weatherCacheTTL: Int32, rainRuleType: String, rainChanceThreshold: Double, rainAmountThreshold: Double) {
        let settings = getAppSettings()
        settings.useMetricUnits = useMetricUnits
        settings.weatherCacheTTL = Int32(weatherCacheTTL)
        settings.rainRuleType = rainRuleType
        settings.rainChanceThreshold = rainChanceThreshold
        settings.rainAmountThreshold = rainAmountThreshold
        
        _ = saveWithRecovery()
    }
    
    /// Update API key in app settings
    func updateAPIKey(_ apiKey: String?) {
        let settings = getAppSettings()
        settings.apiKey = apiKey
        
        if saveWithRecovery() {
            print("✅ API key updated successfully")
            if let key = apiKey {
                print("🔑 New API key: \(String(key.prefix(8)))...")
            } else {
                print("🗑️ API key removed")
            }
        } else {
            print("❌ Failed to save API key")
        }
    }
    
    /// Get current API key from app settings
    func getAPIKey() -> String? {
        let settings = getAppSettings()
        return settings.apiKey
    }
    
    /// Reset app settings to default values
    func resetAppSettingsToDefaults() {
        let settings = getAppSettings()
        settings.pointDensity = 10
        settings.useMetricUnits = true
        settings.weatherCacheTTL = Int32(AppConstants.Settings.defaultWeatherCacheTTL)
        settings.rainRuleType = "BOTH"
        settings.rainChanceThreshold = 30.0
        settings.rainAmountThreshold = 0.3

        
        _ = saveWithRecovery()
        print("✅ App settings reset to defaults")
    }
    
    /// Check if app settings need to be updated to new defaults
    func checkAndUpdateSettingsIfNeeded() {
        let settings = getAppSettings()
        var needsUpdate = false
        
        // Check if rain amount threshold is still using old default (1.0 mm)
        if settings.rainAmountThreshold >= 1.0 {
            print("🔄 Updating rain amount threshold from \(settings.rainAmountThreshold) to 0.3 mm")
            settings.rainAmountThreshold = 0.3
            needsUpdate = true
        }
        
        // Check if rain chance threshold is still using old default (50%)
        if settings.rainChanceThreshold >= 50.0 {
            print("🔄 Updating rain chance threshold from \(settings.rainChanceThreshold)% to 30%")
            settings.rainChanceThreshold = 30.0
            needsUpdate = true
        }
        
        if needsUpdate {
            _ = saveWithRecovery()
            print("✅ App settings updated to new defaults")
        }
    }
    
    // MARK: - Data Migration Helpers
    
    func migrateFromUserDefaults() {
        // This will be implemented later when we're ready to migrate
        print("🔄 UserDefaults migration not yet implemented")
    }
    
    func exportData() -> Data? {
        // This will be implemented later for data export functionality
        print("🔄 Data export not yet implemented")
        return nil
    }
    
    // MARK: - Core Data Model Validation
    
    private func validateCoreDataModelSafely() {
        // Veilige validatie zonder entity class referenties
        print("🔍 Validating Core Data model...")
        
        let model = container.managedObjectModel
        print("✅ Core Data model loaded successfully")
        print("   - Model version: \(model.versionIdentifiers)")
        print("   - Entity count: \(model.entities.count)")
        
        for entity in model.entities {
            print("   - Entity: \(entity.name ?? "Unknown") (\(entity.properties.count) properties)")
        }
    }
    
    // MARK: - Error Recovery & Data Integrity
    
    func clearError() {
        lastError = nil
        lastCoreDataError = nil
    }
    
    func refreshContext() {
        context.refreshAllObjects()
    }
    
    /// Probeer de Core Data stack te herstellen bij ernstige problemen
    func attemptRecovery() -> Bool {
        print("🔄 Attempting Core Data recovery...")
        
        // Reset context
        context.rollback()
        context.refreshAllObjects()
        
        // Probeer opnieuw te saven
        do {
            try context.save()
            print("✅ Core Data recovery successful")
            DispatchQueue.main.async {
                self.lastError = nil
                self.lastCoreDataError = nil
            }
            return true
        } catch {
            print("❌ Core Data recovery failed: \(error)")
            let coreDataError = CoreDataError.contextError(error)
            DispatchQueue.main.async {
                self.lastCoreDataError = coreDataError
                self.lastError = coreDataError.localizedDescription
            }
            return false
        }
    }
    
    /// Valideer alle data in de database
    func validateAllData() -> [String] {
        var errors: [String] = []
        
        // Valideer trips
        let tripErrors = validateTripData()
        errors.append(contentsOf: tripErrors)
        
        // Valideer weather data en route points (moved to extensions)
        // Deze functies zijn nu beschikbaar via de extensions
        
        if !errors.isEmpty {
            let coreDataError = CoreDataError.validationFailed(errors)
            DispatchQueue.main.async {
                self.lastCoreDataError = coreDataError
                self.lastError = coreDataError.localizedDescription
            }
        }
        
        return errors
    }
}
