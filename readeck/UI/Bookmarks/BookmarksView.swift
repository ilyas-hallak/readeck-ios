import SwiftUI

struct BookmarksView: View {
    @State private var viewModel = BookmarksViewModel()
    let state: BookmarkState
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.bookmarks.isEmpty {
                    ProgressView("Lade \(state.displayName)...")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.bookmarks, id: \.id) { bookmark in
                                NavigationLink(destination: BookmarkDetailView(bookmarkId: bookmark.id)) {
                                    BookmarkCardView(
                                        bookmark: bookmark,
                                        currentState: state,
                                        onArchive: { bookmark in
                                            Task {
                                                await viewModel.toggleArchive(bookmark: bookmark)
                                            }
                                        },
                                        onDelete: { bookmark in
                                            Task {
                                                await viewModel.deleteBookmark(bookmark: bookmark)
                                            }
                                        },
                                        onToggleFavorite: { bookmark in
                                            Task {
                                                await viewModel.toggleFavorite(bookmark: bookmark)
                                            }
                                        }
                                    )
                                    .padding(.bottom, 20)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refreshBookmarks()
                    }
                    .overlay {
                        if viewModel.bookmarks.isEmpty && !viewModel.isLoading {
                            ContentUnavailableView(
                                "Keine Bookmarks",
                                systemImage: "bookmark",
                                description: Text("Es wurden noch keine Bookmarks in \(state.displayName.lowercased()) gefunden.")
                            )
                        }
                    }
                }
            }
            .navigationTitle(state.displayName)
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.loadBookmarks(state: state)
            }
        }
    }
}
