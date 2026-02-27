import Foundation

protocol PGetBookmarkAnnotationsUseCase {
    func execute(bookmarkId: String) async throws -> [Annotation]
}

class GetBookmarkAnnotationsUseCase: PGetBookmarkAnnotationsUseCase {
    private let repository: PAnnotationsRepository

    init(repository: PAnnotationsRepository) {
        self.repository = repository
    }

    func execute(bookmarkId: String) async throws -> [Annotation] {
        return try await repository.fetchAnnotations(bookmarkId: bookmarkId)
    }
}
