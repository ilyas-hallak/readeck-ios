import Foundation

protocol PClearCacheUseCase {
    func execute() async throws
}

final class ClearCacheUseCase: PClearCacheUseCase {
    private let settingsRepository: PSettingsRepository

    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute() async throws {
        try await settingsRepository.clearCache()
    }
}
