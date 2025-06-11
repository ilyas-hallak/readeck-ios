import Foundation

@Observable
class BookmarksViewModel {
    private let getBooksmarksUseCase = DefaultUseCaseFactory.shared.makeGetBooksmarksUseCase()
    
    var bookmarks: [Bookmark] = []
    var isLoading = false
    var errorMessage: String?
    
    init() {
        
    }
    
    @MainActor
    func loadBookmarks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            bookmarks = try await getBooksmarksUseCase.execute()
        } catch {
            errorMessage = "Fehler beim Laden der Bookmarks"
        }
        
        isLoading = false
    }
}
