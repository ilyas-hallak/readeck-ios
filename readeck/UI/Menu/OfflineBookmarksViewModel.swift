import Foundation
import SwiftUI
import Combine

@Observable
class OfflineBookmarksViewModel {
    var state: OfflineBookmarkSyncState = .idle
    
    private let syncUseCase: POfflineBookmarkSyncUseCase
    private var cancellables = Set<AnyCancellable>()
    private let successDelaySubject = PassthroughSubject<Int, Never>()
    private var completionTimerActive = false
    
    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.syncUseCase = factory.makeOfflineBookmarkSyncUseCase()
        setupBindings()
        refreshState()
    }
    
    // MARK: - Public Methods
    
    func syncOfflineBookmarks() async {
        guard case .pending(let count) = state else { return }
        
        state = .syncing(count: count, status: nil)
        await syncUseCase.syncOfflineBookmarks()
    }
    
    func refreshState() {
        let currentCount = syncUseCase.getOfflineBookmarksCount()
        updateStateWithCount(currentCount)
    }
    
    // MARK: - Private Setup
    
    private func setupBindings() {
        setupSyncBindings()
        setupAppLifecycleBindings()
    }
    
    private func setupSyncBindings() {
        syncUseCase.isSyncing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSyncing in
                self?.handleSyncingStateChange(isSyncing)
            }
            .store(in: &cancellables)
        
        syncUseCase.syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleSyncStatusUpdate(status)
            }
            .store(in: &cancellables)
        
        // Auto-reset success state after 2 seconds
        successDelaySubject
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.state = .idle
            }
            .store(in: &cancellables)
    }
    
    private func setupAppLifecycleBindings() {
        let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        let activePublisher = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        
        Publishers.Merge(foregroundPublisher, activePublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshState()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - State Management
    
    private func updateStateWithCount(_ count: Int) {
        switch state {
        case .idle:
            if count > 0 {
                state = .pending(count: count)
            }
        case .pending:
            state = count > 0 ? .pending(count: count) : .idle
        case .syncing:
            // Keep syncing state - will be updated by sync handlers
            break
        case .success:
            // Success state is temporary - handled by timer
            break
        case .error:
            state = count > 0 ? .pending(count: count) : .idle
        }
    }
    
    // MARK: - Sync Event Handlers
    
    private func handleSyncingStateChange(_ isSyncing: Bool) {
        if isSyncing {
            transitionToSyncingIfPending()
        } else {
            // Only handle completion if we were actually syncing
            if case .syncing = state {
                handleSyncCompletion()
            }
        }
    }
    
    private func transitionToSyncingIfPending() {
        if case .pending(let count) = state {
            state = .syncing(count: count, status: nil)
        }
    }
    
    private func handleSyncCompletion() {
        guard !completionTimerActive else {
            return
        }
        
        completionTimerActive = true
        
        // wait for 0.5 seconds
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.completionTimerActive = false
                
                guard case .syncing(let originalCount, _) = self.state else { 
                    return 
                }
                
                let remainingCount = self.syncUseCase.getOfflineBookmarksCount()
                
                if remainingCount == 0 {
                    self.state = .success(syncedCount: originalCount)
                    self.successDelaySubject.send(originalCount)
                } else {
                    self.state = .pending(count: remainingCount)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleSyncStatusUpdate(_ status: String?) {
        if case .syncing(let count, _) = state {
            state = .syncing(count: count, status: status)
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
}
