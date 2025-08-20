import Combine
import Foundation
import SwiftUI

struct BookmarksView: View {

    @Namespace private var namespace
    
    // MARK: States
    
    @State private var viewModel: BookmarksViewModel
    @State private var showingAddBookmark = false
    @State private var selectedBookmarkId: String?
    @State private var showingAddBookmarkFromShare = false
    @State private var shareURL = ""
    @State private var shareTitle = ""
    @State private var bookmarkToDelete: Bookmark? = nil
    
    let state: BookmarkState
    let type: [BookmarkType]
    @Binding var selectedBookmark: Bookmark?
    @EnvironmentObject var playerUIState: PlayerUIState
    let tag: String?
    
    // MARK: Environments
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // MARK: Initializer
    
    init(viewModel: BookmarksViewModel = .init(), state: BookmarkState, type: [BookmarkType], selectedBookmark: Binding<Bookmark?>, tag: String? = nil) {
        self.state = state
        self.type = type
        self._selectedBookmark = selectedBookmark
        self.tag = tag
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            if shouldShowCenteredState {
                centeredStateView
            } else {
                bookmarksList
            }
            
            // FAB Button - only show for "Unread" and when not in error/loading state
            if (state == .unread || state == .all) && !shouldShowCenteredState {
                fabButton
            }
        }
        .navigationDestination(
            item: Binding<String?>(
                get: { selectedBookmarkId },
                set: { selectedBookmarkId = $0 }
            )
        ) { bookmarkId in
            BookmarkDetailView(bookmarkId: bookmarkId, namespace: namespace)
                .navigationTransition(.zoom(sourceID: bookmarkId, in: namespace))
        }
        .sheet(isPresented: $showingAddBookmark) {
            AddBookmarkView(prefilledURL: shareURL, prefilledTitle: shareTitle)
        }
        .sheet(
            isPresented: $viewModel.showingAddBookmarkFromShare,
            content: {
                AddBookmarkView(prefilledURL: shareURL, prefilledTitle: shareTitle)
            }
        )
        .alert(item: $bookmarkToDelete) { bookmark in
            Alert(
                title: Text("Delete Bookmark"),
                message: Text("Are you sure you want to delete this bookmark? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        await viewModel.deleteBookmark(bookmark: bookmark)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            Task {
                await viewModel.loadBookmarks(state: state, type: type, tag: tag)
            }
        }
        .onChange(of: showingAddBookmark) { oldValue, newValue in
            // Refresh bookmarks when sheet is dismissed
            if oldValue && !newValue {
                Task {
                    // Wait a bit for the server to process the new bookmark
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    
                    await viewModel.refreshBookmarks()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowCenteredState: Bool {
        let isEmpty = viewModel.bookmarks?.bookmarks.isEmpty == true
        return isEmpty && (viewModel.isLoading || viewModel.errorMessage != nil)
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var centeredStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(R.color.bookmark_list_bg))
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(.accentColor)
            
            VStack(spacing: 8) {
                Text("Loading \(state.displayName)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Please wait while we fetch your bookmarks...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Unable to load bookmarks")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                Task {
                    await viewModel.loadBookmarks(state: state, type: type, tag: tag)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private var bookmarksList: some View {
        List {
            ForEach(viewModel.bookmarks?.bookmarks ?? [], id: \.id) { bookmark in
                Button(action: {
                    if UIDevice.isPhone {
                        selectedBookmarkId = bookmark.id
                    } else {
                        if selectedBookmark?.id == bookmark.id {
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
                            bookmarkToDelete = bookmark
                        },
                        onToggleFavorite: { bookmark in
                            Task {
                                await viewModel.toggleFavorite(bookmark: bookmark)
                            }
                        },
                        namespace: namespace
                    )
                    .onAppear {
                        if bookmark.id == viewModel.bookmarks?.bookmarks.last?.id {
                            Task {
                                await viewModel.loadMoreBookmarks()
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color(R.color.bookmark_list_bg))
                .matchedTransitionSource(id: bookmark.id, in: namespace)
            }
            
            // Show loading indicator for pagination
            if viewModel.isLoading && !(viewModel.bookmarks?.bookmarks.isEmpty == true) {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .listRowBackground(Color(R.color.bookmark_list_bg))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .background(Color(R.color.bookmark_list_bg))
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.refreshBookmarks()
        }
        .overlay {
            if viewModel.bookmarks?.bookmarks.isEmpty == true && !viewModel.isLoading && viewModel.errorMessage == nil {
                ContentUnavailableView(
                    "No bookmarks",
                    systemImage: "bookmark",
                    description: Text(
                        "No bookmarks found in \(state.displayName.lowercased())."
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private var fabButton: some View {
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

#Preview {
    BookmarksView(
        viewModel: .init(MockUseCaseFactory()),
        state: .archived,
        type: [.article],
        selectedBookmark: .constant(nil),
        tag: nil)
}
