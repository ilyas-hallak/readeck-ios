import SwiftUI

struct SearchBookmarksView: View {
    @State private var viewModel = SearchBookmarksViewModel()
    @FocusState private var searchFieldIsFocused: Bool
    @State private var selectedBookmarkId: String?
    @Binding var selectedBookmark: Bookmark?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Suchbegriff eingeben...", text: $viewModel.searchQuery)
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
                ProgressView("Suche...")
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
                        BookmarkCardView(bookmark: bookmark, currentState: .all, onArchive: {_ in }, onDelete: {_ in }, onToggleFavorite: {_ in })
                            .listRowBackground(Color(.systemBackground))
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            } else if !viewModel.isLoading && viewModel.bookmarks != nil {
                ContentUnavailableView("Keine Ergebnisse", systemImage: "magnifyingglass", description: Text("Keine Bookmarks gefunden."))
                    .padding()
            }
            Spacer()
        }
        .navigationTitle("Suche")
    }
}
