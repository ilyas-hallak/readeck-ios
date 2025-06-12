import SwiftUI

struct BookmarksView: View {
    @State private var viewModel = BookmarksViewModel()
    @State private var showingAddBookmark = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolling = false
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
            .sheet(isPresented: $showingAddBookmark) {
                AddBookmarkView()
            }
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
            .onChange(of: showingAddBookmark) { oldValue, newValue in
                // Refresh bookmarks when sheet is dismissed
                if oldValue && !newValue {
                    Task {
                        await viewModel.refreshBookmarks()
                    }
                }
            }
        }
        .overlay {
            // Animated FAB Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingAddBookmark = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                            .scaleEffect(isScrolling ? 0.8 : 1.0)
                            .opacity(isScrolling ? 0.7 : 1.0)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// Helper für Scroll-Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
