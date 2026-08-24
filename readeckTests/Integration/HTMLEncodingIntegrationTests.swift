import Testing
import Foundation

// Integration test – requires a real Readeck server.
// Fill in TOKEN and ENDPOINT before running.
private enum Config {
    static let token = "PASTE_TOKEN_HERE"
    static let endpoint = "PASTE_ENDPOINT_HERE"

    /// Without real credentials the test is skipped instead of failing.
    static var isConfigured: Bool {
        !token.hasPrefix("PASTE_") && !endpoint.hasPrefix("PASTE_")
    }
}

private struct CreateRequest: Encodable {
    let url: String
    let title: String?
    let html: String?
}

private struct CreateResponse: Decodable {
    let message: String
    let status: Int
}

private struct BookmarkResponse: Decodable {
    let id: String
    let title: String
    let description: String
    let resources: BookmarkResources
}

private struct BookmarkResources: Decodable {
    let article: ArticleResource?
}

private struct ArticleResource: Decodable {
    let src: String
}

struct HTMLEncodingIntegrationTests {

    @Test(.enabled(if: Config.isConfigured, "Requires a real Readeck server: fill in TOKEN and ENDPOINT"))
    func createAndReadBookmarkWithUTF8HTML() async throws {
        let html = """
        <html><head><meta charset="utf-8"></head><body>
        <h1>UTF-8 Test: Ä ö ü ß café 日本語 🎉</h1>
        <p>Umlaute: ä ö ü Ä Ö Ü ß</p>
        <p>Französisch: é è ê ñ</p>
        </body></html>
        """

        let uniqueURL = "https://example.com/utf8-test-\(Int(Date().timeIntervalSince1970))"

        // 1. Create the bookmark
        let body = try JSONEncoder().encode(CreateRequest(url: uniqueURL, title: "UTF-8 Test", html: html))

        var createRequest = URLRequest(url: try #require(URL(string: "\(Config.endpoint)/api/bookmarks")))
        createRequest.httpMethod = "POST"
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        createRequest.setValue("Bearer \(Config.token)", forHTTPHeaderField: "Authorization")
        createRequest.httpBody = body

        let (_, createResponse) = try await URLSession.shared.data(for: createRequest)
        let createHttp = try #require(createResponse as? HTTPURLResponse)
        #expect(createHttp.statusCode == 202, "Bookmark-Erstellung fehlgeschlagen: \(createHttp.statusCode)")

        let location = try #require(createHttp.value(forHTTPHeaderField: "Location"), "Kein Location-Header")
        let bookmarkURL = try #require(URL(string: location.hasPrefix("http") ? location : "\(Config.endpoint)\(location)"))

        // 2. Kurz warten bis verarbeitet
        try await Task.sleep(for: .seconds(3))

        // 3. Bookmark lesen
        var readRequest = URLRequest(url: bookmarkURL)
        readRequest.setValue("Bearer \(Config.token)", forHTTPHeaderField: "Authorization")
        readRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, readResponse) = try await URLSession.shared.data(for: readRequest)
        let readHttp = try #require(readResponse as? HTTPURLResponse)
        #expect(readHttp.statusCode == 200, "Lesen fehlgeschlagen: \(readHttp.statusCode)")

        // 4. Print the response for inspection
        let responseString = try #require(String(data: data, encoding: .utf8))
        print("📋 Bookmark Response:\n\(responseString)")

        let bookmark = try JSONDecoder().decode(BookmarkResponse.self, from: data)
        print("📌 Titel: \(bookmark.title)")
        print("📝 Beschreibung: \(bookmark.description)")

        // 5. Fetch the article content and verify UTF-8
        let articleSrc = try #require(bookmark.resources.article?.src, "Kein Artikel-Resource")
        let articleURL = try #require(URL(string: articleSrc))

        var articleRequest = URLRequest(url: articleURL)
        articleRequest.setValue("Bearer \(Config.token)", forHTTPHeaderField: "Authorization")

        let (articleData, _) = try await URLSession.shared.data(for: articleRequest)
        let articleHTML = try #require(String(data: articleData, encoding: .utf8))
        print("📄 Artikel-HTML (erste 1000 Zeichen):\n\(articleHTML.prefix(1000))")

        let expectedChars = ["Ä", "ö", "ü", "ß", "é"]
        for char in expectedChars {
            #expect(articleHTML.contains(char), "UTF-8 Zeichen '\(char)' fehlt im Artikel-Content")
        }
    }
}
