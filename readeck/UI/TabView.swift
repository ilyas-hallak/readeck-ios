import SwiftUI
import Foundation

enum BookmarkState: String, CaseIterable {
    case unread = "unread"
    case favorite = "favorite"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .unread:
            return "Ungelesen"
        case .favorite:
            return "Favoriten"
        case .archived:
            return "Archiv"
        }
    }
    
    var systemImage: String {
        switch self {
        case .unread:
            return "house"
        case .favorite:
            return "heart"
        case .archived:
            return "archivebox"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: String = "Ungelesen"

    var body: some View {
        TabView(selection: $selectedTab) {
            BookmarksView(state: .unread)
                .tabItem {
                    Label("Ungelesen", systemImage: "house")
                }
                .tag("Ungelesen")

            BookmarksView(state: .favorite)
                .tabItem {
                    Label("Favoriten", systemImage: "heart")
                }
                .tag("Favoriten")
            
            BookmarksView(state: .archived)
                .tabItem {
                    Label("Archiv", systemImage: "archivebox")
                }
                .tag("Archiv")
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("Settings")            
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
}
