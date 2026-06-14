import Foundation

protocol PGetMaxCacheSizeUseCase {
    func execute() async throws -> UInt
}

final class GetMaxCacheSizeUseCase: PGetMaxCacheSizeUseCase {
    private let settingsRepository: PSettingsRepository

    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute() async throws -> UInt {
        try await settingsRepository.getMaxCacheSize()
    }
}
