struct PhoneTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                BookmarksView(state: .unread, selectedBookmark: .constant(nil))
            }
            .tabItem {
                Label("Ungelesen", systemImage: "house")
            }
            
            BookmarksView(state: .favorite, selectedBookmark: .constant(nil))
                .tabItem {
                    Label("Favoriten", systemImage: "heart")
                }
            
            BookmarksView(state: .archived, selectedBookmark: .constant(nil))
                .tabItem {
                    Label("Archiv", systemImage: "archivebox")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(.accentColor)
    }
}
