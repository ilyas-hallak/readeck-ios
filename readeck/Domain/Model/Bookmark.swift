import Foundation

struct BookmarksPage {
    var bookmarks: [Bookmark]
    let currentPage: Int?
    let totalCount: Int?
    let totalPages: Int?
    let links: [String]?
}

struct Bookmark {
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
    let resources: BookmarkResources
}

struct BookmarkResources {
    let article: Resource?
    let icon: ImageResource?
    let image: ImageResource?
    let log: Resource?
    let props: Resource?
    let thumbnail: ImageResource?
}

struct Resource {
    let src: String
}

struct ImageResource {
    let src: String
    let height: Int
    let width: Int
}

extension Bookmark: Hashable, Identifiable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        lhs.id == rhs.id
    }
}
