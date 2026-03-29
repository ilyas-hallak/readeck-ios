import Foundation

protocol PLoadSettingsUseCase {
    func execute() async throws -> Settings?
}

final class LoadSettingsUseCase: PLoadSettingsUseCase {
    private let authRepository: PAuthRepository

    init(authRepository: PAuthRepository) {
        self.authRepository = authRepository
    }

    func execute() async throws -> Settings? {
        try await authRepository.getCurrentSettings()
    }
}
