import Foundation
import CoreData
import SwiftUI

class OfflineSyncManager: ObservableObject, @unchecked Sendable {
    static let shared = OfflineSyncManager()
    
    @Published var isSyncing = false
    @Published var syncStatus: String?
    
    private let coreDataManager = CoreDataManager.shared
    private let api: PAPI
    
    init(api: PAPI = API()) {
        self.api = api
    }
    
    // MARK: - Sync Methods
    
    func syncOfflineBookmarks() async {
        // First check if server is reachable
        guard await ServerConnectivity.isServerReachable() else {
            await MainActor.run {
                isSyncing = false
                syncStatus = "Server not reachable. Cannot sync."
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.syncStatus = nil
            }
            return
        }
        
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
                // Try to upload via API
                let dto = CreateBookmarkRequestDto(url: url, title: title, labels: tags.isEmpty ? nil : tags)
                _ = try await api.createBookmark(createRequest: dto)
                
                // If successful, delete from offline storage
                deleteOfflineBookmark(bookmark)
                successCount += 1
                
                await MainActor.run {
                    syncStatus = "Synced \(successCount) bookmarks..."
                }
                
            } catch {
                print("Failed to sync bookmark: \(url) - \(error)")
                failedCount += 1
            }
        }
        
        await MainActor.run {
            isSyncing = false
            if failedCount == 0 {
                syncStatus = "✅ Successfully synced \(successCount) bookmarks"
            } else {
                syncStatus = "⚠️ Synced \(successCount), failed \(failedCount) bookmarks"
            }
        }
        
        // Clear status after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.syncStatus = nil
        }
    }
    
    func getOfflineBookmarksCount() -> Int {
        return getOfflineBookmarks().count
    }
    
    private func getOfflineBookmarks() -> [ArticleURLEntity] {
        do {
            let fetchRequest: NSFetchRequest<ArticleURLEntity> = ArticleURLEntity.fetchRequest()
            return try coreDataManager.context.safeFetch(fetchRequest)
        } catch {
            print("Failed to fetch offline bookmarks: \(error)")
            return []
        }
    }
    
    private func deleteOfflineBookmark(_ entity: ArticleURLEntity) {
        do {
            try coreDataManager.context.safePerform { [weak self] in
                guard let self = self else { return }
                
                self.coreDataManager.context.delete(entity)
                self.coreDataManager.save()
            }
        } catch {
            print("Failed to delete offline bookmark: \(error)")
        }
    }
    
    // MARK: - Auto Sync on Server Connectivity Changes
    
    func startAutoSync() {
        // Monitor server connectivity and auto-sync when server becomes reachable
        NotificationCenter.default.addObserver(
            forName: .serverDidBecomeAvailable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.syncOfflineBookmarks()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
