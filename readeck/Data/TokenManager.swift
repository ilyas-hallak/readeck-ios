import Foundation

@Observable
class TokenManager {
    static let shared = TokenManager()
    
    private let settingsRepository = SettingsRepository()
    private var cachedSettings: Settings?
    
    private init() {}
    
    var currentToken: String? {
        cachedSettings?.token
    }
    
    var currentEndpoint: String? {
        cachedSettings?.endpoint
    }
    
    func loadSettings() async {
        do {
            cachedSettings = try await settingsRepository.loadSettings()
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    func updateToken(_ token: String) async {
        do {
            try await settingsRepository.saveToken(token)
            cachedSettings?.token = token
        } catch {
            print("Failed to save token: \(error)")
        }
    }
    
    func clearToken() async {
        do {
            try await settingsRepository.clearSettings()
            cachedSettings = nil
        } catch {
            print("Failed to clear settings: \(error)")
        }
    }
}