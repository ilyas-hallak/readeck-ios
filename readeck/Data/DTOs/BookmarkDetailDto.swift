import Foundation

struct BookmarkDetailDto: Codable {
    let id: String
    let href: String
    let created: String
    let updated: String
    let state: Int
    let loaded: Bool
    let url: String
    let title: String
    let siteName: String
    let site: String
    let authors: [String]
    let lang: String
    let textDirection: String
    let documentType: String
    let type: String
    let hasArticle: Bool
    let description: String
    let isDeleted: Bool
    let isMarked: Bool
    let isArchived: Bool
    let labels: [String]
    let readProgress: Int
    let resources: Resources
    let links: [Link]
    let wordCount: Int
    let readingTime: Int
    
    enum CodingKeys: String, CodingKey {
        case id, href, created, updated, state, loaded, url, title
        case siteName = "site_name"
        case site, authors, lang
        case textDirection = "text_direction"
        case documentType = "document_type"
        case type
        case hasArticle = "has_article"
        case description
        case isDeleted = "is_deleted"
        case isMarked = "is_marked"
        case isArchived = "is_archived"
        case labels
        case readProgress = "read_progress"
        case resources, links
        case wordCount = "word_count"
        case readingTime = "reading_time"
    }
    
    struct Resources: Codable {
        let article: Resource
        let icon: ResourceWithDimensions
        let image: ResourceWithDimensions
        let log: Resource
        let props: Resource
        let thumbnail: ResourceWithDimensions
    }
    
    struct Resource: Codable {
        let src: String
    }
    
    struct ResourceWithDimensions: Codable {
        let src: String
        let width: Int
        let height: Int
    }
    
    struct Link: Codable {
        let url: String
        let domain: String
        let title: String
        let isPage: Bool
        let contentType: String
        
        enum CodingKeys: String, CodingKey {
            case url, domain, title
            case isPage = "is_page"
            case contentType = "content_type"
        }
    }
}