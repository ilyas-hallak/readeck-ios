import Foundation

protocol PDeleteBookmarkUseCase {
    func execute(bookmarkId: String) async throws
}

class DeleteBookmarkUseCase: PDeleteBookmarkUseCase {
    private let repository: PBookmarksRepository
    
    init(repository: PBookmarksRepository) {
        self.repository = repository
    }
    
    func execute(bookmarkId: String) async throws {
        try await repository.deleteBookmark(id: bookmarkId)
    }
}