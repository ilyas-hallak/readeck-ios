import Foundation

struct BookmarkDto: Codable {
    let id: String
    let title: String
    let url: String
    let href: String
    let description: String
    let authors: [String]
    let created: String
    let published: String?
    let updated: String
    let siteName: String
    let site: String
    let readingTime: Int?
    let wordCount: Int?
    let hasArticle: Bool
    let isArchived: Bool
    let isDeleted: Bool
    let isMarked: Bool
    let labels: [String]
    let lang: String?
    let loaded: Bool
    let readProgress: Int
    let documentType: String
    let state: Int
    let textDirection: String
    let type: String
    let resources: BookmarkResourcesDto
    
    enum CodingKeys: String, CodingKey {
        case id, title, url, href, description, authors, created, published, updated, site, labels, lang, loaded, state, type
        case siteName = "site_name"
        case readingTime = "reading_time"
        case wordCount = "word_count"
        case hasArticle = "has_article"
        case isArchived = "is_archived"
        case isDeleted = "is_deleted"
        case isMarked = "is_marked"
        case readProgress = "read_progress"
        case documentType = "document_type"
        case textDirection = "text_direction"
        case resources
    }
}

struct BookmarkResourcesDto: Codable {
    let article: ResourceDto?
    let icon: ImageResourceDto?
    let image: ImageResourceDto?
    let log: ResourceDto?
    let props: ResourceDto?
    let thumbnail: ImageResourceDto?
}

struct ResourceDto: Codable {
    let src: String
}

struct ImageResourceDto: Codable {
    let src: String
    let height: Int
    let width: Int
}


