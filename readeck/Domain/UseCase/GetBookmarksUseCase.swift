import Foundation

class GetBookmarksUseCase {
    private let repository: PBookmarksRepository
    
    init(repository: PBookmarksRepository) {
        self.repository = repository
    }
    
    func execute(state: BookmarkState? = nil, limit: Int? = nil, offset: Int? = nil, search: String? = nil, type: [BookmarkType]? = nil, tag: String? = nil) async throws -> BookmarksPage {
        var allBookmarks = try await repository.fetchBookmarks(state: state, limit: limit, offset: offset, search: search, type: type, tag: tag)
        
        if let state = state {
            allBookmarks.bookmarks = allBookmarks.bookmarks.filter { bookmark in
                switch state {
                case .all:
                    return true
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
