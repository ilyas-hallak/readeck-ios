import Foundation

protocol PSaveCardLayoutUseCase {
    func execute(layout: CardLayoutStyle) async
}

class SaveCardLayoutUseCase: PSaveCardLayoutUseCase {
    private let settingsRepository: PSettingsRepository
    private let logger = Logger.data
    
    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    func execute(layout: CardLayoutStyle) async {
        do {
            try await settingsRepository.saveCardLayoutStyle(layout)
        } catch {
            logger.error("Failed to save card layout style: \(error)")
        }
    }
}