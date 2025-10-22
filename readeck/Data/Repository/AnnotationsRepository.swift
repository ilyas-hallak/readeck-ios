import Foundation

class AnnotationsRepository: PAnnotationsRepository {
    private let api: PAPI

    init(api: PAPI) {
        self.api = api
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
}
