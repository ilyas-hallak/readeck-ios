import Foundation

protocol PLoadCardLayoutUseCase: Sendable {
    func execute() async -> CardLayoutStyle
}

final class LoadCardLayoutUseCase: PLoadCardLayoutUseCase {
    private let settingsRepository: PSettingsRepository

    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute() async -> CardLayoutStyle {
        do {
            return try await settingsRepository.loadCardLayoutStyle()
        } catch {
            return .magazine
        }
    }
}
