import Foundation

protocol PLoadCardLayoutUseCase {
    func execute() async -> CardLayoutStyle
}

class LoadCardLayoutUseCase: PLoadCardLayoutUseCase {
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