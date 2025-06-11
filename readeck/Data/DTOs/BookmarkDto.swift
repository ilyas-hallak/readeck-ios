import Foundation

struct BookmarkDto: Codable {
    let id: String
    let title: String
    let url: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case createdAt = "created"
    }
}