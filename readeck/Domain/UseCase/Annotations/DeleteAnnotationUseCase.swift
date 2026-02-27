import Foundation

protocol PDeleteAnnotationUseCase {
    func execute(bookmarkId: String, annotationId: String) async throws
}

class DeleteAnnotationUseCase: PDeleteAnnotationUseCase {
    private let repository: PAnnotationsRepository

    init(repository: PAnnotationsRepository) {
        self.repository = repository
    }

    func execute(bookmarkId: String, annotationId: String) async throws {
        try await repository.deleteAnnotation(bookmarkId: bookmarkId, annotationId: annotationId)
    }
}
