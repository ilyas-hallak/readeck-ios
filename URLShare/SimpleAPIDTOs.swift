import Foundation

public struct ServerInfoDto: Codable {
    public let version: VersionInfo
    // swiftlint:disable:next discouraged_optional_collection
    public let features: [String]?

    public struct VersionInfo: Codable {
        public let canonical: String
        public let release: String?
        public let build: String?
    }

    // HTML bookmark submission requires Readeck >= 0.22
    public var supportsHTMLBookmarks: Bool {
        let parts = version.canonical.split(separator: ".").compactMap { Int($0) }
        guard parts.count >= 2 else { return false }
        return parts[0] > 0 || parts[1] >= 22
    }
}

public struct CreateBookmarkRequestDto: Codable {
    // swiftlint:disable:next discouraged_optional_collection
    public let labels: [String]?
    public let title: String?
    public let url: String
    public let html: String?

    // swiftlint:disable:next discouraged_optional_collection
    public init(url: String, title: String? = nil, labels: [String]? = nil, html: String? = nil) {
        self.url = url
        self.title = title
        self.labels = labels
        self.html = html
    }
}

public struct CreateBookmarkResponseDto: Codable {
    public let message: String
    public let status: Int
}

public struct BookmarkLabelDto: Codable, Identifiable {
    public var id: String { href }
    public let name: String
    public let count: Int
    public let href: String

    public enum CodingKeys: String, CodingKey {
        case name, count, href
    }

    public init(name: String, count: Int, href: String) {
        self.name = name
        self.count = count
        self.href = href
    }
}
