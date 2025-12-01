//
//  OfflineCacheSyncUseCase.swift
//  readeck
//
//  Created by Ilyas Hallak on 17.11.25.
//

import Foundation
import Combine

// MARK: - Protocol

/// Use case for syncing articles for offline reading
/// Handles downloading article content and images based on user settings
protocol POfflineCacheSyncUseCase {
    var isSyncing: AnyPublisher<Bool, Never> { get }
    var syncProgress: AnyPublisher<String?, Never> { get }

    func syncOfflineArticles(settings: OfflineSettings) async
    func getCachedArticlesCount() -> Int
    func getCacheSize() -> String
}

// MARK: - Implementation

/// Orchestrates offline article caching with retry logic and progress reporting
/// - Downloads unread bookmarks based on user settings
/// - Prefetches images if enabled
/// - Implements retry logic for temporary server errors (502, 503, 504)
/// - Cleans up old cached articles (FIFO) to respect maxArticles limit
final class OfflineCacheSyncUseCase: POfflineCacheSyncUseCase {

    // MARK: - Dependencies

    private let offlineCacheRepository: POfflineCacheRepository
    private let bookmarksRepository: PBookmarksRepository
    private let settingsRepository: PSettingsRepository

    // MARK: - Published State

    private let _isSyncingSubject = CurrentValueSubject<Bool, Never>(false)
    private let _syncProgressSubject = CurrentValueSubject<String?, Never>(nil)

    var isSyncing: AnyPublisher<Bool, Never> {
        _isSyncingSubject.eraseToAnyPublisher()
    }

    var syncProgress: AnyPublisher<String?, Never> {
        _syncProgressSubject.eraseToAnyPublisher()
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

    /// Syncs offline articles based on provided settings
    /// - Fetches unread bookmarks from API
    /// - Caches article HTML and optionally images
    /// - Implements retry logic for temporary failures
    /// - Updates last sync date in settings
    @MainActor
    func syncOfflineArticles(settings: OfflineSettings) async {
        guard settings.enabled else {
            Logger.sync.info("Offline sync skipped: disabled in settings")
            return
        }

        _isSyncingSubject.send(true)
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
            var retryCount = 0

            // Process each bookmark
            for (index, bookmark) in bookmarks.enumerated() {
                let progress = "\(index + 1)/\(bookmarks.count)"

                // Check cache status
                if offlineCacheRepository.hasCachedArticle(id: bookmark.id) {
                    Logger.sync.debug("⏭️ Skipping '\(bookmark.title)' (already cached)")
                    skippedCount += 1
                    _syncProgressSubject.send("⏭️ Article \(progress) already cached...")
                    continue
                }

                // Update progress
                let imagesSuffix = settings.saveImages ? " + images" : ""
                _syncProgressSubject.send("📥 Article \(progress)\(imagesSuffix)...")
                Logger.sync.info("📥 Caching '\(bookmark.title)'")

                // Retry logic for temporary server errors
                var lastError: Error?
                let maxRetries = 2

                for attempt in 0...maxRetries {
                    do {
                        if attempt > 0 {
                            let delay = Double(attempt) * 2.0 // 2s, 4s backoff
                            Logger.sync.info("⏳ Retry \(attempt)/\(maxRetries) after \(delay)s delay...")
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            retryCount += 1
                        }

                        // Fetch article HTML from API
                        let html = try await bookmarksRepository.fetchBookmarkArticle(id: bookmark.id)

                        // Cache with metadata
                        try await offlineCacheRepository.cacheBookmarkWithMetadata(
                            bookmark: bookmark,
                            html: html,
                            saveImages: settings.saveImages
                        )

                        successCount += 1
                        Logger.sync.info("✅ Cached '\(bookmark.title)'\(attempt > 0 ? " (after \(attempt) retries)" : "")")
                        lastError = nil
                        break // Success - exit retry loop

                    } catch {
                        lastError = error

                        // Check if error is retryable
                        let shouldRetry = isRetryableError(error)

                        if !shouldRetry || attempt == maxRetries {
                            // Log final error
                            logCacheError(error: error, bookmark: bookmark, attempt: attempt)
                            errorCount += 1
                            break // Give up
                        } else {
                            Logger.sync.warning("⚠️ Temporary error, will retry: \(error.localizedDescription)")
                        }
                    }
                }
            }

            // Cleanup old articles (FIFO)
            try await offlineCacheRepository.cleanupOldestCachedArticles(keepCount: settings.maxUnreadArticlesInt)

            // Update last sync date in settings
            var updatedSettings = settings
            updatedSettings.lastSyncDate = Date()
            try await settingsRepository.saveOfflineSettings(updatedSettings)

            // Final status
            let statusMessage = "✅ Synced: \(successCount), Skipped: \(skippedCount), Errors: \(errorCount)\(retryCount > 0 ? ", Retries: \(retryCount)" : "")"
            Logger.sync.info(statusMessage)
            _syncProgressSubject.send(statusMessage)

            // Clear progress message after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            _syncProgressSubject.send(nil)

        } catch {
            Logger.sync.error("❌ Offline sync failed: \(error.localizedDescription)")
            _syncProgressSubject.send("❌ Sync failed")

            // Clear error message after 5 seconds
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            _syncProgressSubject.send(nil)
        }

        _isSyncingSubject.send(false)
    }

    func getCachedArticlesCount() -> Int {
        offlineCacheRepository.getCachedArticlesCount()
    }

    func getCacheSize() -> String {
        offlineCacheRepository.getCacheSize()
    }

    // MARK: - Private Helper Methods

    /// Determines if an error is temporary and should be retried
    /// - Retries on: 502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout
    /// - Retries on: Network timeouts and connection losses
    private func isRetryableError(_ error: Error) -> Bool {
        // Retry on temporary server errors
        if let apiError = error as? APIError {
            switch apiError {
            case .serverError(let statusCode):
                // Retry on: 502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout
                return statusCode == 502 || statusCode == 503 || statusCode == 504
            case .invalidURL, .invalidResponse:
                return false // Don't retry on permanent errors
            }
        }

        // Retry on network timeouts
        if let urlError = error as? URLError {
            return urlError.code == .timedOut || urlError.code == .networkConnectionLost
        }

        return false
    }

    private func logCacheError(error: Error, bookmark: Bookmark, attempt: Int) {
        let retryInfo = attempt > 0 ? " (after \(attempt) failed attempts)" : ""

        if let urlError = error as? URLError {
            Logger.sync.error("❌ Failed to cache '\(bookmark.title)'\(retryInfo) - Network error: \(urlError.code.rawValue) (\(urlError.localizedDescription))")
        } else if let decodingError = error as? DecodingError {
            Logger.sync.error("❌ Failed to cache '\(bookmark.title)'\(retryInfo) - Decoding error: \(decodingError)")
        } else if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL:
                Logger.sync.error("❌ Failed to cache '\(bookmark.title)'\(retryInfo) - APIError: Invalid URL for bookmark ID '\(bookmark.id)'")
            case .invalidResponse:
                Logger.sync.error("❌ Failed to cache '\(bookmark.title)'\(retryInfo) - APIError: Invalid server response (nicht 200 OK)")
            case .serverError(let statusCode):
                Logger.sync.error("❌ Failed to cache '\(bookmark.title)'\(retryInfo) - APIError: Server error HTTP \(statusCode)")
            }
            Logger.sync.error("   Bookmark ID: \(bookmark.id)")
            Logger.sync.error("   URL: \(bookmark.url)")
        } else {
            Logger.sync.error("❌ Failed to cache '\(bookmark.title)'\(retryInfo) - Error: \(error.localizedDescription) (Type: \(type(of: error)))")
        }
    }
}
