//
//  BookmarkState.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

import Foundation

enum BookmarkState: String, CaseIterable {
    case all = "all"
    case unread = "unread"
    case favorite = "favorite"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .all:
            return NSLocalizedString("All", comment: "")
        case .unread:
            return NSLocalizedString("Unread", comment: "")
        case .favorite:
            return NSLocalizedString("Favorites", comment: "")
        case .archived:
            return NSLocalizedString("Archive", comment: "")
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
