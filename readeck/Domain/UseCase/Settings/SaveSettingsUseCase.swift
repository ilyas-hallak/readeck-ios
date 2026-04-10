import Foundation

protocol PSaveSettingsUseCase {
    func execute(selectedFontFamily: FontFamily, selectedFontSize: FontSize) async throws
    func execute(selectedFontFamily: FontFamily, fontSizeNumeric: Double) async throws
    func execute(readerLayout horizontalMargin: Double, lineHeight: Double) async throws
    func execute(readerVisibility hideProgressBar: Bool, hideWordCount: Bool, hideHeroImage: Bool, hideSummary: Bool) async throws
    func execute(customCSS: String) async throws
    func execute(readerColorTheme: ReaderColorTheme, customBackgroundColor: String?, customTextColor: String?) async throws
    func execute(enableTTS: Bool) async throws
    func execute(theme: Theme) async throws
    func execute(urlOpener: UrlOpener) async throws
    func execute(bookmarkSortField: BookmarkSortField, bookmarkSortDirection: BookmarkSortDirection) async throws
    func execute(disableReaderBackSwipe: Bool) async throws
    func execute(swipeActionConfig: SwipeActionConfig) async throws
}

final class SaveSettingsUseCase: PSaveSettingsUseCase {
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

    func execute(readerVisibility hideProgressBar: Bool, hideWordCount: Bool, hideHeroImage: Bool, hideSummary: Bool) async throws {
        try await settingsRepository.saveSettings(
            .init(
                hideProgressBar: hideProgressBar,
                hideWordCount: hideWordCount,
                hideHeroImage: hideHeroImage,
                hideSummary: hideSummary
            )
        )
    }

    func execute(customCSS: String) async throws {
        try await settingsRepository.saveSettings(
            .init(customCSS: customCSS)
        )
    }

    func execute(readerColorTheme: ReaderColorTheme, customBackgroundColor: String?, customTextColor: String?) async throws {
        try await settingsRepository.saveSettings(
            .init(
                readerColorTheme: readerColorTheme,
                customBackgroundColor: customBackgroundColor,
                customTextColor: customTextColor
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

    func execute(urlOpener: UrlOpener) async throws {
        try await settingsRepository.saveSettings(
            .init(urlOpener: urlOpener)
        )
    }

    func execute(bookmarkSortField: BookmarkSortField, bookmarkSortDirection: BookmarkSortDirection) async throws {
        try await settingsRepository.saveSettings(
            .init(
                bookmarkSortField: bookmarkSortField,
                bookmarkSortDirection: bookmarkSortDirection
            )
        )
    }

    func execute(disableReaderBackSwipe: Bool) async throws {
        try await settingsRepository.saveSettings(
            .init(disableReaderBackSwipe: disableReaderBackSwipe)
        )
    }

    func execute(swipeActionConfig: SwipeActionConfig) async throws {
        try await settingsRepository.saveSettings(
            .init(swipeActionConfig: swipeActionConfig)
        )
    }
}
