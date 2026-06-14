import Foundation

protocol PDeleteBookmarkUseCase {
    func execute(bookmarkId: String) async throws
}

final class DeleteBookmarkUseCase: PDeleteBookmarkUseCase {
    private let repository: PBookmarksRepository

    init(repository: PBookmarksRepository) {
        self.repository = repository
    }

    func execute(bookmarkId: String) async throws {
        try await repository.deleteBookmark(id: bookmarkId)
    }
}
