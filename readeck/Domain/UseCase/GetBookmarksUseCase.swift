import Foundation

class GetBookmarksUseCase {
    private let repository: PBookmarksRepository
    
    init(repository: PBookmarksRepository) {
        self.repository = repository
    }
    
    func execute(state: BookmarkState? = nil) async throws -> [Bookmark] {
        let allBookmarks = try await repository.fetchBookmarks(state: state)
        
        // Fallback-Filterung auf Client-Seite falls API keine Query-Parameter unterstützt
        if let state = state {
            return allBookmarks.filter { bookmark in
                switch state {
                case .unread:
                    return !bookmark.isArchived && !bookmark.isMarked
                case .favorite:
                    return bookmark.isMarked
                case .archived:
                    return bookmark.isArchived
                }
            }
        }
        
        return allBookmarks
    }
}
