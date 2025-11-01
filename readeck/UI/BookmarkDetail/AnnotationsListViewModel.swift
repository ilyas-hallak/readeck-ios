import Foundation

@Observable
class AnnotationsListViewModel {
    private let getAnnotationsUseCase: PGetBookmarkAnnotationsUseCase
    private let deleteAnnotationUseCase: PDeleteAnnotationUseCase

    var annotations: [Annotation] = []
    var isLoading = false
    var errorMessage: String?
    var showErrorAlert = false

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.getAnnotationsUseCase = factory.makeGetBookmarkAnnotationsUseCase()
        self.deleteAnnotationUseCase = factory.makeDeleteAnnotationUseCase()
    }

    @MainActor
    func loadAnnotations(for bookmarkId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            annotations = try await getAnnotationsUseCase.execute(bookmarkId: bookmarkId)
        } catch {
            errorMessage = "Failed to load annotations"
            showErrorAlert = true
        }
    }

    @MainActor
    func deleteAnnotation(bookmarkId: String, annotationId: String) async {
        do {
            try await deleteAnnotationUseCase.execute(bookmarkId: bookmarkId, annotationId: annotationId)
            annotations.removeAll { $0.id == annotationId }
        } catch {
            errorMessage = "Failed to delete annotation"
            showErrorAlert = true
        }
    }
}
