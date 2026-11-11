import Testing
import Foundation
@testable import readeck

@Suite("BookmarksRepository sharing")
struct BookmarkShareRepositoryTests {

    @Test("createShareLink returns the public URL")
    func createShareLinkMapsURL() async throws {
        let api = StubAPI()
        api.getBookmarkShareLinkHandler = { _ in BookmarkShareLinkDto(url: "https://readeck.example.com/@b/xyz") }

        let url = try await BookmarksRepository(api: api).createShareLink(id: "abc")

        #expect(url.absoluteString == "https://readeck.example.com/@b/xyz")
    }

    @Test("createShareLink rejects an unusable URL")
    func createShareLinkInvalidURL() async {
        let api = StubAPI()
        api.getBookmarkShareLinkHandler = { _ in BookmarkShareLinkDto(url: "") }

        await #expect(throws: APIError.invalidResponse) {
            _ = try await BookmarksRepository(api: api).createShareLink(id: "abc")
        }
    }

    @Test("shareByEmail sends the format's raw value")
    func shareByEmailMapsFormat() async throws {
        let api = StubAPI()
        var received: (String, ShareBookmarkEmailRequestDto)?
        api.shareBookmarkByEmailHandler = { id, request in received = (id, request) }

        try await BookmarksRepository(api: api).shareByEmail(id: "abc", email: "alice@example.com", format: .epub)

        #expect(received?.0 == "abc")
        #expect(received?.1.email == "alice@example.com")
        #expect(received?.1.format == "epub")
    }
}
