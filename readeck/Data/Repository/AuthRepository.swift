import Foundation

final class AuthRepository: PAuthRepository {
    private let api: PAPI
    private let settingsRepository: PSettingsRepository
    private let getUserProfileUseCase: PGetUserProfileUseCase

    init(api: PAPI, settingsRepository: PSettingsRepository, getUserProfileUseCase: PGetUserProfileUseCase) {
        self.api = api
        self.settingsRepository = settingsRepository
        self.getUserProfileUseCase = getUserProfileUseCase
    }

    func login(endpoint: String, username: String, password: String) async throws -> User {
        let userDto = try await api.login(endpoint: endpoint, username: username, password: password)
        // Token wird automatisch von der API gespeichert
        await api.tokenProvider.setAuthMethod(.apiToken)
        return User(id: userDto.id, token: userDto.token)
    }

    func logout() async throws {
        await api.tokenProvider.clearToken()
        await api.tokenProvider.setAuthMethod(.apiToken)
    }

    func getCurrentSettings() async throws -> Settings? {
        try await settingsRepository.loadSettings()
    }

    func loginWithOAuth(endpoint: String, token: OAuthToken, clientId: String) async throws {
        // Save OAuth token, auth method, client ID, and endpoint
        await api.tokenProvider.setOAuthToken(token)
        await api.tokenProvider.setAuthMethod(.oauth)
        await api.tokenProvider.setOAuthClientId(clientId)
        await api.tokenProvider.setEndpoint(endpoint)

        // Fetch username from user profile
        let username = try await getUserProfileUseCase.execute()

        // Save endpoint and username to settings (token is stored in keychain via tokenProvider)
        if var settings = try await settingsRepository.loadSettings() {
            settings.endpoint = endpoint
            settings.username = username
            // Note: isLoggedIn is a computed property based on token presence
            // The OAuth token is already saved via tokenProvider above
            try await settingsRepository.saveSettings(settings)
        }
    }

    func getAuthenticationMethod() async -> AuthenticationMethod? {
        await api.tokenProvider.getAuthMethod()
    }

    func switchToClassicAuth(endpoint: String, username: String, password: String) async throws -> User {
        // Clear OAuth token first
        await api.tokenProvider.clearToken()
        await api.tokenProvider.setAuthMethod(.apiToken)

        // Then do regular login
        return try await login(endpoint: endpoint, username: username, password: password)
    }
}

struct User {
    let id: String
    let token: String
}
