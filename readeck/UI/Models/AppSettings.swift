//
//  AppSettings.swift
//  readeck
//
//  Created by Ilyas Hallak on 21.07.25.
//


//
//  AppSettings.swift
//  readeck
//
//  SPDX-License-Identifier: MIT
//

import Foundation

@Observable
final class AppSettings {
    var settings: Settings?
    var isNetworkConnected = true

    var enableTTS: Bool {
        settings?.enableTTS ?? false
    }

    var disableReaderBackSwipe: Bool {
        settings?.disableReaderBackSwipe ?? false
    }

    var archiveAdvanceMode: ArchiveAdvanceMode {
        if let mode = settings?.archiveAdvanceMode {
            return mode
        }
        // Migration fallback for settings loaded before this field existed.
        return settings?.autoAdvanceAfterArchive == false ? .stay : .nextArticle
    }

    var theme: Theme {
        settings?.theme ?? .system
    }

    var urlOpener: UrlOpener {
        settings?.urlOpener ?? .inAppBrowser
    }

    var tagSortOrder: TagSortOrder {
        settings?.tagSortOrder ?? .byCount
    }

    var bookmarkSortField: BookmarkSortField {
        settings?.bookmarkSortField ?? .created
    }

    var bookmarkSortDirection: BookmarkSortDirection {
        settings?.bookmarkSortDirection ?? .descending
    }

    var swipeActionConfig: SwipeActionConfig {
        settings?.swipeActionConfig ?? .default
    }

    init(settings: Settings? = nil) {
        self.settings = settings
    }
}
