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
    
    // sizeClass
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    
    @State var selectedBookmark: Bookmark?
    
    var body: some View {
        if UIDevice.isPhone {
            PhoneView()
        } else {
            PadView()
        }
    }
    
    @ViewBuilder
    private func PhoneView() -> some View {
        TabView(selection: $selectedTab) {
            BookmarksView(state: .unread, selectedBookmark: .constant(nil))
                .tabItem {
                    Label("Ungelesen", systemImage: "house")
                }
                .tag("Ungelesen")
            
            BookmarksView(state: .favorite, selectedBookmark: .constant(nil))
                .tabItem {
                    Label("Favoriten", systemImage: "heart")
                }
                .tag("Favoriten")
            
            BookmarksView(state: .archived, selectedBookmark: .constant(nil))
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
        .accentColor(.accentColor)
    }
    
    @ViewBuilder
    private func PadView() -> some View {
        TabView(selection: $selectedTab) {
            // Ungelesen Tab
            NavigationSplitView {
                BookmarksView(state: .unread, selectedBookmark: $selectedBookmark)
            } detail: {
                if let selectedBookmark = selectedBookmark {
                    BookmarkDetailView(bookmarkId: selectedBookmark.id)
                } else {
                    Text("Select a bookmark")
                        .foregroundColor(.gray)
                }
            }
                .tabItem {
                    Label("Unread", systemImage: "house")
                }
                .tag("Unread")
            
            NavigationSplitViewContainer(state: .favorite, selectedBookmark: $selectedBookmark)
                .tabItem {
                    Label("Favoriten", systemImage: "heart")
                }
                .tag("Favorite")
            
            NavigationSplitViewContainer(state: .archived, selectedBookmark: $selectedBookmark)
                .tabItem {
                    Label("Archive", systemImage: "archivebox")
                }
                .tag("Archive")
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("Settings")
        }
        .accentColor(.accentColor)
    }
}

// Container für NavigationSplitView
struct NavigationSplitViewContainer: View {
    let state: BookmarkState
    @Binding var selectedBookmark: Bookmark?

    var body: some View {
        NavigationSplitView {
            BookmarksView(state: state, selectedBookmark: $selectedBookmark)
        } detail: {
            if let selectedBookmark = selectedBookmark {
                BookmarkDetailView(bookmarkId: selectedBookmark.id)
            } else {
                Text("Select a bookmark")
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    MainTabView()
}
