import Foundation

struct CreateBookmarkRequest {
    let url: String
    let title: String?
    // swiftlint:disable:next discouraged_optional_collection
    let labels: [String]?

    // swiftlint:disable:next discouraged_optional_collection
    init(url: String, title: String? = nil, labels: [String]? = nil) {
        self.url = url
        self.title = title
        self.labels = labels
    }
}

// Convenience Initializers
extension CreateBookmarkRequest {
    static func fromURL(_ url: String) -> CreateBookmarkRequest {
        CreateBookmarkRequest(url: url)
    }

    static func fromURLWithTitle(_ url: String, title: String) -> CreateBookmarkRequest {
        CreateBookmarkRequest(url: url, title: title)
    }

    static func fromURLWithLabels(_ url: String, labels: [String]) -> CreateBookmarkRequest {
        CreateBookmarkRequest(url: url, labels: labels)
    }
}
