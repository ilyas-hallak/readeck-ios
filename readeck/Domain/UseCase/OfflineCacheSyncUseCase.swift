//
//  OfflineCacheSyncUseCase.swift
//  readeck
//
//  Created by Claude on 17.11.25.
//

import Foundation
import Combine

// MARK: - Protocol

protocol POfflineCacheSyncUseCase {
    var isSyncing: AnyPublisher<Bool, Never> { get }
    var syncProgress: AnyPublisher<String?, Never> { get }

    func syncOfflineArticles(settings: OfflineSettings) async
    func getCachedArticlesCount() -> Int
    func getCacheSize() -> String
}

// MARK: - Implementation

@MainActor
final class OfflineCacheSyncUseCase: POfflineCacheSyncUseCase {

    // MARK: - Dependencies

    private let offlineCacheRepository: POfflineCacheRepository
    private let bookmarksRepository: PBookmarksRepository
    private let settingsRepository: PSettingsRepository

    // MARK: - Published State

    @Published private var _isSyncing = false
    @Published private var _syncProgress: String?

    var isSyncing: AnyPublisher<Bool, Never> {
        $_isSyncing.eraseToAnyPublisher()
    }

    var syncProgress: AnyPublisher<String?, Never> {
        $_syncProgress.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(
        offlineCacheRepository: POfflineCacheRepository,
        bookmarksRepository: PBookmarksRepository,
        settingsRepository: PSettingsRepository
    ) {
        self.offlineCacheRepository = offlineCacheRepository
        self.bookmarksRepository = bookmarksRepository
        self.settingsRepository = settingsRepository
    }

    // MARK: - Public Methods

    func syncOfflineArticles(settings: OfflineSettings) async {
        guard settings.enabled else {
            Logger.sync.info("Offline sync skipped: disabled in settings")
            return
        }

        _isSyncing = true
        Logger.sync.info("🔄 Starting offline sync (max: \(settings.maxUnreadArticlesInt) articles, images: \(settings.saveImages))")

        do {
            // Fetch unread bookmarks from API
            let page = try await bookmarksRepository.fetchBookmarks(
                state: .unread,
                limit: settings.maxUnreadArticlesInt,
                offset: 0,
                search: nil,
                type: nil,
                tag: nil
            )

            let bookmarks = page.bookmarks
            Logger.sync.info("📚 Fetched \(bookmarks.count) unread bookmarks")

            var successCount = 0
            var skippedCount = 0
            var errorCount = 0

            // Process each bookmark
            for (index, bookmark) in bookmarks.enumerated() {
                let progress = "\(index + 1)/\(bookmarks.count)"

                // Check cache status
                if offlineCacheRepository.hasCachedArticle(id: bookmark.id) {
                    Logger.sync.debug("⏭️ Skipping '\(bookmark.title)' (already cached)")
                    skippedCount += 1
                    _syncProgress = "⏭️ Artikel \(progress) bereits gecacht..."
                    continue
                }

                // Update progress
                let imagesSuffix = settings.saveImages ? " + Bilder" : ""
                _syncProgress = "📥 Artikel \(progress)\(imagesSuffix)..."
                Logger.sync.info("📥 Caching '\(bookmark.title)'")

                do {
                    // Fetch article HTML from API
                    let html = try await bookmarksRepository.fetchBookmarkArticle(id: bookmark.id)

                    // Cache with metadata
                    try await offlineCacheRepository.cacheBookmarkWithMetadata(
                        bookmark: bookmark,
                        html: html,
                        saveImages: settings.saveImages
                    )

                    successCount += 1
                    Logger.sync.info("✅ Cached '\(bookmark.title)'")
                } catch {
                    errorCount += 1
                    Logger.sync.error("❌ Failed to cache '\(bookmark.title)': \(error.localizedDescription)")
                }
            }

            // Cleanup old articles (FIFO)
            try await offlineCacheRepository.cleanupOldestCachedArticles(keepCount: settings.maxUnreadArticlesInt)

            // Update last sync date in settings
            var updatedSettings = settings
            updatedSettings.lastSyncDate = Date()
            try await settingsRepository.saveOfflineSettings(updatedSettings)

            // Final status
            let statusMessage = "✅ Synchronisiert: \(successCount), Übersprungen: \(skippedCount), Fehler: \(errorCount)"
            Logger.sync.info(statusMessage)
            _syncProgress = statusMessage

            // Clear progress message after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            _syncProgress = nil

        } catch {
            Logger.sync.error("❌ Offline sync failed: \(error.localizedDescription)")
            _syncProgress = "❌ Synchronisierung fehlgeschlagen"

            // Clear error message after 5 seconds
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            _syncProgress = nil
        }

        _isSyncing = false
    }

    func getCachedArticlesCount() -> Int {
        offlineCacheRepository.getCachedArticlesCount()
    }

    func getCacheSize() -> String {
        offlineCacheRepository.getCacheSize()
    }
}
