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

    init(api: PAPI = API()) {
        self.api = api
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

        for bookmark in offlineBookmarks {
            guard let url = bookmark.url else {
                failedCount += 1
                continue
            }

            let tags = bookmark.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
            let title = bookmark.title ?? ""

            do {
                let dto = CreateBookmarkRequestDto(url: url, title: title, labels: tags.isEmpty ? nil : tags)
                _ = try await api.createBookmark(createRequest: dto)

                deleteOfflineBookmark(bookmark)
                successCount += 1

                await MainActor.run {
                    syncStatus = "Synced \(successCount) bookmarks..."
                }

            } catch {
                logger.error("Failed to sync bookmark: \(url) - \(error)")
                failedCount += 1

                // If first sync attempt fails, server is likely unreachable - abort
                if successCount == 0 && failedCount == 1 {
                    await MainActor.run {
                        isSyncing = false
                        syncStatus = "Server not reachable. Cannot sync."
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.syncStatus = nil
                    }
                    return
                }
            }
        }

        await MainActor.run {
            isSyncing = false
            if successCount > 0 {
                if failedCount == 0 {
                    syncStatus = "✅ Successfully synced \(successCount) bookmarks"
                } else {
                    syncStatus = "⚠️ Synced \(successCount), failed \(failedCount) bookmarks"
                }
            } else if failedCount > 0 {
                syncStatus = "❌ Sync failed - check your connection"
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.syncStatus = nil
        }
    }
    
    func getOfflineBookmarksCount() -> Int {
        return getOfflineBookmarks().count
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
                guard let self = self else { return }

                self.coreDataManager.context.delete(entity)
                self.coreDataManager.save()
            }
        } catch {
            logger.error("Failed to delete offline bookmark: \(error)")
        }
    }
    
}
