struct PadSidebarView: View {
    @State private var selectedTab: SidebarTab = .unread
    @State private var selectedBookmark: Bookmark?
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(SidebarTab.allCases.filter { $0 != .settings }, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        Label(tab.label, systemImage: tab.systemImage)
                            .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        
                        if tab == .article {
                            Spacer()
                        }
                        
                        if tab == .pictures {
                            Divider()
                        }
                    }
                    .listRowBackground(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom, alignment: .center) {
                VStack(spacing: 0) {
                    Divider()
                    Button(action: {
                        selectedTab = .settings
                    }) {
                        Label(SidebarTab.settings.label, systemImage: SidebarTab.settings.systemImage)
                            .foregroundColor(selectedTab == .settings ? .accentColor : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .listRowBackground(selectedTab == .settings ? Color.accentColor.opacity(0.15) : Color.clear)
                }
                .padding(.horizontal, 12)
                .background(Color(.systemGroupedBackground))
            }
        } content: {
            switch selectedTab {
            case .all:
                Text("All")
            case .unread:
                BookmarksView(state: .unread, selectedBookmark: $selectedBookmark)
            case .favorite:
                BookmarksView(state: .favorite, selectedBookmark: $selectedBookmark)
            case .archived:
                BookmarksView(state: .archived, selectedBookmark: $selectedBookmark)
            case .settings:
                SettingsView()
            case .article:
                Text("Artikel")
            case .videos:
                Text("Videos")
            case .pictures:
                Text("Pictures")
            case .tags:
                Text("Tags")
            }
        } detail: {
            if let bookmark = selectedBookmark, selectedTab != .settings {
                BookmarkDetailView(bookmarkId: bookmark.id)
            } else {
                Text(selectedTab == .settings ? "" : "Select a bookmark")
                    .foregroundColor(.gray)
            }
        }
    }
}