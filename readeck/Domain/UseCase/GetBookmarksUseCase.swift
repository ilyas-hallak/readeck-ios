
class GetBooksmarksUseCase {
    private let repository: BookmarksRepository

    init(repository: BookmarksRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Bookmark] {
        return try await repository.fetchBookmarks()
    }
}
