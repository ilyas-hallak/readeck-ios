import Foundation

protocol PGetBookmarkUseCase {
    func execute(id: String) async throws -> BookmarkDetail
}

final class GetBookmarkUseCase: PGetBookmarkUseCase {
    private let repository: PBookmarksRepository

    init(repository: PBookmarksRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws -> BookmarkDetail {
        try await repository.fetchBookmark(id: id)
    }
}
