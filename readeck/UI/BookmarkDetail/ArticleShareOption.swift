import Foundation

/// One entry of the reader's share sheet, in display order.
enum ArticleShareOption: CaseIterable, Identifiable {
    case email
    case originalLink
    case readeckLink
    case pdf

    var id: Self { self }

    var title: String {
        switch self {
        case .email: "Send by Email".localized
        case .originalLink: "Share Original Link".localized
        case .readeckLink: "Share Readeck Link".localized
        case .pdf: "Export as PDF".localized
        }
    }

    var systemImage: String {
        switch self {
        case .email: "envelope"
        case .originalLink: "link"
        case .readeckLink: "globe"
        case .pdf: "doc.richtext"
        }
    }
}
