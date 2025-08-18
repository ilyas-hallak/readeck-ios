import Foundation
import SwiftUI
import Combine

@Observable
class OfflineBookmarksViewModel {
    var state: OfflineBookmarkSyncState = .idle
    
    private let syncUseCase: POfflineBookmarkSyncUseCase
    private var cancellables = Set<AnyCancellable>()
    private var successTimer: Timer?
    
    init(syncUseCase: POfflineBookmarkSyncUseCase = OfflineBookmarkSyncUseCase()) {
        self.syncUseCase = syncUseCase
        setupBindings()
        updateState()
    }
    
    private func setupBindings() {
        // Observe sync state changes
        syncUseCase.isSyncing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSyncing in
                self?.handleSyncStateChange(isSyncing: isSyncing)
            }
            .store(in: &cancellables)
        
        // Observe sync status changes
        syncUseCase.syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleSyncStatusChange(status: status)
            }
            .store(in: &cancellables)
        
        // Update count on app lifecycle events
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateState()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateState()
            }
            .store(in: &cancellables)
    }
    
    func updateState() {
        let count = syncUseCase.getOfflineBookmarksCount()
        
        switch state {
        case .idle:
            if count > 0 {
                state = .pending(count: count)
            }
        case .pending:
            if count > 0 {
                state = .pending(count: count)
            } else {
                state = .idle
            }
        case .syncing:
            // Keep syncing state, will be updated by handleSyncStateChange
            break
        case .success:
            // Success state is temporary, handled by timer
            break
        case .error:
            // Update count even in error state
            if count > 0 {
                state = .pending(count: count)
            } else {
                state = .idle
            }
        }
    }
    
    func syncOfflineBookmarks() async {
        guard case .pending(let count) = state else { return }
        
        state = .syncing(count: count, status: nil)
        await syncUseCase.syncOfflineBookmarks()
    }
    
    private func handleSyncStateChange(isSyncing: Bool) {
        if isSyncing {
            // If we're not already in syncing state, transition to it
            if case .pending(let count) = state {
                state = .syncing(count: count, status: nil)
            }
        } else {
            // Sync completed
            Task { @MainActor in
                // Small delay to ensure count is updated
                try await Task.sleep(nanoseconds: 500_000_000)
                
                let currentCount = syncUseCase.getOfflineBookmarksCount()
                
                if case .syncing(let originalCount, _) = state {
                    if currentCount == 0 {
                        // Success - all bookmarks synced
                        state = .success(syncedCount: originalCount)
                        
                        // Auto-hide success message after 2 seconds
                        successTimer?.invalidate()
                        successTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                            self?.state = .idle
                        }
                    } else {
                        // Some bookmarks remain
                        state = .pending(count: currentCount)
                    }
                }
            }
        }
    }
    
    private func handleSyncStatusChange(status: String?) {
        if case .syncing(let count, _) = state {
            state = .syncing(count: count, status: status)
        }
    }
    
    deinit {
        successTimer?.invalidate()
    }
}