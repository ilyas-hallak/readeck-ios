import Foundation

protocol PGetCacheSizeUseCase {
    func execute() async throws -> UInt
}

final class GetCacheSizeUseCase: PGetCacheSizeUseCase {
    private let settingsRepository: PSettingsRepository

    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute() async throws -> UInt {
        try await settingsRepository.getCacheSize()
    }
}
