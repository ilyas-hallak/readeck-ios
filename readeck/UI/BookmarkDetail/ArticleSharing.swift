import SwiftUI

/// Presents the share sheet of the reader and everything that follows from it:
/// the system share sheet, the email form, and the PDF export.
struct ArticleSharing: ViewModifier {
    @Binding var isPresented: Bool
    let viewModel: BookmarkDetailViewModel
    let isOnline: Bool

    @Environment(\.openURL) private var openURL
    @State private var pendingOption: ArticleShareOption?
    @State private var destination: Destination?

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
                case .mailDraft(let draft):
                    MailComposeView(draft: draft)
                        .ignoresSafeArea()
                }
            }
            .alert(
                "Error".localized,
                isPresented: Binding(
                    get: { viewModel.shareErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented { viewModel.clearShareError() }
                    }
                )
            ) {
                Button("OK".localized, role: .cancel) {}
            } message: {
                Text(viewModel.shareErrorMessage ?? "")
            }
    }

    private func runPendingOption() {
        guard let option = pendingOption else { return }
        pendingOption = nil

        switch option {
        case .email:
            sendByEmail()
        case .originalLink:
            if let url = viewModel.prepareOriginalLinkShare() {
                destination = .activity([url])
            }
        case .readeckLink:
            Task {
                let succeeded = await viewModel.createShareLink()
                if succeeded, let url = viewModel.shareLinkURL {
                    destination = .activity([url])
                }
            }
        case .pdf:
            Task {
                let succeeded = await viewModel.exportArticleAsPDF()
                if succeeded, let url = viewModel.exportedPDFURL {
                    destination = .activity([url])
                }
            }
        }
    }

    private func sendByEmail() {
        switch viewModel.emailShareMode(isOnline: isOnline) {
        case .server:
            destination = .email
        case .localDraft:
            guard let draft = viewModel.prepareMailDraft() else { return }
            if MailComposeView.canSendMail {
                destination = .mailDraft(draft)
            } else if let url = draft.mailtoURL {
                openURL(url)
            }
        }
    }
}

extension ArticleSharing {
    enum Destination: Identifiable {
        case activity([Any])
        case email
        case mailDraft(MailDraft)

        var id: String {
            switch self {
            case .activity: "activity"
            case .email: "email"
            case .mailDraft: "mailDraft"
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
