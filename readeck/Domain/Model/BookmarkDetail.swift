import Foundation

struct BookmarkDetail {
    let id: String
    let title: String
    let url: String
    let description: String
    let siteName: String
    let authors: [String]
    let created: String
    let updated: String
    let wordCount: Int?
    let readingTime: Int?
    let hasArticle: Bool
    let isMarked: Bool
    var isArchived: Bool
    let thumbnailUrl: String
    let imageUrl: String
}

extension BookmarkDetail {
    static let empty = BookmarkDetail(
        id: "",
        title: "",
        url: "",
        description: "",
        siteName: "",
        authors: [],
        created: "",
        updated: "",
        wordCount: 0,
        readingTime: 0,
        hasArticle: false,
        isMarked: false,
        isArchived: false,
        thumbnailUrl: "",
        imageUrl: ""
    )
} 
