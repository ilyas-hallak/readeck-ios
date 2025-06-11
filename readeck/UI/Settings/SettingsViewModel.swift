import Foundation

@Observable
class SettingsViewModel {
    private let loginUseCase: LoginUseCase
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let loadSettingsUseCase: LoadSettingsUseCase
    
    var endpoint = ""
    var username = ""
    var password = ""
    var isLoading = false
    var isSaving = false
    var isLoggedIn = false
    var errorMessage: String?
    var successMessage: String?
    
    init() {
        let factory = DefaultUseCaseFactory.shared
        self.loginUseCase = factory.makeLoginUseCase()
        self.saveSettingsUseCase = factory.makeSaveSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }
    
    @MainActor
    func loadSettings() async {
        do {
            if let settings = try await loadSettingsUseCase.execute() {
                endpoint = settings.endpoint
                username = settings.username
                password = settings.password
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
            _ = try await loginUseCase.execute(username: username, password: password)
            isLoggedIn = true
            successMessage = "Erfolgreich angemeldet"
            
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
            // Hier könntest du eine Logout-UseCase hinzufügen
            // try await logoutUseCase.execute()
            isLoggedIn = false
            successMessage = "Abgemeldet"
        } catch {
            errorMessage = "Fehler beim Abmelden"
        }
    }
    
    var canSave: Bool {
        !endpoint.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    var canLogin: Bool {
        !username.isEmpty && !password.isEmpty
    }
}
