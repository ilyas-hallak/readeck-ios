import Foundation

class SaveSettingsUseCase {
    private let authRepository: PAuthRepository
    
    init(authRepository: PAuthRepository) {
        self.authRepository = authRepository
    }
    
    func execute(endpoint: String, username: String, password: String) async throws {
        let settings = Settings(
            endpoint: endpoint,
            username: username,
            password: password,
            token: nil
        )
        try await authRepository.saveSettings(settings)
    }
}