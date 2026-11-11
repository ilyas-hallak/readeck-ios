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
    }

    enum Reader {
        static let menuButton = "reader.menuButton"
        static let shareMenuItem = "reader.menu.share"
        static let archiveMenuItem = "reader.menu.archive"
    }

    enum ShareSheet {
        static func option(_ option: ArticleShareOption) -> String { "shareSheet.option.\(option)" }
    }
}
