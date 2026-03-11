import Foundation

protocol PGetMaxCacheSizeUseCase {
    func execute() async throws -> UInt
}

class GetMaxCacheSizeUseCase: PGetMaxCacheSizeUseCase {
    private let settingsRepository: PSettingsRepository

    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute() async throws -> UInt {
        return try await settingsRepository.getMaxCacheSize()
    }
}
