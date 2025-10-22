import Foundation

@Observable
class AnnotationsListViewModel {
    private let getAnnotationsUseCase: PGetBookmarkAnnotationsUseCase

    var annotations: [Annotation] = []
    var isLoading = false
    var errorMessage: String?
    var showErrorAlert = false

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.getAnnotationsUseCase = factory.makeGetBookmarkAnnotationsUseCase()
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
}
