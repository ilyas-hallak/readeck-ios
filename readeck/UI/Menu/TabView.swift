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
    @State private var selectedTab: SidebarTab = .unread
    @State var selectedBookmark: Bookmark?
    
    // sizeClass
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    
    var body: some View {
        if UIDevice.isPhone {
            PhoneView()
        } else {
            PadSidebarView()
        }
    }
}

// Sidebar Tabs
enum SidebarTab: Hashable, CaseIterable, Identifiable {
    case all, unread, favorite, archived, settings, article, videos, pictures, tags
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .all: return "Alle"
        case .unread: return "Ungelesen"
        case .favorite: return "Favoriten"
        case .archived: return "Archiv"
        case .settings: return "Einstellungen"
        case .article: return "Artikel"
        case .videos: return "Videos"
        case .pictures: return "Bilder"
        case .tags: return "Tags"
        }
    }
    
    var systemImage: String {
        switch self {
        case .unread: return "house"
        case .favorite: return "heart"
        case .archived: return "archivebox"
        case .settings: return "gear"
        case .all: return "list.bullet"
        case .article: return "doc.plaintext"
        case .videos: return "film"
        case .pictures: return "photo"
        case .tags: return "tag"
        }
    }
}

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

// iPhone: TabView bleibt wie gehabt
extension MainTabView {
    @ViewBuilder
    fileprivate func PhoneView() -> some View {
        TabView {
            NavigationStack {
                BookmarksView(state: .unread, selectedBookmark: .constant(nil))
            }
            .tabItem {
                Label("Ungelesen", systemImage: "house")
            }
    
            NavigationView {
                BookmarksView(state: .favorite, selectedBookmark: .constant(nil))
                    .tabItem {
                        Label("Favoriten", systemImage: "heart")
                    }
            }
            
            NavigationView {
                BookmarksView(state: .archived, selectedBookmark: .constant(nil))
                    .tabItem {
                        Label("Archiv", systemImage: "archivebox")
                    }
            }
            
            NavigationView {
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
        .accentColor(.accentColor)
    }
}

#Preview {
    MainTabView()
}
