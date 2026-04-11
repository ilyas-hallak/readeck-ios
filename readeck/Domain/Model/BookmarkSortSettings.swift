import Foundation

enum BookmarkSortField: String, CaseIterable {
    case created
    case published
    case domain
    case duration
    case site
    case title

    var displayName: String {
        switch self {
        case .created: return "Created"
        case .published: return "Published"
        case .domain: return "Domain"
        case .duration: return "Duration"
        case .site: return "Site"
        case .title: return "Title"
        }
    }
}

enum BookmarkSortDirection: String, CaseIterable {
    case ascending = "asc"
    case descending = "desc"

    var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
}
