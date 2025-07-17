import Foundation
import Observation
import SwiftUI

@Observable
class SettingsServerViewModel {
    
    // MARK: - Use Cases
    
    private let loginUseCase: PLoginUseCase
    private let logoutUseCase: PLogoutUseCase
    private let saveServerSettingsUseCase: PSaveServerSettingsUseCase
    private let loadSettingsUseCase: PLoadSettingsUseCase
    
    // MARK: - Server Settings
    var endpoint = ""
    var username = ""
    var password = ""
    var isLoading = false
    var isLoggedIn = false
    
    // MARK: - Messages
    var errorMessage: String?
    var successMessage: String?
    
    private var hasFinishedSetup: Bool {
        SettingsRepository().hasFinishedSetup
    }
    
    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.loginUseCase = factory.makeLoginUseCase()
        self.logoutUseCase = factory.makeLogoutUseCase()
        self.saveServerSettingsUseCase = factory.makeSaveServerSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }
    
    var isSetupMode: Bool {
        !hasFinishedSetup
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
        guard canLogin else {
            errorMessage = "Bitte füllen Sie alle Felder aus."
            return
        }
        clearMessages()
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await loginUseCase.execute(endpoint: endpoint, username: username.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            try await saveServerSettingsUseCase.execute(endpoint: endpoint, username: username, password: password, token: user.token)
            isLoggedIn = true
            successMessage = "Server-Einstellungen gespeichert und erfolgreich angemeldet."
            try await SettingsRepository().saveHasFinishedSetup(true)
            NotificationCenter.default.post(name: NSNotification.Name("SetupStatusChanged"), object: nil)
        } catch {
            errorMessage = "Verbindung oder Anmeldung fehlgeschlagen: \(error.localizedDescription)"
            isLoggedIn = false
        }
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
    
    var canLogin: Bool {
        !username.isEmpty && !password.isEmpty
    }
} 
