import SwiftUI

/// The share entry of the reader menu. Turns into a submenu when the server
/// can also share the Readeck version of the article.
struct ArticleShareMenu: View {
    let viewModel: BookmarkDetailViewModel
    let isOnline: Bool
    let onShareReadeckLink: () -> Void
    let onSendByEmail: () -> Void

    var body: some View {
        if viewModel.canShareReadeckLink || viewModel.canSendByEmail {
            Menu {
                ShareLink(item: viewModel.shareContent) {
                    Label("Share Original Link".localized, systemImage: "link")
                }

                if viewModel.canShareReadeckLink {
                    Button(action: onShareReadeckLink) {
                        Label("Share Readeck Link".localized, systemImage: "square.and.arrow.up")
                    }
                    .disabled(!isOnline || viewModel.isCreatingShareLink)
                }

                if viewModel.canSendByEmail {
                    Button(action: onSendByEmail) {
                        Label("Send by Email".localized, systemImage: "envelope")
                    }
                    .disabled(!isOnline)
                }
            } label: {
                Label("Share".localized, systemImage: "square.and.arrow.up")
            }
        } else {
            ShareLink(item: viewModel.shareContent) {
                Label("Share".localized, systemImage: "square.and.arrow.up")
            }
        }
    }
}
