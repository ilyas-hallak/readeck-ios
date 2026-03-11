import Foundation

protocol PGetBookmarkArticleUseCase {
    func execute(id: String) async throws -> String
}

class GetBookmarkArticleUseCase: PGetBookmarkArticleUseCase {
    private let repository: PBookmarksRepository

    init(repository: PBookmarksRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws -> String {
        return try await repository.fetchBookmarkArticle(id: id)
    }
}
