import Foundation
import Combine

protocol POfflineBookmarkSyncUseCase {
    var isSyncing: AnyPublisher<Bool, Never> { get }
    var syncStatus: AnyPublisher<String?, Never> { get }
    
    func getOfflineBookmarksCount() -> Int
    func syncOfflineBookmarks() async
}

class OfflineBookmarkSyncUseCase: POfflineBookmarkSyncUseCase {
    private let syncManager = OfflineSyncManager.shared
    
    var isSyncing: AnyPublisher<Bool, Never> {
        syncManager.$isSyncing.eraseToAnyPublisher()
    }
    
    var syncStatus: AnyPublisher<String?, Never> {
        syncManager.$syncStatus.eraseToAnyPublisher()
    }
    
    func getOfflineBookmarksCount() -> Int {
        return syncManager.getOfflineBookmarksCount()
    }
    
    func syncOfflineBookmarks() async {
        await syncManager.syncOfflineBookmarks()
    }
}