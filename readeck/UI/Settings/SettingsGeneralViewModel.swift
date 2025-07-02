import Foundation
import Observation
import SwiftUI

@Observable
class SettingsGeneralViewModel {
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let loadSettingsUseCase: LoadSettingsUseCase
    
    // MARK: - UI Settings
    var selectedTheme: Theme = .system
    // MARK: - Sync Settings
    var autoSyncEnabled: Bool = true
    var syncInterval: Int = 15
    // MARK: - Reading Settings
    var enableReaderMode: Bool = false
    var openExternalLinksInApp: Bool = true
    var autoMarkAsRead: Bool = false
    // MARK: - App Info
    var appVersion: String = "1.0.0"
    var developerName: String = "Your Name"
    // MARK: - Messages
    var errorMessage: String?
    var successMessage: String?
    // MARK: - Data Management (Platzhalter)
    // func clearCache() async {}
    // func resetSettings() async {}
    
    init() {
        let factory = DefaultUseCaseFactory.shared
        self.saveSettingsUseCase = factory.makeSaveSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }
    
    @MainActor
    func loadGeneralSettings() async {
        do {
            if let settings = try await loadSettingsUseCase.execute() {
                selectedTheme = .system // settings.theme ?? .system
                autoSyncEnabled = settings.autoSyncEnabled
                syncInterval = settings.syncInterval
                enableReaderMode = settings.enableReaderMode
                openExternalLinksInApp = settings.openExternalLinksInApp
                autoMarkAsRead = settings.autoMarkAsRead
                appVersion = settings.appVersion ?? "1.0.0"
                developerName = settings.developerName ?? "Your Name"
            }
        } catch {
            errorMessage = "Fehler beim Laden der Einstellungen"
        }
    }
    
    @MainActor
    func saveGeneralSettings() async {
        do {
            try await saveSettingsUseCase.execute(
                selectedTheme: selectedTheme,
                autoSyncEnabled: autoSyncEnabled,
                syncInterval: syncInterval,
                enableReaderMode: enableReaderMode,
                openExternalLinksInApp: openExternalLinksInApp,
                autoMarkAsRead: autoMarkAsRead
            )
            successMessage = "Einstellungen gespeichert"
        } catch {
            errorMessage = "Fehler beim Speichern der Einstellungen"
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
} 
