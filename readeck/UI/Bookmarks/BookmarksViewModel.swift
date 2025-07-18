import Foundation
import Combine
import SwiftUI

@Observable
class BookmarksViewModel {
    private let getBooksmarksUseCase: PGetBookmarksUseCase
    private let updateBookmarkUseCase: PUpdateBookmarkUseCase
    private let deleteBookmarkUseCase: PDeleteBookmarkUseCase
    
    var bookmarks: BookmarksPage?
    var isLoading = false
    var errorMessage: String?
    var currentState: BookmarkState = .unread
    var currentType = [BookmarkType.article]
    var currentTag: String? = nil
    
    var showingAddBookmarkFromShare = false
    var shareURL = ""
    var shareTitle = ""
    
    
    private var cancellables = Set<AnyCancellable>()
    private var limit = 20
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
        
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default
            .publisher(for: NSNotification.Name("AddBookmarkFromShare"))
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
        
        print("Received share notification - URL: \(url)")
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
        
        offset = 0 // Offset zurücksetzen
        hasMoreData = true // Pagination zurücksetzen
        
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
            hasMoreData = newBookmarks.currentPage != newBookmarks.totalPages // Prüfen, ob weitere Daten verfügbar sind
        } catch {
            errorMessage = "Fehler beim Laden der Bookmarks"
            bookmarks = nil
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMoreBookmarks() async {
        guard !isLoading && hasMoreData else { return } // Verhindern, dass mehrfach geladen wird
        
        isLoading = true
        errorMessage = nil
        
        do {
            offset += limit // Offset erhöhen
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
            errorMessage = "Fehler beim Nachladen der Bookmarks"
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshBookmarks() async {
        await loadBookmarks(state: currentState)
    }
    
    @MainActor
    func toggleArchive(bookmark: Bookmark) async {
        do {
            try await updateBookmarkUseCase.toggleArchive(
                bookmarkId: bookmark.id,
                isArchived: !bookmark.isArchived
            )
            
            // Liste aktualisieren
            await loadBookmarks(state: currentState)
            
        } catch {
            errorMessage = "Fehler beim Archivieren des Bookmarks"
        }
    }
    
    @MainActor
    func toggleFavorite(bookmark: Bookmark) async {
        do {
            try await updateBookmarkUseCase.toggleFavorite(
                bookmarkId: bookmark.id,
                isMarked: !bookmark.isMarked
            )
            
            // Liste aktualisieren
            await loadBookmarks(state: currentState)
            
        } catch {
            errorMessage = "Fehler beim Markieren des Bookmarks"
        }
    }
    
    @MainActor
    func deleteBookmark(bookmark: Bookmark) async {
        do {
            // Echtes Löschen über API statt nur als gelöscht markieren
            try await deleteBookmarkUseCase.execute(bookmarkId: bookmark.id)
            
            // Lokal aus der Liste entfernen (optimistische Update)
            bookmarks?.bookmarks.removeAll { $0.id == bookmark.id }
            
        } catch {
            errorMessage = "Fehler beim Löschen des Bookmarks"
            // Bei Fehler die Liste neu laden, um konsistenten Zustand zu haben
            await loadBookmarks(state: currentState)
        }
    }
}
