import Foundation

protocol PGetBookmarkArticleUseCase {
    func execute(id: String) async throws -> String
}

final class GetBookmarkArticleUseCase: PGetBookmarkArticleUseCase {
    private let repository: PBookmarksRepository

    init(repository: PBookmarksRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws -> String {
        try await repository.fetchBookmarkArticle(id: id)
    }
}
