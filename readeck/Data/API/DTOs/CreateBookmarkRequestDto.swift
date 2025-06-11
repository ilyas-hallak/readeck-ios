import Foundation

struct CreateBookmarkRequestDto: Codable {
    let labels: [String]?
    let title: String?
    let url: String
    
    init(url: String, title: String? = nil, labels: [String]? = nil) {
        self.url = url
        self.title = title
        self.labels = labels
    }
}
