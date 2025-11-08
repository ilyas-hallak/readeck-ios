//
//  OfflineSettings.swift
//  readeck
//
//  Created by Claude on 08.11.25.
//

import Foundation

struct OfflineSettings: Codable {
    var enabled: Bool = true
    var maxUnreadArticles: Double = 20 // Double für Slider (Default: 20 Artikel)
    var saveImages: Bool = false
    var lastSyncDate: Date?

    var maxUnreadArticlesInt: Int {
        Int(maxUnreadArticles)
    }

    var shouldSyncOnAppStart: Bool {
        guard enabled else { return false }

        // Sync if never synced before
        guard let lastSync = lastSyncDate else { return true }

        // Sync if more than 4 hours since last sync
        let fourHoursAgo = Date().addingTimeInterval(-4 * 60 * 60)
        return lastSync < fourHoursAgo
    }
}
