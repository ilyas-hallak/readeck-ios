import Foundation

class LoadSettingsUseCase {
    private let authRepository: PAuthRepository
    
    init(authRepository: PAuthRepository) {
        self.authRepository = authRepository
    }
    
    func execute() async throws -> Settings? {
        return try await authRepository.getCurrentSettings()
    }
}