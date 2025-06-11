import Foundation

@Observable
class BookmarksViewModel {
    private let getBooksmarksUseCase = DefaultUseCaseFactory.shared.makeGetBookmarksUseCase()
    
    var bookmarks: [Bookmark] = []
    var isLoading = false
    var errorMessage: String?
    var currentState: BookmarkState = .unread

    
    init() {

    }
    
    @MainActor
    func loadBookmarks(state: BookmarkState = .unread) async {
        isLoading = true
        errorMessage = nil
        currentState = state

        do {
            bookmarks = try await getBooksmarksUseCase.execute(state: state)
        } catch {
            errorMessage = "Fehler beim Laden der Bookmarks"
             bookmarks = []
        }
        
        isLoading = false
    }

    @MainActor
    func refreshBookmarks() async {
        await loadBookmarks(state: currentState)
    }
}
