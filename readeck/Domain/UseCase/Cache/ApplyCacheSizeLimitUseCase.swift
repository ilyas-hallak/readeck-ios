import Foundation

protocol PApplyCacheSizeLimitUseCase {
    func execute() async throws
}

/// Applies the configured max image-cache size to the on-disk image cache and
/// evicts least-recently-used images until the cache is within the limit.
///
/// Used at app launch so the limit is enforced across restarts (Codeberg #44).
final class ApplyCacheSizeLimitUseCase: PApplyCacheSizeLimitUseCase {
    private let settingsRepository: PSettingsRepository

    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute() async throws {
        try await settingsRepository.applyCacheSizeLimit()
    }
}
