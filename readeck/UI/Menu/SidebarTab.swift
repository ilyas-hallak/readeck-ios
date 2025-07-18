//
//  SidebarTab.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

enum SidebarTab: Hashable, CaseIterable, Identifiable {
    case search, all, unread, favorite, archived, article, videos, pictures, tags, settings
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .all: return "All"
        case .unread: return "Unread"
        case .favorite: return "Favorites"
        case .archived: return "Archive"
        case .search: return "Search"
        case .settings: return "Settings"
        case .article: return "Articles"
        case .videos: return "Videos"
        case .pictures: return "Pictures"
        case .tags: return "Tags"
        }
    }
    
    var systemImage: String {
        switch self {
        case .unread: return "house"
        case .favorite: return "heart"
        case .archived: return "archivebox"
        case .search: return "magnifyingglass"
        case .settings: return "gear"
        case .all: return "list.bullet"
        case .article: return "doc.plaintext"
        case .videos: return "film"
        case .pictures: return "photo"
        case .tags: return "tag"
        }
    }
}
