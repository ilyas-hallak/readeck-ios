//
//  BookmarkState.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

enum BookmarkState: String, CaseIterable {
    case all = "all"
    case unread = "unread"
    case favorite = "favorite"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .all:
            return "Alle"
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
        case .all:
            return "list.bullet"
        case .unread:
            return "house"
        case .favorite:
            return "heart"
        case .archived:
            return "archivebox"
        }
    }
}
