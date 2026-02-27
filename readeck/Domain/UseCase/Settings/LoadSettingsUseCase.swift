import Foundation

protocol PLoadSettingsUseCase {
    func execute() async throws -> Settings?
}

class LoadSettingsUseCase: PLoadSettingsUseCase {
    private let authRepository: PAuthRepository
    
    init(authRepository: PAuthRepository) {
        self.authRepository = authRepository
    }
    
    func execute() async throws -> Settings? {
        return try await authRepository.getCurrentSettings()
    }
}