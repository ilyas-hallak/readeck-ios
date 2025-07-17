import Foundation

protocol PSearchBookmarksUseCase {
    func execute(search: String) async throws -> BookmarksPage
}

class SearchBookmarksUseCase: PSearchBookmarksUseCase {
    private let repository: PBookmarksRepository
    
    init(repository: PBookmarksRepository) {
        self.repository = repository
    }
    
    func execute(search: String) async throws -> BookmarksPage {
        return try await repository.searchBookmarks(search: search)
    }
} 