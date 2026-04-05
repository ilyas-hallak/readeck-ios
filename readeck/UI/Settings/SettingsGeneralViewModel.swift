import Foundation
import Observation
import SwiftUI

@Observable
final class SettingsGeneralViewModel {
    private let saveSettingsUseCase: PSaveSettingsUseCase
    private let loadSettingsUseCase: PLoadSettingsUseCase

    // MARK: - UI Settings
    var selectedTheme: Theme = .system
    // MARK: - Sync Settings
    var autoSyncEnabled = true
    var syncInterval = 15
    // MARK: - Reading Settings
    var enableReaderMode = false
    var enableTTS = false
    var disableReaderBackSwipe = false
    var autoMarkAsRead = false
    var urlOpener: UrlOpener = .inAppBrowser

    // MARK: - Sort Settings
    var bookmarkSortField: BookmarkSortField = .created
    var bookmarkSortDirection: BookmarkSortDirection = .descending

    // MARK: - Messages

    var errorMessage: String?
    var successMessage: String?

    // MARK: - Data Management (Placeholder)

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.saveSettingsUseCase = factory.makeSaveSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }

    @MainActor
    func loadGeneralSettings() async {
        do {
            if let settings = try await loadSettingsUseCase.execute() {
                enableTTS = settings.enableTTS ?? false
                disableReaderBackSwipe = settings.disableReaderBackSwipe
                selectedTheme = settings.theme ?? .system
                urlOpener = settings.urlOpener ?? .inAppBrowser
                bookmarkSortField = settings.bookmarkSortField ?? .created
                bookmarkSortDirection = settings.bookmarkSortDirection ?? .descending
                autoSyncEnabled = false
            }
        } catch {
            errorMessage = "Error loading settings"
        }
    }

    @MainActor
    func saveGeneralSettings() async {
        do {
            try await saveSettingsUseCase.execute(enableTTS: enableTTS)
            try await saveSettingsUseCase.execute(disableReaderBackSwipe: disableReaderBackSwipe)
            try await saveSettingsUseCase.execute(theme: selectedTheme)
            try await saveSettingsUseCase.execute(urlOpener: urlOpener)

            successMessage = "Settings saved"

            // send notification to apply settings to the app
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        } catch {
            errorMessage = "Error saving settings"
        }
    }

    @MainActor
    func saveBookmarkSortSettings() async {
        do {
            try await saveSettingsUseCase.execute(
                bookmarkSortField: bookmarkSortField,
                bookmarkSortDirection: bookmarkSortDirection
            )
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
            successMessage = "Settings saved"
        } catch {
            errorMessage = "Error saving settings"
        }
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
