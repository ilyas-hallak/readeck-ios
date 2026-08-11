//
//  DeepLinkReader.swift
//  readeck
//
//  Handles `readeck://bookmark/{id}` deep links (e.g. the Share Extension's
//  "Open in Readeck" button) by presenting the article reader modally on top of
//  whatever is on screen. Presenting rather than driving the per-tab navigation
//  keeps the behaviour identical on iPhone and iPad and avoids reaching into each
//  tab's private navigation state.
//

import SwiftUI
import Observation

@Observable
final class DeepLinkRouter {
    /// The bookmark to present, if any. Setting this opens the reader; the sheet
    /// clears it again on dismiss.
    var openedBookmark: DeepLinkedBookmark?

    /// Parses a `readeck://bookmark/{id}` URL and, on success, requests the reader.
    /// Ignores anything else (e.g. OAuth callbacks go through ASWebAuthenticationSession).
    @discardableResult
    func handle(url: URL) -> Bool {
        guard url.scheme?.lowercased() == "readeck", url.host?.lowercased() == "bookmark" else {
            return false
        }
        let id = url.pathComponents.first { $0 != "/" && !$0.isEmpty }
        guard let bookmarkId = id, !bookmarkId.isEmpty else { return false }
        openedBookmark = DeepLinkedBookmark(id: bookmarkId)
        return true
    }
}

struct DeepLinkedBookmark: Identifiable, Equatable {
    let id: String
}

/// Hosts the article reader inside its own navigation stack so it renders correctly
/// when presented modally, with a leading button to close it.
struct DeepLinkReaderView: View {
    let bookmarkId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ArticleReaderRouter(bookmarkId: bookmarkId)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
