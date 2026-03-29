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

    var urlOpener: UrlOpener?
    var swipeActionConfig: SwipeActionConfig?

    var isLoggedIn: Bool {
        token != nil && !token!.isEmpty
    }

    mutating func setToken(_ newToken: String) {
        token = newToken
    }
}
