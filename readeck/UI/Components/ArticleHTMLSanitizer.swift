//
//  ArticleHTMLSanitizer.swift
//  readeck
//
//  Cleans up article HTML before it is handed to a web view. Kept free of
//  WebKit view types so it can be unit tested, and shared by both readers so
//  neither one skips it.
//

import Foundation

enum ArticleHTMLSanitizer {
    /// Removes markup that is harmless in a regular browser but hurts inside the
    /// reader's web view: attributes that trigger spurious navigation/click events,
    /// IDs that bloat the DOM, and invalid nesting that breaks layout.
    static func sanitize(_ html: String) -> String {
        let anchored = anchorTargets(in: html)

        return removeUnreferencedIDs(from: html, keeping: anchored)
            // Remove Google attributes that cause navigation events
            .replacingOccurrences(of: #"\s*jsaction="[^"]*""#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*jscontroller="[^"]*""#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*jsname="[^"]*""#, with: "", options: .regularExpression)
            // Remove tabindex from non-interactive elements
            .replacingOccurrences(of: #"\s*tabindex="[^"]*""#, with: "", options: .regularExpression)
            // Remove role=button from figures (causes false click targets)
            .replacingOccurrences(of: #"\s*role="button""#, with: "", options: .regularExpression)
            // Fix invalid nested <p> tags inside <pre><span>
            .replacingOccurrences(of: #"<pre><span[^>]*>([^<]*)<p>"#, with: "<pre><span>$1\n", options: .regularExpression)
            .replacingOccurrences(of: #"</p>([^<]*)</span></pre>"#, with: "\n$1</span></pre>", options: .regularExpression)
    }

    /// Fragment names the document links to itself, e.g. the `note-1` in
    /// `<a href="#note-1">`. Footnotes and tables of contents rely on these, so the
    /// matching `id` has to survive even though every other ID is stripped.
    private static func anchorTargets(in html: String) -> Set<String> {
        matches(of: ##"href="#([^"]+)""##, in: html).reduce(into: Set<String>()) { targets, capture in
            targets.insert(capture)
        }
    }

    /// Drops `id` attributes that nothing links to. IDs bloat the DOM and the reader
    /// never styles or scripts against them, but removing a jump target breaks
    /// in-document navigation, so referenced ones stay.
    private static func removeUnreferencedIDs(from html: String, keeping referenced: Set<String>) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\s*id="([^"]*)""#) else { return html }

        let full = NSRange(html.startIndex..., in: html)
        var result = ""
        var lastEnd = html.startIndex

        for match in regex.matches(in: html, range: full) {
            guard let range = Range(match.range, in: html),
                  let valueRange = Range(match.range(at: 1), in: html) else { continue }

            result.append(contentsOf: html[lastEnd..<range.lowerBound])
            if referenced.contains(String(html[valueRange])) {
                result.append(contentsOf: html[range])
            }
            lastEnd = range.upperBound
        }

        result.append(contentsOf: html[lastEnd...])
        return result
    }

    private static func matches(of pattern: String, in html: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let full = NSRange(html.startIndex..., in: html)
        return regex.matches(in: html, range: full).compactMap { match in
            Range(match.range(at: 1), in: html).map { String(html[$0]) }
        }
    }
}
