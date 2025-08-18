import Foundation

protocol PSaveSettingsUseCase {
    func execute(selectedFontFamily: FontFamily, selectedFontSize: FontSize) async throws
    func execute(enableTTS: Bool) async throws
    func execute(theme: Theme) async throws
}

class SaveSettingsUseCase: PSaveSettingsUseCase {
    private let settingsRepository: PSettingsRepository
    
    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    func execute(selectedFontFamily: FontFamily, selectedFontSize: FontSize) async throws {
        try await settingsRepository.saveSettings(
            .init(
                fontFamily: selectedFontFamily,
                fontSize: selectedFontSize
            )
        )
    }
    
    func execute(enableTTS: Bool) async throws {
        try await settingsRepository.saveSettings(
            .init(enableTTS: enableTTS)
        )
    }
    
    func execute(theme: Theme) async throws {
        try await settingsRepository.saveSettings(
            .init(theme: theme)
        )
    }
}
