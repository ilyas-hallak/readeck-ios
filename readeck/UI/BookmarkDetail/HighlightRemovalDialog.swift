import SwiftUI

/// Asks whether a tapped highlight should be removed, shared by both readers.
private struct HighlightRemovalDialog: ViewModifier {
    @Binding var annotationId: String?
    let bookmarkId: String
    let viewModel: BookmarkDetailViewModel

    @State private var showingError = false

    func body(content: Content) -> some View {
        content
            // An alert and not a confirmation dialog, which iOS 26 shows as a popover pointing at
            // the top of the reader instead of at the tapped highlight.
            .alert(
                "Remove Highlight".localized,
                isPresented: isPresented,
                presenting: annotationId
            ) { annotationId in
                Button("Cancel".localized, role: .cancel) {}
                Button("Remove".localized, role: .destructive) {
                    remove(annotationId)
                }
            } message: { annotationId in
                if let text = viewModel.annotationText(for: annotationId) {
                    Text(text)
                }
            }
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized, role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { annotationId != nil },
            set: { if !$0 { annotationId = nil } }
        )
    }

    private func remove(_ annotationId: String) {
        Task {
            if await !viewModel.deleteAnnotation(bookmarkId: bookmarkId, annotationId: annotationId) {
                showingError = true
            }
        }
    }
}

extension View {
    func highlightRemovalDialog(
        annotationId: Binding<String?>,
        bookmarkId: String,
        viewModel: BookmarkDetailViewModel
    ) -> some View {
        modifier(HighlightRemovalDialog(annotationId: annotationId, bookmarkId: bookmarkId, viewModel: viewModel))
    }
}
