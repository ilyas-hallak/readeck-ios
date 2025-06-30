import Foundation
import Combine
import SwiftUI

struct BookmarksView: View {
    @State private var viewModel = BookmarksViewModel()
    @State private var showingAddBookmark = false
    @State private var selectedBookmarkId: String?
    let state: BookmarkState
    
    @Binding var selectedBookmark: Bookmark?
    
    @State private var showingAddBookmarkFromShare = false
    @State private var shareURL = ""
    @State private var shareTitle = ""
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.bookmarks.isEmpty {
                    ProgressView("Lade \(state.displayName)...")
                } else {
                    List {
                        ForEach(viewModel.bookmarks, id: \.id) { bookmark in
                            Button(action: {
                                if UIDevice.isPhone {
                                    selectedBookmarkId = bookmark.id
                                } else {
                                    if selectedBookmark?.id == bookmark.id {
                                        // Optional: Deselect, um erneutes Auswählen zu ermöglichen
                                        selectedBookmark = nil
                                        DispatchQueue.main.async {
                                            selectedBookmark = bookmark
                                        }
                                    } else {
                                        selectedBookmark = bookmark
                                    }
                                }
                            }) {
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
                                .onAppear {
                                    if bookmark.id == viewModel.bookmarks.last?.id {
                                        Task {
                                            await viewModel.loadMoreBookmarks()
                                        }
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
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
                
                // FAB Button - nur bei "Ungelesen" anzeigen
                if state == .unread {
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
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle(state.displayName)
            .navigationDestination(item: Binding<String?>(
                get: { selectedBookmarkId },
                set: { selectedBookmarkId = $0 }
            )) { bookmarkId in
                BookmarkDetailView(bookmarkId: bookmarkId)
            }
            .sheet(isPresented: $showingAddBookmark) {
                AddBookmarkView(prefilledURL: shareURL, prefilledTitle: shareTitle)
            }
            .sheet(isPresented: $viewModel.showingAddBookmarkFromShare, content: {
                AddBookmarkView(prefilledURL: shareURL, prefilledTitle: shareTitle)
            })
            /*.alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }*/
            .onAppear {
                Task {
                    await viewModel.loadBookmarks(state: state)
                }
            }
            .onChange(of: showingAddBookmark) { oldValue, newValue in
                // Refresh bookmarks when sheet is dismissed
                if oldValue && !newValue {
                    Task {
                        await viewModel.loadBookmarks(state: state)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, placement: .automatic, prompt: "Search...")        
    }
}

// String Identifiable Extension für navigationDestination
extension String: Identifiable {
    public var id: String { self }
}
