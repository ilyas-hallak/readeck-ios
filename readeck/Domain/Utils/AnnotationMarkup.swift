import Foundation

/// Reads and edits the highlight markup the server renders into article HTML.
enum AnnotationMarkup {
    /// IDs of all highlights in `html`. Multi paragraph highlights and notes repeat
    /// an ID across several tags, so the result is a set.
    static func annotationIds(in html: String) -> Set<String> {
        let pattern = /<rd-annotation\b[^>]*\bdata-annotation-id-value="([^"]+)"/
        return Set(html.matches(of: pattern).map { String($0.output.1) })
    }

    /// Strips the `<rd-annotation>` wrapper tags for `id`, keeping their inner text, so a
    /// deleted highlight disappears from `html` immediately instead of waiting for the next
    /// server refresh. Multi paragraph highlights repeat the same ID across several tags, so
    /// every matching tag is unwrapped.
    static func removingAnnotation(id: String, from html: String) -> String {
        let escapedId = NSRegularExpression.escapedPattern(for: id)
        let pattern = "<rd-annotation\\b[^>]*\\bdata-annotation-id-value=\"\(escapedId)\"[^>]*>([\\s\\S]*?)</rd-annotation>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }
        let range = NSRange(html.startIndex..., in: html)
        return regex.stringByReplacingMatches(in: html, range: range, withTemplate: "$1")
    }
}
