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