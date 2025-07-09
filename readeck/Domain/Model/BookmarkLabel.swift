import Foundation

struct BookmarkLabel: Identifiable, Equatable, Hashable {
    let id: String // kann href oder name sein, je nach Backend
    let name: String
    let count: Int
    let href: String
    
    init(name: String, count: Int, href: String) {
        self.name = name
        self.count = count
        self.href = href
        self.id = href // oder name, je nach Backend-Eindeutigkeit
    }
}
