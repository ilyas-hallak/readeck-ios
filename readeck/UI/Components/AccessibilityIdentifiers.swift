import Foundation

/// Stable identifiers for UI automation (Maestro, XCUITest).
/// Values are plain strings on purpose so Maestro flows can reference them directly.
enum AccessibilityID {
    enum Bookmarks {
        static let list = "bookmarks.list"
        static let addButton = "bookmarks.addButton"
        static func tab(_ tab: SidebarTab) -> String { "bookmarks.tab.\(tab)" }
        static func row(_ bookmarkId: String) -> String { "bookmarks.row.\(bookmarkId)" }
    }

    enum SwipeActionButton {
        static func id(_ action: SwipeAction) -> String { "bookmarks.swipe.\(action.rawValue)" }
    }

    enum AddBookmark {
        static let urlField = "addBookmark.urlField"
        static let titleField = "addBookmark.titleField"
        static let saveButton = "addBookmark.saveButton"
        static let closeButton = "addBookmark.closeButton"
        static let keyboardDoneButton = "addBookmark.keyboardDoneButton"
    }

    enum Reader {
        static let menuButton = "reader.menuButton"
        static let shareMenuItem = "reader.menu.share"
        static let archiveMenuItem = "reader.menu.archive"
    }

    enum ShareSheet {
        static func option(_ option: ArticleShareOption) -> String { "shareSheet.option.\(option)" }
    }

    /// Shared between AddBookmarkView and the share extension (CoreDataTagManagementView).
    enum Labels {
        static let searchField = "labels.searchField"
        static let addCustomTagButton = "labels.addCustomTagButton"
        static func chip(_ name: String) -> String { "labels.chip.\(name)" }
    }

    enum More {
        static func row(_ tab: SidebarTab) -> String { "more.row.\(tab)" }
    }

    enum Settings {
        static let enableOfflineReadingToggle = "settings.offlineReading.enableToggle"
        static let syncNowButton = "settings.offlineReading.syncNowButton"
        static let offlineReadingRow = "settings.offlineReading.row"
        static let simulateOfflineToggle = "settings.offlineReading.simulateOfflineToggle"
        static let previewCachedArticlesRow = "settings.offlineReading.previewCachedArticlesRow"
    }

    enum ReleaseNotes {
        static let doneButton = "releaseNotes.doneButton"
    }
}
