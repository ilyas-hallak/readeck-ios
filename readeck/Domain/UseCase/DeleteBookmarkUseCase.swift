import Foundation

class DeleteBookmarkUseCase {
    private let repository: PBookmarksRepository
    
    init(repository: PBookmarksRepository) {
        self.repository = repository
    }
    
    func execute(bookmarkId: String) async throws {
        try await repository.deleteBookmark(id: bookmarkId)
    }
}