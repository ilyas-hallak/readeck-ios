import Foundation

/// The formats Readeck can mail a bookmark in. The raw values are the
/// `format` values `POST /bookmarks/{id}/share/email` accepts.
enum EmailShareFormat: String, CaseIterable, Identifiable {
    case html
    case epub

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .html:
            return "Article".localized
        case .epub:
            return "E-Book".localized
        }
    }
}
