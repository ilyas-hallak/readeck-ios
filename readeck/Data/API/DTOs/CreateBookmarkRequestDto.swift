import Foundation

struct CreateBookmarkRequestDto: Codable {
    // swiftlint:disable:next discouraged_optional_collection
    let labels: [String]?
    let title: String?
    let url: String
    let html: String?

    // swiftlint:disable:next discouraged_optional_collection
    init(url: String, title: String? = nil, labels: [String]? = nil, html: String? = nil) {
        self.url = url
        self.title = title
        self.labels = labels
        self.html = html
    }
}
