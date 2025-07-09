import Foundation

struct BookmarkLabelDto: Codable, Identifiable {
    var id: String { get { href } }
    let name: String
    let count: Int
    let href: String
    
    enum CodingKeys: String, CodingKey {
        case name, count, href
    }
    
    init(name: String, count: Int, href: String) {
        self.name = name
        self.count = count
        self.href = href
    }
} 
