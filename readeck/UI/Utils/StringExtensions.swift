import Foundation

extension String {
    var stripHTML: String {
        // Entfernt HTML-Tags und decodiert HTML-Entities
        let attributedString = try? NSAttributedString(
            data: Data(utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )

        return attributedString?.string ?? self
    }
}
