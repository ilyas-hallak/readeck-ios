import Foundation

protocol PSearchBookmarksUseCase: Sendable {
    func execute(search: String) async throws -> BookmarksPage
}

final class SearchBookmarksUseCase: PSearchBookmarksUseCase {
    private let repository: PBookmarksRepository

    init(repository: PBookmarksRepository) {
        self.repository = repository
    }

    func execute(search: String) async throws -> BookmarksPage {
        try await repository.searchBookmarks(search: search)
    }
}
