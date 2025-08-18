import Foundation

enum OfflineBookmarkSyncState: Equatable {
    case idle
    case pending(count: Int)
    case syncing(count: Int, status: String?)
    case success(syncedCount: Int)
    case error(String)
    
    var localBookmarkCount: Int {
        switch self {
        case .idle:
            return 0
        case .pending(let count):
            return count
        case .syncing(let count, _):
            return count
        case .success:
            return 0
        case .error:
            return 0
        }
    }
    
    var isSyncing: Bool {
        switch self {
        case .syncing:
            return true
        default:
            return false
        }
    }
    
    var syncStatus: String? {
        switch self {
        case .syncing(_, let status):
            return status
        case .error(let message):
            return message
        default:
            return nil
        }
    }
    
    var showSuccessMessage: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
    
    var syncedBookmarkCount: Int {
        switch self {
        case .success(let count):
            return count
        default:
            return 0
        }
    }
}