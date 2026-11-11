import Foundation

// Bookmarks the server could not fetch, or is still fetching, have no title.
enum BookmarkDisplayTitle {
    static func make(title: String, siteName: String, url: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty { return trimmedTitle }

        let trimmedSiteName = siteName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSiteName.isEmpty { return withoutWWW(trimmedSiteName) }

        if let host = URL(string: url)?.host(), !host.isEmpty { return withoutWWW(host) }
        return url
    }

    private static func withoutWWW(_ value: String) -> String {
        value.lowercased().hasPrefix("www.") ? String(value.dropFirst(4)) : value
    }
}

extension Bookmark {
    var displayTitle: String {
        BookmarkDisplayTitle.make(title: title, siteName: siteName, url: url)
    }
}

extension BookmarkDetail {
    var displayTitle: String {
        BookmarkDisplayTitle.make(title: title, siteName: siteName, url: url)
    }
}
