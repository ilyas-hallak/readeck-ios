import Foundation

final class AnnotationsRepository: PAnnotationsRepository {
    private let api: PAPI

    init(api: PAPI) {
        self.api = api
    }

    func createAnnotation(bookmarkId: String, color: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws -> Annotation {
        try await api.createAnnotation(bookmarkId: bookmarkId, color: color, startOffset: startOffset, endOffset: endOffset, startSelector: startSelector, endSelector: endSelector)
            .toDomain()
    }

    func fetchAnnotations(bookmarkId: String) async throws -> [Annotation] {
        let annotationDtos = try await api.getBookmarkAnnotations(bookmarkId: bookmarkId)
        return annotationDtos.map { dto in
            Annotation(
                id: dto.id,
                text: dto.text,
                created: dto.created,
                startOffset: dto.startOffset,
                endOffset: dto.endOffset,
                startSelector: dto.startSelector,
                endSelector: dto.endSelector
            )
        }
    }

    func deleteAnnotation(bookmarkId: String, annotationId: String) async throws {
        try await api.deleteAnnotation(bookmarkId: bookmarkId, annotationId: annotationId)
    }
}
