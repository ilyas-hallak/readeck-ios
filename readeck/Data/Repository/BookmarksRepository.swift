import Foundation

protocol PBookmarksRepository {
    func fetchBookmarks(state: BookmarkState?) async throws -> [Bookmark]
    func fetchBookmark(id: String) async throws -> BookmarkDetail
    func fetchBookmarkArticle(id: String) async throws -> String
    func addBookmark(bookmark: Bookmark) async throws
    func removeBookmark(id: String) async throws
}

class BookmarksRepository: PBookmarksRepository {
    private var api: PAPI

    init(api: PAPI) {
        self.api = api
    }
    
    func fetchBookmarks(state: BookmarkState? = nil) async throws -> [Bookmark] {
        let bookmarkDtos = try await api.getBookmarks(state: state)
        return bookmarkDtos.map { $0.toDomain() }
    }
    
    func fetchBookmark(id: String) async throws -> BookmarkDetail {
        let bookmarkDetailDto = try await api.getBookmark(id: id)
        return BookmarkDetail(
            id: bookmarkDetailDto.id,
            title: bookmarkDetailDto.title,
            url: bookmarkDetailDto.url,
            description: bookmarkDetailDto.description,
            siteName: bookmarkDetailDto.siteName,
            authors: bookmarkDetailDto.authors,
            created: bookmarkDetailDto.created,
            updated: bookmarkDetailDto.updated,
            wordCount: bookmarkDetailDto.wordCount,
            readingTime: bookmarkDetailDto.readingTime,
            hasArticle: bookmarkDetailDto.hasArticle,
            isMarked: bookmarkDetailDto.isMarked,
            isArchived: bookmarkDetailDto.isArchived,
            thumbnailUrl: bookmarkDetailDto.resources.thumbnail?.src ?? "",
            imageUrl: bookmarkDetailDto.resources.image?.src ?? ""
        )
    }
    
    func fetchBookmarkArticle(id: String) async throws -> String {
        return try await api.getBookmarkArticle(id: id)
    }
    
    func addBookmark(bookmark: Bookmark) async throws {
        // Implement logic to add a bookmark if needed
    }
    
    func removeBookmark(id: String) async throws {
        // Implement logic to remove a bookmark if needed   
    }
}

struct BookmarkDetail {
    let id: String
    let title: String
    let url: String
    let description: String
    let siteName: String
    let authors: [String]
    let created: String
    let updated: String
    let wordCount: Int
    let readingTime: Int?
    let hasArticle: Bool
    let isMarked: Bool
    let isArchived: Bool
    let thumbnailUrl: String
    let imageUrl: String
}
