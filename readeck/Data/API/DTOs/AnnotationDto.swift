import Foundation

struct AnnotationDto: Codable {
    let id: String
    let text: String
    let created: String
    let startOffset: Int
    let endOffset: Int
    let startSelector: String
    let endSelector: String

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case created
        case startOffset = "start_offset"
        case endOffset = "end_offset"
        case startSelector = "start_selector"
        case endSelector = "end_selector"
    }
}
