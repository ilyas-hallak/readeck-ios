import Foundation

struct BookmarkUpdateRequest {
    let addLabels: [String]?
    let isArchived: Bool?
    let isDeleted: Bool?
    let isMarked: Bool?
    let labels: [String]?
    let readAnchor: String?
    let readProgress: Int?
    let removeLabels: [String]?
    let title: String?
    
    init(
        addLabels: [String]? = nil,
        isArchived: Bool? = nil,
        isDeleted: Bool? = nil,
        isMarked: Bool? = nil,
        labels: [String]? = nil,
        readAnchor: String? = nil,
        readProgress: Int? = nil,
        removeLabels: [String]? = nil,
        title: String? = nil
    ) {
        self.addLabels = addLabels
        self.isArchived = isArchived
        self.isDeleted = isDeleted
        self.isMarked = isMarked
        self.labels = labels
        self.readAnchor = readAnchor
        self.readProgress = readProgress
        self.removeLabels = removeLabels
        self.title = title
    }
}

// Convenience Initializers für häufige Aktionen
extension BookmarkUpdateRequest {
    static func archive(_ isArchived: Bool) -> BookmarkUpdateRequest {
        return BookmarkUpdateRequest(isArchived: isArchived)
    }
    
    static func favorite(_ isMarked: Bool) -> BookmarkUpdateRequest {
        return BookmarkUpdateRequest(isMarked: isMarked)
    }
    
    static func delete(_ isDeleted: Bool) -> BookmarkUpdateRequest {
        return BookmarkUpdateRequest(isDeleted: isDeleted)
    }
    
    static func updateProgress(_ progress: Int, anchor: String? = nil) -> BookmarkUpdateRequest {
        return BookmarkUpdateRequest(readAnchor: anchor, readProgress: progress)
    }
    
    static func updateTitle(_ title: String) -> BookmarkUpdateRequest {
        return BookmarkUpdateRequest(title: title)
    }
    
    static func updateLabels(_ labels: [String]) -> BookmarkUpdateRequest {
        return BookmarkUpdateRequest(labels: labels)
    }
}