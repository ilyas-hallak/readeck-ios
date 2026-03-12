import Foundation

protocol PUpdateMaxCacheSizeUseCase {
    func execute(sizeInBytes: UInt) async throws
}

class UpdateMaxCacheSizeUseCase: PUpdateMaxCacheSizeUseCase {
    private let settingsRepository: PSettingsRepository

    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute(sizeInBytes: UInt) async throws {
        try await settingsRepository.updateMaxCacheSize(sizeInBytes)
    }
}
