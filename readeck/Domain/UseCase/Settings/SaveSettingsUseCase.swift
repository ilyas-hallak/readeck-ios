import Foundation

protocol PSaveSettingsUseCase {
    func execute(selectedFontFamily: FontFamily, selectedFontSize: FontSize) async throws
    func execute(enableTTS: Bool) async throws
    func execute(theme: Theme) async throws
    func execute(urlOpener: UrlOpener) async throws
    func execute(bookmarkSortField: BookmarkSortField, bookmarkSortDirection: BookmarkSortDirection) async throws
    func execute(swipeActionConfig: SwipeActionConfig) async throws
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

    func execute(swipeActionConfig: SwipeActionConfig) async throws {
        try await settingsRepository.saveSettings(
            .init(swipeActionConfig: swipeActionConfig)
        )
    }
}
