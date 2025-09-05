import SwiftUI

struct SearchBookmarksView: View {
    @State private var viewModel = SearchBookmarksViewModel()
    @FocusState private var searchFieldIsFocused: Bool
    @State private var selectedBookmarkId: String?
    @Binding var selectedBookmark: Bookmark?
    @Namespace private var namespace
    @State private var isFirstAppearance = true
    @State private var cardLayoutStyle: CardLayoutStyle = .magazine
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search...", text: $viewModel.searchQuery)
                    .focused($searchFieldIsFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                        searchFieldIsFocused = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding([.horizontal, .top])
            
            if viewModel.isLoading {
                ProgressView("Searching...")
                    .padding()
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if let bookmarks = viewModel.bookmarks?.bookmarks, !bookmarks.isEmpty {
                List(bookmarks) { bookmark in
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
                            currentState: .all, 
                            layout: cardLayoutStyle,
                            onArchive: {_ in }, 
                            onDelete: {_ in }, 
                            onToggleFavorite: {_ in }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets(
                        top: cardLayoutStyle == .compact ? 8 : 12,
                        leading: 16,
                        bottom: cardLayoutStyle == .compact ? 8 : 12,
                        trailing: 16
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(R.color.bookmark_list_bg))
                }
                .listStyle(.plain)
                .background(Color(R.color.bookmark_list_bg))
                .scrollContentBackground(.hidden)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { _ in
                            searchFieldIsFocused = false
                        }
                )
            } else if !viewModel.isLoading && viewModel.bookmarks != nil {
                ContentUnavailableView("No results", systemImage: "magnifyingglass", description: Text("No bookmarks found."))
                    .padding()
            }
            Spacer()
        }
        .background(Color(R.color.bookmark_list_bg))
        .navigationTitle("Search")
        .navigationDestination(
            item: Binding<String?>(
                get: { selectedBookmarkId },
                set: { selectedBookmarkId = $0 }
            )
        ) { bookmarkId in
            BookmarkDetailView(bookmarkId: bookmarkId)
        }
        .onAppear {
            if isFirstAppearance {
                searchFieldIsFocused = true
                isFirstAppearance = false
            }
            loadCardLayoutStyle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cardLayoutChanged)) { notification in
            if let layout = notification.object as? CardLayoutStyle {
                cardLayoutStyle = layout
            }
        }
    }
    
    private func loadCardLayoutStyle() {
        Task {
            let loadCardLayoutUseCase = DefaultUseCaseFactory.shared.makeLoadCardLayoutUseCase()
            let layout = await loadCardLayoutUseCase.execute()
            await MainActor.run {
                cardLayoutStyle = layout
            }
        }
    }
}
