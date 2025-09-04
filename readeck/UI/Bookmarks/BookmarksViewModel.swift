import Foundation
import Combine
import SwiftUI

@Observable
class BookmarksViewModel {
    private let getBooksmarksUseCase: PGetBookmarksUseCase
    private let updateBookmarkUseCase: PUpdateBookmarkUseCase
    private let deleteBookmarkUseCase: PDeleteBookmarkUseCase
    private let loadCardLayoutUseCase: PLoadCardLayoutUseCase
    
    var bookmarks: BookmarksPage?
    var isLoading = false
    var isInitialLoading = true
    var errorMessage: String?
    var isNetworkError = false
    var currentState: BookmarkState = .unread
    var currentType = [BookmarkType.article]
    var currentTag: String? = nil
    var cardLayoutStyle: CardLayoutStyle = .magazine
    
    var showingAddBookmarkFromShare = false
    var shareURL = ""
    var shareTitle = ""
    
    // Undo delete functionality
    var pendingDeletes: [String: PendingDelete] = [:] // bookmarkId -> PendingDelete
    
    
    private var cancellables = Set<AnyCancellable>()
    private var limit = 50
    private var offset = 0
    private var hasMoreData = true
    private var searchWorkItem: DispatchWorkItem?
    
    var searchQuery: String = "" {
        didSet {
            throttleSearch()
        }
    }
    
    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        getBooksmarksUseCase = factory.makeGetBookmarksUseCase()
        updateBookmarkUseCase = factory.makeUpdateBookmarkUseCase()
        deleteBookmarkUseCase = factory.makeDeleteBookmarkUseCase()
        loadCardLayoutUseCase = factory.makeLoadCardLayoutUseCase()
        
        setupNotificationObserver()
        
        Task {
            await loadCardLayout()
        }
    }
    
    private func setupNotificationObserver() {
        // Listen for card layout changes
        NotificationCenter.default
            .publisher(for: .cardLayoutChanged)
            .sink { notification in
                if let layout = notification.object as? CardLayoutStyle {
                    Task { @MainActor in
                        self.cardLayoutStyle = layout
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for
        NotificationCenter.default
            .publisher(for: .addBookmarkFromShare)
            .sink { [weak self] notification in
                self?.handleShareNotification(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleShareNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let url = userInfo["url"] as? String,
              !url.isEmpty else {
            return
        }
        
        DispatchQueue.main.async {
            self.shareURL = url
            self.shareTitle = userInfo["title"] as? String ?? ""
            self.showingAddBookmarkFromShare = true
        }
    }
    
    private func throttleSearch() {
        searchWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task {
                await self.loadBookmarks(state: self.currentState)
            }
        }
        
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    @MainActor
    func loadBookmarks(state: BookmarkState = .unread, type: [BookmarkType] = [.article], tag: String? = nil) async {
        isLoading = true
        errorMessage = nil
        currentState = state
        currentType = type
        currentTag = tag
        
        offset = 0
        hasMoreData = true
        
        do {
            let newBookmarks = try await getBooksmarksUseCase.execute(
                state: state,
                limit: limit,
                offset: offset,
                search: searchQuery,
                type: type,
                tag: tag
            )
            bookmarks = newBookmarks
            hasMoreData = newBookmarks.currentPage != newBookmarks.totalPages // check if more data is available
            isNetworkError = false
        } catch {
            // Check if it's a network error
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost:
                    isNetworkError = true
                    errorMessage = "No internet connection"
                default:
                    isNetworkError = false
                    errorMessage = "Error loading bookmarks"
                }
            } else {
                isNetworkError = false
                errorMessage = "Error loading bookmarks"
            }
            // Don't clear bookmarks on error - keep existing data visible
        }
        
        isLoading = false
        isInitialLoading = false
    }
    
    @MainActor
    func loadMoreBookmarks() async {
        guard !isLoading && hasMoreData else { return } // prevent multiple loads
        
        isLoading = true
        errorMessage = nil
        
        do {
            offset += limit // inc. offset
            let newBookmarks = try await getBooksmarksUseCase.execute(
                state: currentState,
                limit: limit,
                offset: offset,
                search: nil,
                type: currentType,
                tag: currentTag)
            bookmarks?.bookmarks.append(contentsOf: newBookmarks.bookmarks)
            hasMoreData = newBookmarks.currentPage != newBookmarks.totalPages
        } catch {
            // Check if it's a network error
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost:
                    isNetworkError = true
                    errorMessage = "No internet connection"
                default:
                    isNetworkError = false
                    errorMessage = "Error loading more bookmarks"
                }
            } else {
                isNetworkError = false
                errorMessage = "Error loading more bookmarks"
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshBookmarks() async {
        await loadBookmarks(state: currentState)
    }
    
    @MainActor
    func retryLoading() async {
        errorMessage = nil
        isNetworkError = false
        await loadBookmarks(state: currentState, type: currentType, tag: currentTag)
    }
    
    @MainActor
    func toggleArchive(bookmark: Bookmark) async {
        do {
            try await updateBookmarkUseCase.toggleArchive(
                bookmarkId: bookmark.id,
                isArchived: !bookmark.isArchived
            )
            
            await loadBookmarks(state: currentState)
            
        } catch {
            errorMessage = "Error archiving bookmark"
        }
    }
    
    @MainActor
    func toggleFavorite(bookmark: Bookmark) async {
        do {
            try await updateBookmarkUseCase.toggleFavorite(
                bookmarkId: bookmark.id,
                isMarked: !bookmark.isMarked
            )
            
            await loadBookmarks(state: currentState)
            
        } catch {
            errorMessage = "Error marking bookmark"
        }
    }
    
    @MainActor
    func deleteBookmarkWithUndo(bookmark: Bookmark) {
        // Don't remove from UI immediately - just mark as pending
        let pendingDelete = PendingDelete(bookmark: bookmark)
        pendingDeletes[bookmark.id] = pendingDelete
        
        // Start countdown timer for this specific delete
        startDeleteCountdown(for: bookmark.id)
        
        // Schedule actual delete after 3 seconds
        let deleteTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Check if not cancelled and still pending
            if !Task.isCancelled, pendingDeletes[bookmark.id] != nil {
                await executeDelete(bookmark: bookmark)
                await MainActor.run {
                    // Clean up
                    pendingDeletes[bookmark.id]?.timer?.invalidate()
                    pendingDeletes.removeValue(forKey: bookmark.id)
                }
            }
        }
        
        // Store the task in the pending delete
        pendingDeletes[bookmark.id]?.deleteTask = deleteTask
    }
    
    @MainActor
    func undoDelete(bookmarkId: String) {
        guard let pendingDelete = pendingDeletes[bookmarkId] else { return }
        
        // Cancel the delete task and timer
        pendingDelete.deleteTask?.cancel()
        pendingDelete.timer?.invalidate()
        
        // Remove from pending deletes
        pendingDeletes.removeValue(forKey: bookmarkId)
    }
    
    private func startDeleteCountdown(for bookmarkId: String) {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self = self,
                      let pendingDelete = self.pendingDeletes[bookmarkId] else {
                    timer.invalidate()
                    return
                }
                
                pendingDelete.progress += 1.0 / 30.0 // 3 seconds / 0.1 interval = 30 steps
                
                // Trigger UI update by modifying the dictionary
                self.pendingDeletes[bookmarkId] = pendingDelete
                
                if pendingDelete.progress >= 1.0 {
                    timer.invalidate()
                }
            }
        }
        
        pendingDeletes[bookmarkId]?.timer = timer
    }
    
    private func executeDelete(bookmark: Bookmark) async {
        do {
            try await deleteBookmarkUseCase.execute(bookmarkId: bookmark.id)
            // If delete succeeds, remove bookmark from the list
            await MainActor.run {
                bookmarks?.bookmarks.removeAll { $0.id == bookmark.id }
            }
        } catch {
            // If delete fails, restore the bookmark
            await MainActor.run {
                errorMessage = "Error deleting bookmark"
                if var currentBookmarks = bookmarks?.bookmarks {
                    currentBookmarks.insert(bookmark, at: 0)
                    bookmarks?.bookmarks = currentBookmarks
                }
            }
        }
    }
    
    @MainActor
    private func loadCardLayout() async {
        cardLayoutStyle = await loadCardLayoutUseCase.execute()
    }
}

class PendingDelete: Identifiable {
    let id = UUID()
    let bookmark: Bookmark
    var progress: Double = 0.0
    var timer: Timer?
    var deleteTask: Task<Void, Never>?
    
    init(bookmark: Bookmark) {
        self.bookmark = bookmark
    }
}
