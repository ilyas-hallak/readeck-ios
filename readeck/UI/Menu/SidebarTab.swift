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
        case .all: return "Alle"
        case .unread: return "Ungelesen"
        case .favorite: return "Favoriten"
        case .archived: return "Archiv"
        case .search: return "Suche"
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
