import Foundation

class AuthRepository: PAuthRepository {
    private let api: PAPI
    private let settingsRepository: PSettingsRepository
    
    init(api: PAPI, settingsRepository: PSettingsRepository) {
        self.api = api
        self.settingsRepository = settingsRepository
    }
    
    func login(endpoint: String, username: String, password: String) async throws -> User {
        let userDto = try await api.login(endpoint: endpoint, username: username, password: password)
        // Token wird automatisch von der API gespeichert
        return User(id: userDto.id, token: userDto.token)
    }
    
    func logout() async throws {
        await api.tokenProvider.clearToken()
    }
    
    func getCurrentSettings() async throws -> Settings? {
        return try await settingsRepository.loadSettings()
    }
}

struct User {
    let id: String
    let token: String
}
