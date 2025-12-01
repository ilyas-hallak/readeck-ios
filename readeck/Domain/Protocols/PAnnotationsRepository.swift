protocol PAnnotationsRepository {
    func fetchAnnotations(bookmarkId: String) async throws -> [Annotation]
    func deleteAnnotation(bookmarkId: String, annotationId: String) async throws
    func createAnnotation(bookmarkId: String, color: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws -> Annotation
}
