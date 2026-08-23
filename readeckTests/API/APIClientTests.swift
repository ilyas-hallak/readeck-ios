//
//  APIClientTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
@testable import readeck

@Suite("API Client Tests (injected HTTPSession)")
@MainActor
struct APIClientTests {

    // MARK: - ProfileApiClient

    @Test("getProfile decodes the profile and sends a Bearer token")
    func profileSuccess() async throws {
        let json = """
        {
          "user": { "username": "ilyas", "email": "ilyas@example.com", "created": null, "updated": null },
          "provider": { "id": "1", "name": "local", "application": null, "roles": null, "permissions": null }
        }
        """
        let session = MockHTTPSession(.json(json))
        let client = ProfileApiClient(tokenProvider: TestMockTokenProvider(), session: session)

        let profile = try await client.getProfile()

        #expect(profile.user.username == "ilyas")
        #expect(profile.user.email == "ilyas@example.com")
        #expect(profile.provider.name == "local")
        // TestMockTokenProvider liefert "mock-token"
        #expect(session.lastRequest?.value(forHTTPHeaderField: "authorization") == "Bearer mock-token")
    }

    @Test("getProfile throws serverError on 5xx")
    func profileServerError() async throws {
        let session = MockHTTPSession(.http(status: 500, data: Data()))
        let client = ProfileApiClient(tokenProvider: TestMockTokenProvider(), session: session)

        await #expect(throws: APIError.serverError(500)) {
            _ = try await client.getProfile()
        }
    }

    @Test("getProfile throws invalidResponse on a non-HTTP response")
    func profileInvalidResponse() async throws {
        let url = URL(string: "https://mock.example.com/api/profile")!
        let nonHTTP = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let session = MockHTTPSession(.raw(Data(), nonHTTP))
        let client = ProfileApiClient(tokenProvider: TestMockTokenProvider(), session: session)

        await #expect(throws: APIError.invalidResponse) {
            _ = try await client.getProfile()
        }
    }

    // MARK: - InfoApiClient

    @Test("getServerInfo decodes a nested version object")
    func infoNestedVersion() async throws {
        let json = """
        { "version": { "canonical": "0.15.0", "release": "0.15.0", "build": "abc" }, "features": ["a"] }
        """
        let session = MockHTTPSession(.json(json))
        let client = InfoApiClient(tokenProvider: TestMockTokenProvider(), session: session)

        let info = try await client.getServerInfo()

        #expect(info.version.canonical == "0.15.0")
        #expect(info.features == ["a"])
    }

    @Test("getServerInfo decodes a plain version string defensively")
    func infoPlainVersionString() async throws {
        let json = """
        { "version": "0.14.1" }
        """
        let session = MockHTTPSession(.json(json))
        let client = InfoApiClient(tokenProvider: TestMockTokenProvider(), session: session)

        let info = try await client.getServerInfo()

        #expect(info.version.canonical == "0.14.1")
    }

    // MARK: - API

    @Test("getBookmarkLabels decodes labels via the injected session")
    func apiLabelsSuccess() async throws {
        let json = """
        [
          { "name": "swift", "count": 3, "href": "/api/bookmarks/labels/swift" },
          { "name": "ios", "count": 1, "href": "/api/bookmarks/labels/ios" }
        ]
        """
        let session = MockHTTPSession(.json(json))
        let api = API(tokenProvider: TestMockTokenProvider(), session: session)

        let labels = try await api.getBookmarkLabels()

        #expect(labels.count == 2)
        #expect(labels.first?.name == "swift")
        #expect(labels.first?.count == 3)
        #expect(session.lastRequest?.url?.absoluteString == "https://mock.example.com/api/bookmarks/labels")
    }

    @Test("API surfaces serverError from the injected session")
    func apiServerError() async throws {
        let session = MockHTTPSession(.http(status: 503, data: Data()))
        let api = API(tokenProvider: TestMockTokenProvider(), session: session)

        await #expect(throws: APIError.self) {
            _ = try await api.getBookmarkLabels()
        }
    }
}
