import Foundation

class GetBookmarkUseCase {
    private let repository: PBookmarksRepository

    init(repository: PBookmarksRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws -> BookmarkDetail {
        return try await repository.fetchBookmark(id: id)
    }
}