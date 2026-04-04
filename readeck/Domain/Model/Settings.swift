//
//  Settings.swift
//  readeck
//
//  Created by Ilyas Hallak on 06.11.25.
//


struct Settings {
    var endpoint: String?
    var username: String?
    var password: String?
    var token: String?

    var fontFamily: FontFamily?
    var fontSize: FontSize?
    var hasFinishedSetup = false
    // swiftlint:disable:next discouraged_optional_boolean
    var enableTTS: Bool?
    var theme: Theme?
    var cardLayoutStyle: CardLayoutStyle?
    var tagSortOrder: TagSortOrder?
    var bookmarkSortField: BookmarkSortField?
    var bookmarkSortDirection: BookmarkSortDirection?

    // swiftlint:disable:next discouraged_optional_boolean
    var disableReaderBackSwipe: Bool?
    var urlOpener: UrlOpener?
    var swipeActionConfig: SwipeActionConfig?

    // Reader styling
    var fontSizeNumeric: Double?
    var horizontalMargin: Double?
    var lineHeight: Double?
    var hideProgressBar: Bool?
    var hideWordCount: Bool?
    var hideHeroImage: Bool?
    var customCSS: String?
    var readerColorTheme: ReaderColorTheme?
    var customBackgroundColor: String?  // hex string
    var customTextColor: String?        // hex string

    var webViewIdentifier: String {
        let parts: [String] = [
            fontFamily?.rawValue ?? "system",
            "\(fontSizeNumeric ?? 20)",
            "\(horizontalMargin ?? 16)",
            "\(lineHeight ?? 1.4)",
            "\(customCSS?.hashValue ?? 0)",
            readerColorTheme?.rawValue ?? "system",
            customBackgroundColor ?? "",
            customTextColor ?? ""
        ]
        return parts.joined(separator: "-")
    }

    var isLoggedIn: Bool {
        token != nil && !token!.isEmpty
    }

    mutating func setToken(_ newToken: String) {
        token = newToken
    }
}
