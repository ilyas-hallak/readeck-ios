import Foundation

struct Annotation: Identifiable, Hashable {
    let id: String
    let text: String
    let created: String
    let startOffset: Int
    let endOffset: Int
    let startSelector: String
    let endSelector: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Annotation, rhs: Annotation) -> Bool {
        lhs.id == rhs.id
    }
}
