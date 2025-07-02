import Foundation
import Observation
import SwiftUI

@Observable
class SettingsServerViewModel {
    private let loginUseCase: LoginUseCase
    private let logoutUseCase: LogoutUseCase
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let loadSettingsUseCase: LoadSettingsUseCase
    private let settingsRepository: SettingsRepository
    
    // MARK: - Server Settings
    var endpoint = ""
    var username = ""
    var password = ""
    var isLoading = false
    var isLoggedIn = false
    // MARK: - Messages
    var errorMessage: String?
    var successMessage: String?
    
    init() {
        let factory = DefaultUseCaseFactory.shared
        self.loginUseCase = factory.makeLoginUseCase()
        self.logoutUseCase = factory.makeLogoutUseCase()
        self.saveSettingsUseCase = factory.makeSaveSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
        self.settingsRepository = SettingsRepository()
    }
    
    var isSetupMode: Bool {
        !settingsRepository.hasFinishedSetup
    }
    
    @MainActor
    func loadServerSettings() async {
        do {
            if let settings = try await loadSettingsUseCase.execute() {
                endpoint = settings.endpoint ?? ""
                username = settings.username ?? ""
                password = settings.password ?? ""
                isLoggedIn = settings.isLoggedIn
            }
        } catch {
            errorMessage = "Fehler beim Laden der Einstellungen"
        }
    }
    
    @MainActor
    func saveServerSettings() async {
        do {
            try await saveSettingsUseCase.execute(
                endpoint: endpoint,
                username: username,
                password: password
            )
            successMessage = "Server-Einstellungen gespeichert"
        } catch {
            errorMessage = "Fehler beim Speichern der Server-Einstellungen"
        }
    }
    
    @MainActor
    func testConnection() async -> Bool {
        guard canLogin else {
            errorMessage = "Bitte füllen Sie alle Felder aus."
            return false
        }
                
        clearMessages()
        
        do {
            // Test login without saving settings
            let _ = try await loginUseCase.execute(
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            
            
            successMessage = "Verbindung erfolgreich getestet! ✓"
            
            return true
            
        } catch {
            errorMessage = "Verbindungstest fehlgeschlagen: \(error.localizedDescription)"
        }
        
        return false
    }
    
    @MainActor
    func login() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let _ = try await loginUseCase.execute(username: username, password: password)
            isLoggedIn = true
            successMessage = "Erfolgreich angemeldet"
            try await settingsRepository.saveHasFinishedSetup(true)
            NotificationCenter.default.post(name: NSNotification.Name("SetupStatusChanged"), object: nil)
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
} 
