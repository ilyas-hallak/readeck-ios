import Foundation

protocol TokenProvider {
    func getToken() async -> String?
    func getEndpoint() async -> String?
    func setToken(_ token: String) async
    func clearToken() async
}

class CoreDataTokenProvider: TokenProvider {
    private let settingsRepository = SettingsRepository()
    private var cachedSettings: Settings?
    private var isLoaded = false
    private let keychainHelper = KeychainHelper.shared
    
    private func loadSettingsIfNeeded() async {
        guard !isLoaded else { return }
        
        do {
            cachedSettings = try await settingsRepository.loadSettings()
            isLoaded = true
        } catch {
            print("Failed to load settings: \(error)")
            cachedSettings = nil
        }
    }
    
    func getToken() async -> String? {
        await loadSettingsIfNeeded()
        return cachedSettings?.token
    }
    
    func getEndpoint() async -> String? {
        await loadSettingsIfNeeded()
        // Basis-URL ohne /api Suffix, da es in der API-Klasse hinzugefügt wird
        return cachedSettings?.endpoint
    }
    
    func setToken(_ token: String) async {
        await loadSettingsIfNeeded()
        
        do {
            try await settingsRepository.saveToken(token)
            saveTokenToKeychain(token: token)
            if cachedSettings != nil {
                cachedSettings!.token = token
            }
        } catch {
            print("Failed to save token: \(error)")
        }
    }
    
    func clearToken() async {
        do {
            try await settingsRepository.clearSettings()
            cachedSettings = nil
            saveTokenToKeychain(token: "")
        } catch {
            print("Failed to clear settings: \(error)")
        }
    }
    
    // MARK: - Keychain Support
    
    func saveTokenToKeychain(token: String) {
        keychainHelper.saveToken(token)
    }
    
    func loadTokenFromKeychain() -> String? {
        keychainHelper.loadToken()
    }
}
