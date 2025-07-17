import Foundation
import Observation
import SwiftUI

@Observable
class SettingsGeneralViewModel {
    private let saveSettingsUseCase: PSaveSettingsUseCase
    private let loadSettingsUseCase: PLoadSettingsUseCase
    
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
    
    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.saveSettingsUseCase = factory.makeSaveSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }
    
    @MainActor
    func loadGeneralSettings() async {
        do {
            if let settings = try await loadSettingsUseCase.execute() {
                selectedTheme = .system // settings.theme ?? .system
                autoSyncEnabled = false // settings.autoSyncEnabled
                // syncInterval = settings.syncInterval
                // enableReaderMode = settings.enableReaderMode
                // openExternalLinksInApp = settings.openExternalLinksInApp
                // autoMarkAsRead = settings.autoMarkAsRead
                appVersion = "1.0.0"
                developerName = "Ilyas Hallak"
            }
        } catch {
            errorMessage = "Fehler beim Laden der Einstellungen"
        }
    }
    
    @MainActor
    func saveGeneralSettings() async {
        do {
            
            // TODO: add save general settings here
            /*try await saveSettingsUseCase.execute(
                token: "",
                selectedTheme: selectedTheme,
                autoSyncEnabled: autoSyncEnabled,
                syncInterval: syncInterval,
                enableReaderMode: enableReaderMode,
                openExternalLinksInApp: openExternalLinksInApp,
                autoMarkAsRead: autoMarkAsRead
            )*/
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
