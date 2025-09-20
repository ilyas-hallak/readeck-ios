//
//  SidebarTab.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

import Foundation

enum SidebarTab: Hashable, CaseIterable, Identifiable {
    case search, all, unread, favorite, archived, article, videos, pictures, tags, settings
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .all: return NSLocalizedString("All", comment: "")
        case .unread: return NSLocalizedString("Unread", comment: "")
        case .favorite: return NSLocalizedString("Favorites", comment: "")
        case .archived: return NSLocalizedString("Archive", comment: "")
        case .search: return NSLocalizedString("Search", comment: "")
        case .settings: return NSLocalizedString("Settings", comment: "")
        case .article: return NSLocalizedString("Articles", comment: "")
        case .videos: return NSLocalizedString("Videos", comment: "")
        case .pictures: return NSLocalizedString("Pictures", comment: "")
        case .tags: return NSLocalizedString("Tags", comment: "")
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
