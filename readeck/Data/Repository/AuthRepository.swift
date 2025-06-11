import Foundation

class AuthRepository: PAuthRepository {
    private let api: PAPI
    private let settingsRepository: PSettingsRepository
    
    init(api: PAPI, settingsRepository: PSettingsRepository) {
        self.api = api
        self.settingsRepository = settingsRepository
    }
    
    func login(username: String, password: String) async throws -> User {
        let userDto = try await api.login(username: username, password: password)
        // Token wird automatisch von der API gespeichert
        return User(id: userDto.id, token: userDto.token)
    }
    
    func logout() async throws {
        await api.tokenProvider.clearToken()
    }
    
    func getCurrentSettings() async throws -> Settings? {
        return try await settingsRepository.loadSettings()
    }
    
    func saveSettings(_ settings: Settings) async throws {
        try await settingsRepository.saveSettings(settings)
    }
}

struct User {
    let id: String
    let token: String
}
