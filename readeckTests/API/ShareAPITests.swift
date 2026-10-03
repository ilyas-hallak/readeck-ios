import Testing
import Foundation
@testable import readeck

@Suite("Share API Tests")
@MainActor
struct ShareAPITests {

    private func makeAPI(_ stub: MockHTTPSession.Stub) -> (API, MockHTTPSession) {
        let session = MockHTTPSession(stub)
        return (API(tokenProvider: TestMockTokenProvider(), session: session), session)
    }

    @Test("getBookmarkShareLink sends a GET and decodes the server's 201 body")
    func shareLinkDecodesResponse() async throws {
        let json = """
        {
          "url": "https://readeck.example.com/@b/AbCdEf123",
          "expires": "2026-10-04T17:25:00Z",
          "title": "Some article",
          "id": "8vnRoGbXUoWdyiHvqaosTu"
        }
        """
        let (api, session) = makeAPI(.json(json, status: 201))

        let dto = try await api.getBookmarkShareLink(id: "8vnRoGbXUoWdyiHvqaosTu")

        #expect(dto.url == "https://readeck.example.com/@b/AbCdEf123")
        let request = try #require(session.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://mock.example.com/api/bookmarks/8vnRoGbXUoWdyiHvqaosTu/share/link")
    }

    @Test("getBookmarkShareLink throws serverError when the bookmark is not loaded yet")
    func shareLinkServerError() async {
        let (api, _) = makeAPI(.http(status: 500, data: Data()))

        await #expect(throws: APIError.serverError(500)) {
            _ = try await api.getBookmarkShareLink(id: "abc")
        }
    }

    @Test("shareBookmarkByEmail posts email and format as JSON")
    func shareByEmailSendsBody() async throws {
        let (api, session) = makeAPI(.json(#"{"status":200,"message":"Email sent to alice@example.com"}"#))

        try await api.shareBookmarkByEmail(
            id: "abc",
            request: ShareBookmarkEmailRequestDto(email: "alice@example.com", format: "epub")
        )

        let request = try #require(session.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://mock.example.com/api/bookmarks/abc/share/email")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try #require(request.httpBody)
        let sent = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(sent == ["email": "alice@example.com", "format": "epub"])
    }

    @Test("shareBookmarkByEmail throws on a 422 form error")
    func shareByEmailValidationError() async {
        let formError = #"{"is_valid":false,"errors":null,"fields":{"email":{"is_valid":false,"errors":["not a valid email address"]}}}"#
        let (api, _) = makeAPI(.json(formError, status: 422))

        await #expect(throws: APIError.serverError(422)) {
            try await api.shareBookmarkByEmail(
                id: "abc",
                request: ShareBookmarkEmailRequestDto(email: "nope", format: "html")
            )
        }
    }
}
