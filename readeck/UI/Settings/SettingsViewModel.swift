import Foundation
import Observation
import SwiftUI

@Observable
class SettingsViewModel {
    private let _loginUseCase: LoginUseCase
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let loadSettingsUseCase: LoadSettingsUseCase
    private let logoutUseCase: LogoutUseCase
    private let settingsRepository: SettingsRepository
    
    // MARK: - Server Settings
    var endpoint = ""
    var username = ""
    var password = ""
    var isLoading = false
    var isSaving = false
    var isLoggedIn = false
    
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
    
    init() {
        let factory = DefaultUseCaseFactory.shared
        self._loginUseCase = factory.makeLoginUseCase()
        self.saveSettingsUseCase = factory.makeSaveSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
        self.logoutUseCase = factory.makeLogoutUseCase()
        self.settingsRepository = SettingsRepository()
    }
    
    var isSetupMode: Bool {
        !settingsRepository.hasFinishedSetup
    }
    
    @MainActor
    func loadSettings() async {
        do {
            if let settings = try await loadSettingsUseCase.execute() {
                endpoint = settings.endpoint ?? ""
                username = settings.username ?? ""
                password = settings.password ?? ""
                isLoggedIn = settings.isLoggedIn // Verwendet die neue Hilfsmethode
            }
        } catch {
            errorMessage = "Fehler beim Laden der Einstellungen"
        }
    }
    
    @MainActor
    func saveSettings() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await saveSettingsUseCase.execute(
                endpoint: endpoint,
                username: username,
                password: password
            )
            successMessage = "Einstellungen gespeichert"
            
            // Factory-Konfiguration aktualisieren
            await DefaultUseCaseFactory.shared.refreshConfiguration()
            
        } catch {
            errorMessage = "Fehler beim Speichern der Einstellungen"
        }
        
        isSaving = false
    }
    
    @MainActor
    func login() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let user = try await _loginUseCase.execute(username: username, password: password)
                        
            isLoggedIn = true
            successMessage = "Erfolgreich angemeldet"
            
            // Setup als abgeschlossen markieren
            try await settingsRepository.saveHasFinishedSetup(true)
            
            // Notification senden, dass sich der Setup-Status geändert hat
            NotificationCenter.default.post(name: NSNotification.Name("SetupStatusChanged"), object: nil)
            
            // Factory-Konfiguration aktualisieren (Token wird automatisch gespeichert)
            await DefaultUseCaseFactory.shared.refreshConfiguration()
            
        } catch {
            errorMessage = "Anmeldung fehlgeschlagen"
            isLoggedIn = false
        }
        
        isLoading = false
    }
    
    @MainActor
    func logout() async {
        do {
            try await logoutUseCase.execute()
            isLoggedIn = false
            successMessage = "Abgemeldet"
            
            // Notification senden, dass sich der Setup-Status geändert hat
            NotificationCenter.default.post(name: NSNotification.Name("SetupStatusChanged"), object: nil)
            
        } catch {
            errorMessage = "Fehler beim Abmelden"
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    var canSave: Bool {
        !endpoint.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    var canLogin: Bool {
        !username.isEmpty && !password.isEmpty
    }
    
    // Expose loginUseCase for testing purposes
    var loginUseCase: LoginUseCase {
        return _loginUseCase
    }
}


enum Theme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Hell"
        case .dark: return "Dunkel"
        }
    }
}
