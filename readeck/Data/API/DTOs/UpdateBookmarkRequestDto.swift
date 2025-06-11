import Foundation

struct UpdateBookmarkRequestDto: Codable {
    let addLabels: [String]?
    let isArchived: Bool?
    let isDeleted: Bool?
    let isMarked: Bool?
    let labels: [String]?
    let readAnchor: String?
    let readProgress: Int?
    let removeLabels: [String]?
    let title: String?
    
    enum CodingKeys: String, CodingKey {
        case addLabels = "add_labels"
        case isArchived = "is_archived"
        case isDeleted = "is_deleted"
        case isMarked = "is_marked"
        case labels
        case readAnchor = "read_anchor"
        case readProgress = "read_progress"
        case removeLabels = "remove_labels"
        case title
    }
}