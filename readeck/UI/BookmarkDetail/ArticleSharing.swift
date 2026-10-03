import SwiftUI

/// Presents the share sheet of the reader and everything that follows from it:
/// the system share sheet, the email form, and the PDF export.
struct ArticleSharing: ViewModifier {
    @Binding var isPresented: Bool
    let viewModel: BookmarkDetailViewModel
    let isOnline: Bool

    @State private var pendingOption: ArticleShareOption?
    @State private var destination: Destination?
    @State private var showingError = false

    func body(content: Content) -> some View {
        content
            // The follow-up is started in onDismiss, because SwiftUI drops a
            // sheet that is presented while another one is still animating out.
            .sheet(isPresented: $isPresented, onDismiss: runPendingOption) {
                ArticleShareSheet(
                    options: viewModel.shareOptions,
                    isEnabled: { viewModel.isShareOptionEnabled($0, isOnline: isOnline) }
                ) { option in
                    pendingOption = option
                    isPresented = false
                }
            }
            .sheet(item: $destination) { destination in
                switch destination {
                case .activity(let items):
                    ActivityView(activityItems: items)
                case .email:
                    ShareByEmailView(bookmarkId: viewModel.bookmarkDetail.id)
                }
            }
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized, role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    private func runPendingOption() {
        guard let option = pendingOption else { return }
        pendingOption = nil

        switch option {
        case .email:
            destination = .email
        case .originalLink:
            destination = .activity([viewModel.shareContent])
        case .readeckLink:
            Task {
                let succeeded = await viewModel.createShareLink()
                presentShareSheet(for: succeeded ? viewModel.shareLinkURL : nil)
            }
        case .pdf:
            Task {
                let succeeded = await viewModel.exportArticleAsPDF()
                presentShareSheet(for: succeeded ? viewModel.exportedPDFURL : nil)
            }
        }
    }

    private func presentShareSheet(for url: URL?) {
        if let url {
            destination = .activity([url])
        } else {
            showingError = true
        }
    }
}

extension ArticleSharing {
    enum Destination: Identifiable {
        case activity([Any])
        case email

        var id: String {
            switch self {
            case .activity: "activity"
            case .email: "email"
            }
        }
    }
}

extension View {
    func articleSharing(
        isPresented: Binding<Bool>,
        viewModel: BookmarkDetailViewModel,
        isOnline: Bool
    ) -> some View {
        modifier(ArticleSharing(isPresented: isPresented, viewModel: viewModel, isOnline: isOnline))
    }
}
