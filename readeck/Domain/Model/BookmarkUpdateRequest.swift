import Foundation

// swiftlint:disable discouraged_optional_collection discouraged_optional_boolean
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


extension BookmarkUpdateRequest {
    static func archive(_ isArchived: Bool) -> BookmarkUpdateRequest {
        BookmarkUpdateRequest(isArchived: isArchived)
    }

    static func favorite(_ isMarked: Bool) -> BookmarkUpdateRequest {
        BookmarkUpdateRequest(isMarked: isMarked)
    }

    static func delete(_ isDeleted: Bool) -> BookmarkUpdateRequest {
        BookmarkUpdateRequest(isDeleted: isDeleted)
    }

    static func updateProgress(_ progress: Int, anchor: String? = nil) -> BookmarkUpdateRequest {
        BookmarkUpdateRequest(readAnchor: anchor, readProgress: progress)
    }

    static func updateTitle(_ title: String) -> BookmarkUpdateRequest {
        BookmarkUpdateRequest(title: title)
    }

    static func updateLabels(_ labels: [String]) -> BookmarkUpdateRequest {
        BookmarkUpdateRequest(labels: labels)
    }

    static func addLabels(_ labels: [String]) -> BookmarkUpdateRequest {
        BookmarkUpdateRequest(addLabels: labels)
    }

    static func removeLabels(_ labels: [String]) -> BookmarkUpdateRequest {
        BookmarkUpdateRequest(removeLabels: labels)
    }
}
// swiftlint:enable discouraged_optional_collection discouraged_optional_boolean
