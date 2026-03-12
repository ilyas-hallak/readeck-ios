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

    var isLoggedIn: Bool {
        token != nil && !token!.isEmpty
    }

    mutating func setToken(_ newToken: String) {
        token = newToken
    }
}

enum BookmarkSortField: String, CaseIterable {
    case created = "created"
    case published = "published"

    var displayName: String {
        switch self {
        case .created: return "Created"
        case .published: return "Published"
        }
    }
}

enum BookmarkSortDirection: String, CaseIterable {
    case ascending = "asc"
    case descending = "desc"

    var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
}
