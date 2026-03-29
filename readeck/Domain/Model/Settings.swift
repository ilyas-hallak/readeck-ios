//
//  Settings.swift
//  readeck
//
//  Created by Ilyas Hallak on 06.11.25.
//


struct Settings {
    var endpoint: String? = nil
    var username: String? = nil
    var password: String? = nil
    var token: String? = nil

    var fontFamily: FontFamily? = nil
    var fontSize: FontSize? = nil
    var hasFinishedSetup: Bool = false
    var enableTTS: Bool? = nil
    var theme: Theme? = nil
    var cardLayoutStyle: CardLayoutStyle? = nil
    var tagSortOrder: TagSortOrder? = nil
    var bookmarkSortField: BookmarkSortField? = nil
    var bookmarkSortDirection: BookmarkSortDirection? = nil

    var urlOpener: UrlOpener? = nil

    var swipeActionConfig: SwipeActionConfig? = nil
    // Reader styling
    var fontSizeNumeric: Double? = nil
    var horizontalMargin: Double? = nil
    var lineHeight: Double? = nil
    var hideProgressBar: Bool? = nil
    var hideWordCount: Bool? = nil
    var hideHeroImage: Bool? = nil
    var customCSS: String? = nil
    var readerColorTheme: ReaderColorTheme? = nil
    var customBackgroundColor: String? = nil  // hex string
    var customTextColor: String? = nil        // hex string

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
