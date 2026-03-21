import Foundation

protocol PSaveSettingsUseCase {
    func execute(selectedFontFamily: FontFamily, selectedFontSize: FontSize) async throws
    func execute(selectedFontFamily: FontFamily, fontSizeNumeric: Double) async throws
    func execute(readerLayout horizontalMargin: Double, lineHeight: Double) async throws
    func execute(readerVisibility hideProgressBar: Bool, hideWordCount: Bool, hideHeroImage: Bool) async throws
    func execute(customCSS: String) async throws
    func execute(enableTTS: Bool) async throws
    func execute(theme: Theme) async throws
    func execute(urlOpener: UrlOpener) async throws
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

    func execute(selectedFontFamily: FontFamily, fontSizeNumeric: Double) async throws {
        try await settingsRepository.saveSettings(
            .init(
                fontFamily: selectedFontFamily,
                fontSizeNumeric: fontSizeNumeric
            )
        )
    }

    func execute(readerLayout horizontalMargin: Double, lineHeight: Double) async throws {
        try await settingsRepository.saveSettings(
            .init(
                horizontalMargin: horizontalMargin,
                lineHeight: lineHeight
            )
        )
    }

    func execute(readerVisibility hideProgressBar: Bool, hideWordCount: Bool, hideHeroImage: Bool) async throws {
        try await settingsRepository.saveSettings(
            .init(
                hideProgressBar: hideProgressBar,
                hideWordCount: hideWordCount,
                hideHeroImage: hideHeroImage
            )
        )
    }

    func execute(customCSS: String) async throws {
        try await settingsRepository.saveSettings(
            .init(customCSS: customCSS)
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
    
    func execute(urlOpener: UrlOpener) async throws {
        try await settingsRepository.saveSettings(
            .init(urlOpener: urlOpener)
        )
    }
}
