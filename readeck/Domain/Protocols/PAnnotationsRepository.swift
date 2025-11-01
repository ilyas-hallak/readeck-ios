protocol PAnnotationsRepository {
    func fetchAnnotations(bookmarkId: String) async throws -> [Annotation]
    func deleteAnnotation(bookmarkId: String, annotationId: String) async throws
}
