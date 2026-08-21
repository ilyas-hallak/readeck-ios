import Foundation
import CoreData
import SwiftUI

protocol POfflineSyncManager {
    func syncOfflineBookmarks() async
    func getOfflineBookmarks() -> [ArticleURLEntity]
    func deleteOfflineBookmark(_ entity: ArticleURLEntity)
}

open class OfflineSyncManager: ObservableObject, @unchecked Sendable {
    static let shared = OfflineSyncManager()

    @Published var isSyncing = false
    @Published var syncStatus: String?

    private let coreDataManager = CoreDataManager.shared
    private let api: PAPI
    private let logger = Logger.sync
    private let retryBackoffBaseSeconds: Double

    init(api: PAPI = API(), retryBackoffBaseSeconds: Double = 2.0) {
        self.api = api
        self.retryBackoffBaseSeconds = retryBackoffBaseSeconds
    }

    // MARK: - Sync Methods

    func syncOfflineBookmarks() async {
        await MainActor.run {
            isSyncing = true
            syncStatus = "Syncing bookmarks with server..."
        }

        let offlineBookmarks = getOfflineBookmarks()

        guard !offlineBookmarks.isEmpty else {
            await MainActor.run {
                isSyncing = false
                syncStatus = "No bookmarks to sync"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = nil
            }
            return
        }

        var successCount = 0
        var failedCount = 0
        var aborted = false
        let maxRetries = 2

        for bookmark in offlineBookmarks {
            // Read entity properties on the context queue (not thread-safe otherwise).
            var snapshot: (url: String, title: String, tags: [String], html: String?)?
            bookmark.managedObjectContext?.performAndWait {
                guard let url = bookmark.url else { return }
                let tags = bookmark.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
                snapshot = (url, bookmark.title ?? "", tags, bookmark.html)
            }

            guard let snapshot else {
                // objectID is thread-safe; the String `id` attribute is not.
                logger.error("Skipping offline bookmark without URL (id: \(bookmark.objectID))")
                failedCount += 1
                continue
            }

            let url = snapshot.url
            let dto = CreateBookmarkRequestDto(
                url: snapshot.url,
                title: snapshot.title,
                labels: snapshot.tags.isEmpty ? nil : snapshot.tags,
                html: snapshot.html
            )

            var lastError: Error?
            for attempt in 0...maxRetries {
                do {
                    if attempt > 0 {
                        let delay = Double(attempt) * retryBackoffBaseSeconds // linear backoff, mirrors OfflineCacheSyncUseCase
                        if delay > 0 {
                            logger.info("⏳ Retry \(attempt)/\(maxRetries) for \(url) after \(delay)s")
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        }
                    }
                    _ = try await api.createBookmark(createRequest: dto)
                    deleteOfflineBookmark(bookmark)
                    successCount += 1
                    lastError = nil
                    await MainActor.run { syncStatus = "Synced \(successCount) bookmarks..." }
                    break
                } catch {
                    lastError = error
                    if !isRetryableError(error) || attempt == maxRetries {
                        break
                    }
                    logger.warning("Temporary error syncing \(url), will retry: \(error.localizedDescription)")
                }
            }

            if let lastError {
                // Keep the entry in the queue (do NOT delete) so it is retried on the next sync.
                logger.error("Failed to sync bookmark after retries, keeping for later retry: \(url) - \(lastError)")
                failedCount += 1

                // Fully offline and nothing synced yet: stop early, queue stays intact.
                if successCount == 0 && isConnectivityError(lastError) {
                    aborted = true
                    break
                }
            }
        }

        await MainActor.run {
            isSyncing = false
            if aborted {
                syncStatus = "Server not reachable. \(failedCount) bookmark(s) kept for later."
            } else if successCount > 0 {
                syncStatus = failedCount == 0
                    ? "✅ Successfully synced \(successCount) bookmarks"
                    : "⚠️ Synced \(successCount), \(failedCount) kept for retry"
            } else if failedCount > 0 {
                syncStatus = "❌ Sync failed - \(failedCount) bookmark(s) kept for retry"
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.syncStatus = nil
        }
    }

    func getOfflineBookmarksCount() -> Int {
        getOfflineBookmarks().count
    }

    open func getOfflineBookmarks() -> [ArticleURLEntity] {
        do {
            let fetchRequest: NSFetchRequest<ArticleURLEntity> = ArticleURLEntity.fetchRequest()
            return try coreDataManager.context.safeFetch(fetchRequest)
        } catch {
            logger.error("Failed to fetch offline bookmarks: \(error)")
            return []
        }
    }

    open func deleteOfflineBookmark(_ entity: ArticleURLEntity) {
        do {
            try coreDataManager.context.safePerform { [weak self] in
                guard let self else { return }

                self.coreDataManager.context.delete(entity)
                self.coreDataManager.save()
            }
        } catch {
            logger.error("Failed to delete offline bookmark: \(error)")
        }
    }

    // MARK: - Retry Helpers

    // Retry only transient server/network errors (400 stays permanent, unlike OfflineCacheSyncUseCase).
    private func isRetryableError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .serverError(let statusCode):
                return statusCode == 502 || statusCode == 503 || statusCode == 504
            case .serverErrorWithMessage(let statusCode, _):
                return statusCode == 502 || statusCode == 503 || statusCode == 504
            case .invalidURL, .invalidResponse:
                return false
            }
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .cannotConnectToHost,
                 .notConnectedToInternet, .cannotFindHost, .dnsLookupFailed:
                return true
            default:
                return false
            }
        }
        return false
    }

    // True only when the server/network is completely unreachable (vs. a single bad item).
    private func isConnectivityError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .notConnectedToInternet, .cannotConnectToHost, .cannotFindHost,
             .networkConnectionLost, .dnsLookupFailed, .dataNotAllowed:
            return true
        default:
            return false
        }
    }
}
