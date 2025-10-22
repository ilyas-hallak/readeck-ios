protocol PAnnotationsRepository {
    func fetchAnnotations(bookmarkId: String) async throws -> [Annotation]
}
