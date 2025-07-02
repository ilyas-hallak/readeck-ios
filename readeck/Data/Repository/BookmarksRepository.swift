import Foundation

protocol PBookmarksRepository {
    func fetchBookmarks(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?) async throws -> BookmarksPage
    func fetchBookmark(id: String) async throws -> BookmarkDetail
    func fetchBookmarkArticle(id: String) async throws -> String
    func createBookmark(createRequest: CreateBookmarkRequest) async throws -> String
    func updateBookmark(id: String, updateRequest: BookmarkUpdateRequest) async throws
    func deleteBookmark(id: String) async throws
}

class BookmarksRepository: PBookmarksRepository {
    private var api: PAPI

    init(api: PAPI) {
        self.api = api
    }
    
    func fetchBookmarks(state: BookmarkState? = nil, limit: Int? = nil, offset: Int? = nil, search: String? = nil, type: [BookmarkType]? = nil) async throws -> BookmarksPage {
        let bookmarkDtos = try await api.getBookmarks(state: state, limit: limit, offset: offset, search: search, type: type)
        return bookmarkDtos.toDomain()
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
    
    func createBookmark(createRequest: CreateBookmarkRequest) async throws -> String {
        let dto = CreateBookmarkRequestDto(
            url: createRequest.url,
            title: createRequest.title,
            labels: createRequest.labels
        )
        
        let response = try await api.createBookmark(createRequest: dto)
        
        // Prüfe ob die Erstellung erfolgreich war
        guard response.status == 0 || response.status == 202 else {
            throw CreateBookmarkError.serverError(response.message)
        }
        
        return response.message
    }
    
    func deleteBookmark(id: String) async throws {
        try await api.deleteBookmark(id: id)
    }
    
    func updateBookmark(id: String, updateRequest: BookmarkUpdateRequest) async throws {
        let dto = UpdateBookmarkRequestDto(
            addLabels: updateRequest.addLabels,
            isArchived: updateRequest.isArchived,
            isDeleted: updateRequest.isDeleted,
            isMarked: updateRequest.isMarked,
            labels: updateRequest.labels,
            readAnchor: updateRequest.readAnchor,
            readProgress: updateRequest.readProgress,
            removeLabels: updateRequest.removeLabels,
            title: updateRequest.title
        )
        
        try await api.updateBookmark(id: id, updateRequest: dto)
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
    let wordCount: Int?
    let readingTime: Int?
    let hasArticle: Bool
    let isMarked: Bool
    let isArchived: Bool
    let thumbnailUrl: String
    let imageUrl: String
}

enum CreateBookmarkError: Error, LocalizedError {
    case invalidURL
    case duplicateBookmark
    case networkError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die eingegebene URL ist ungültig"
        case .duplicateBookmark:
            return "Dieser Bookmark existiert bereits"
        case .networkError:
            return "Netzwerkfehler beim Erstellen des Bookmarks"
        case .serverError(let message):
            return message // Verwende die Server-Nachricht direkt
        }
    }
}
