import SwiftUI

struct BookmarksView: View {
    @State private var viewModel = BookmarksViewModel()
    let state: BookmarkState
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else {                    
                    
                    List(viewModel.bookmarks, id: \.id) { bookmark in
                        NavigationLink(destination: BookmarkDetailView(bookmarkId: bookmark.id)) {
                            BookmarkCardView(bookmark: bookmark)
                        }
                    }
                    .refreshable {
                        await viewModel.loadBookmarks()
                    }
                    .overlay {
                        if viewModel.bookmarks.isEmpty && !viewModel.isLoading {
                            ContentUnavailableView(
                                "Keine Bookmarks",
                                systemImage: "bookmark",
                                description: Text("Es wurden noch keine Bookmarks gespeichert.")
                            )
                        }
                    }
                }
            }
            .navigationTitle(state.displayName)
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.loadBookmarks(state: state)
            }
        }
    }
}

// Unterkomponente für die Darstellung eines einzelnen Bookmarks
private struct BookmarkRow: View {
    let bookmark: Bookmark
    
    var body: some View {
        NavigationLink(destination: BookmarkDetailView(bookmarkId: bookmark.id)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.headline)
                
                Text(bookmark.url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(bookmark.created)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}
