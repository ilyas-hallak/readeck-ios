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

class AppSettings: ObservableObject {
    @Published var settings: Settings?

    var enableTTS: Bool {
        settings?.enableTTS ?? false
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

    init(settings: Settings? = nil) {
        self.settings = settings
    }
}
