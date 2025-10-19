import Foundation

public struct ServerInfoDto: Codable {
    public let version: String
    public let buildDate: String?
    public let userAgent: String?

    public enum CodingKeys: String, CodingKey {
        case version
        case buildDate = "build_date"
        case userAgent = "user_agent"
    }
}

public struct CreateBookmarkRequestDto: Codable {
    public let labels: [String]?
    public let title: String?
    public let url: String
    
    public init(url: String, title: String? = nil, labels: [String]? = nil) {
        self.url = url
        self.title = title
        self.labels = labels
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
