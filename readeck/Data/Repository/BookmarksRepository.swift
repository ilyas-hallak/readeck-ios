import Foundation

protocol PBookmarksRepository {
    func fetchBookmarks() async throws -> [Bookmark]
    func addBookmark(bookmark: Bookmark) async throws
    func removeBookmark(id: String) async throws
}

class BookmarksRepository: PBookmarksRepository {
    private var api: PAPI

    init(api: PAPI) {
        self.api = api
    }
    
    func fetchBookmarks() async throws -> [Bookmark] {
        let bookmarkDtos = try await api.getBookmarks()
        api.authToken = UserDefaults.standard.string(forKey: "token")
        return bookmarkDtos.map { dto in
            Bookmark(id: dto.id, title: dto.title, url: dto.url, createdAt: dto.createdAt)
        }
    }
    
    func addBookmark(bookmark: Bookmark) async throws {
        // Implement logic to add a bookmark if needed
    }
    
    func removeBookmark(id: String) async throws {
        // Implement logic to remove a bookmark if needed   
    }
}

struct Bookmark {
    let id: String
    let title: String
    let url: String
    let createdAt: String
}
