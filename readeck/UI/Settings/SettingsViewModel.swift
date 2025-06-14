import Foundation
import Observation
import SwiftUI

@Observable
class SettingsViewModel {
    private let loginUseCase: LoginUseCase
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let loadSettingsUseCase: LoadSettingsUseCase
    
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
    
    // MARK: - Font Settings
    var selectedFontFamily: FontFamily = .system
    var selectedFontSize: FontSize = .medium

    // MARK: - Computed Font Properties for Preview
    var previewTitleFont: Font {
        switch selectedFontFamily {
        case .system:
            return selectedFontSize.systemFont.weight(.semibold)
        case .serif:
            return Font.custom("Times New Roman", size: selectedFontSize.size).weight(.semibold)
        case .sansSerif:
            return Font.custom("Helvetica Neue", size: selectedFontSize.size).weight(.semibold)
        case .monospace:
            return Font.custom("Menlo", size: selectedFontSize.size).weight(.semibold)
        }
    }
    
    var previewBodyFont: Font {
        switch selectedFontFamily {
        case .system:
            return selectedFontSize.systemFont
        case .serif:
            return Font.custom("Times New Roman", size: selectedFontSize.size)
        case .sansSerif:
            return Font.custom("Helvetica Neue", size: selectedFontSize.size)
        case .monospace:
            return Font.custom("Menlo", size: selectedFontSize.size)
        }
    }

    var previewCaptionFont: Font {
        let captionSize = selectedFontSize.size * 0.85
        switch selectedFontFamily {
        case .system:
            return Font.system(size: captionSize)
        case .serif:
            return Font.custom("Times New Roman", size: captionSize)
        case .sansSerif:
            return Font.custom("Helvetica Neue", size: captionSize)
        case .monospace:
            return Font.custom("Menlo", size: captionSize)
        }
    }
    
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
    func saveFontSettings() async {
        do {
            try await saveSettingsUseCase.execute(
                selectedFontFamily: selectedFontFamily, selectedFontSize: selectedFontSize
            )
        } catch {
            errorMessage = "Fehler beim Speichern der Font-Einstellungen"
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
            let user = try await loginUseCase.execute(username: username, password: password)
                        
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

// MARK: - Font Enums
enum FontFamily: String, CaseIterable {
    case system = "system"
    case serif = "serif"
    case sansSerif = "sansSerif"
    case monospace = "monospace"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .serif: return "Serif"
        case .sansSerif: return "Sans Serif"
        case .monospace: return "Monospace"
        }
    }
}

enum FontSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        }
    }
    
    var size: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        }
    }
    
    var systemFont: Font {
        return Font.system(size: size)
    }
}
