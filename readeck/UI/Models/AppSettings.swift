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
import Combine

final class AppSettings: ObservableObject {
    @Published var settings: Settings?
    @Published var isNetworkConnected = true

    var enableTTS: Bool {
        settings?.enableTTS ?? false
    }

    var disableReaderBackSwipe: Bool {
        settings?.disableReaderBackSwipe ?? false
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
