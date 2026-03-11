import Foundation

protocol PGetCacheSizeUseCase {
    func execute() async throws -> UInt
}

class GetCacheSizeUseCase: PGetCacheSizeUseCase {
    private let settingsRepository: PSettingsRepository

    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute() async throws -> UInt {
        return try await settingsRepository.getCacheSize()
    }
}
