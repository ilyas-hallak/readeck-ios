import Foundation

protocol PGetBookmarksUseCase {
    func execute(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?) async throws -> BookmarksPage
}

class GetBookmarksUseCase: PGetBookmarksUseCase {
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
