//
//  SimpleAPITests.swift
//  URLShareTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation

/// `SimpleAPI` is static by design, so the environment is set per test and
/// restored to `live()` afterwards.
@Suite("SimpleAPI Tests", .serialized)
struct SimpleAPITests {
    private func withEnvironment(
        _ environment: SimpleAPIEnvironment,
        _ body: () async throws -> Void
    ) async rethrows {
        SimpleAPI.environment = environment
        defer { SimpleAPI.environment = .live() }
        try await body()
    }

    // MARK: - Server Reachability

    @Test("checkServerReachability decodes the server info when reachable")
    func serverReachable() async throws {
        let session = MockHTTPSession(.json(#"{"version": {"canonical": "0.22.0"}}"#))

        await withEnvironment(.test(session: session)) {
            let info = await SimpleAPI.checkServerReachability()

            #expect(info?.version.canonical == "0.22.0")
            #expect(info?.supportsHTMLBookmarks == true)
            #expect(session.lastRequest?.url?.absoluteString == "https://mock.example.com/api/info")
        }
    }

    @Test("checkServerReachability returns nil when the server is unreachable")
    func serverUnreachable() async throws {
        let session = MockHTTPSession(.failure(URLError(.cannotConnectToHost)))

        await withEnvironment(.test(session: session)) {
            #expect(await SimpleAPI.checkServerReachability() == nil)
        }
    }

    @Test("checkServerReachability returns nil on a server error")
    func serverReturnsError() async throws {
        let session = MockHTTPSession(.http(status: 500, data: Data()))

        await withEnvironment(.test(session: session)) {
            #expect(await SimpleAPI.checkServerReachability() == nil)
        }
    }

    @Test("checkServerReachability returns nil without a configured endpoint")
    func serverWithoutEndpoint() async throws {
        let session = MockHTTPSession(.json("{}"))

        await withEnvironment(.test(session: session, endpoint: nil)) {
            #expect(await SimpleAPI.checkServerReachability() == nil)
            #expect(session.requests.isEmpty)
        }
    }

    @Test("an older server does not advertise HTML bookmark support")
    func oldServerLacksHTMLSupport() async throws {
        let session = MockHTTPSession(.json(#"{"version": {"canonical": "0.21.9"}}"#))

        await withEnvironment(.test(session: session)) {
            let info = await SimpleAPI.checkServerReachability()
            #expect(info?.supportsHTMLBookmarks == false)
        }
    }

    // MARK: - addBookmark

    @Test("addBookmark reports success and extracts the id from the Bookmark-Id header")
    func addBookmarkSuccess() async throws {
        let session = MockHTTPSession(
            .json(#"{"message": "created", "status": 0}"#, headers: ["Bookmark-Id": "bm-42"])
        )

        await withEnvironment(.test(session: session)) {
            var result: (message: String, isError: Bool, id: String?)?
            await SimpleAPI.addBookmark(title: "T", url: "https://example.com/a", labels: ["swift"]) {
                result = ($0, $1, $2)
            }

            #expect(result?.isError == false)
            #expect(result?.id == "bm-42")
            #expect(session.lastRequest?.url?.absoluteString == "https://mock.example.com/api/bookmarks")
            #expect(session.lastRequest?.httpMethod == "POST")
            #expect(session.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        }
    }

    @Test("addBookmark falls back to the Location header for the id")
    func addBookmarkIdFromLocation() async throws {
        let session = MockHTTPSession(
            .json(#"{"message": "created", "status": 0}"#, headers: ["Location": "/api/bookmarks/bm-7"])
        )

        await withEnvironment(.test(session: session)) {
            var id: String?
            await SimpleAPI.addBookmark(title: "T", url: "https://example.com/a") { _, _, bookmarkId in
                id = bookmarkId
            }
            #expect(id == "bm-7")
        }
    }

    @Test("addBookmark sends the request body with url, title and labels")
    func addBookmarkSendsBody() async throws {
        let session = MockHTTPSession(.json(#"{"message": "created", "status": 0}"#))

        await withEnvironment(.test(session: session)) {
            await SimpleAPI.addBookmark(title: "Title", url: "https://example.com/a", labels: ["x"]) { _, _, _ in }

            let body = try! #require(session.lastRequest?.httpBody)
            let decoded = try! JSONDecoder().decode(CreateBookmarkRequestDto.self, from: body)
            #expect(decoded.url == "https://example.com/a")
            #expect(decoded.title == "Title")
            #expect(decoded.labels == ["x"])
        }
    }

    @Test("addBookmark reports a network error instead of throwing")
    func addBookmarkNetworkError() async throws {
        let session = MockHTTPSession(.failure(URLError(.notConnectedToInternet)))

        await withEnvironment(.test(session: session)) {
            var result: (message: String, isError: Bool)?
            await SimpleAPI.addBookmark(title: "T", url: "https://example.com/a") { message, isError, _ in
                result = (message, isError)
            }

            #expect(result?.isError == true)
            #expect(result?.message.contains("Network error") == true)
        }
    }

    @Test("addBookmark surfaces a 401 as an expired session")
    func addBookmarkUnauthorized() async throws {
        let session = MockHTTPSession(.http(status: 401, data: Data()))

        await withEnvironment(.test(session: session)) {
            var result: (message: String, isError: Bool)?
            await SimpleAPI.addBookmark(title: "T", url: "https://example.com/a") { message, isError, _ in
                result = (message, isError)
            }

            #expect(result?.isError == true)
            #expect(result?.message.contains("Session expired") == true)
        }
    }

    @Test("addBookmark reports a missing token without hitting the network")
    func addBookmarkWithoutToken() async throws {
        let session = MockHTTPSession(.json("{}"))

        await withEnvironment(.test(session: session, token: nil)) {
            var result: (message: String, isError: Bool)?
            await SimpleAPI.addBookmark(title: "T", url: "https://example.com/a") { message, isError, _ in
                result = (message, isError)
            }

            #expect(result?.isError == true)
            #expect(result?.message.contains("No token found") == true)
            #expect(session.requests.isEmpty)
        }
    }
}
