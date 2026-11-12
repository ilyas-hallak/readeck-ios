import Foundation
import Testing
@testable import readeck

// Readeck answers unknown API paths with a 303 to its HTML login page.
// URLSession follows it, so the client sees status 200 with an HTML body.
@Suite("Missing API endpoints")
struct MissingEndpointTests {
    private let loginPage = MockHTTPSession.Stub.http(
        status: 200,
        data: Data("<!DOCTYPE html><html><body>Sign in</body></html>".utf8),
        headers: ["Content-Type": "text/html; charset=utf-8"]
    )

    @Test("getServerInfo reports a missing endpoint for the HTML login page")
    func infoHTMLLoginPage() async {
        let client = InfoApiClient(tokenProvider: TestMockTokenProvider(), session: MockHTTPSession(loginPage))

        await #expect(throws: APIError.endpointNotAvailable) {
            _ = try await client.getServerInfo(endpoint: "http://192.168.1.205:8000")
        }
    }

    @Test("getServerInfo reports a missing endpoint for 404")
    func info404() async {
        let session = MockHTTPSession(.http(status: 404, data: Data()))
        let client = InfoApiClient(tokenProvider: TestMockTokenProvider(), session: session)

        await #expect(throws: APIError.endpointNotAvailable) {
            _ = try await client.getServerInfo(endpoint: "http://192.168.1.205:8000")
        }
    }

    @Test("getServerInfo keeps 5xx as a server error")
    func info500() async {
        let session = MockHTTPSession(.http(status: 503, data: Data()))
        let client = InfoApiClient(tokenProvider: TestMockTokenProvider(), session: session)

        await #expect(throws: APIError.serverError(503)) {
            _ = try await client.getServerInfo(endpoint: "http://192.168.1.205:8000")
        }
    }

    @Test("login reports a missing endpoint instead of a decoding error")
    func loginHTMLLoginPage() async {
        let api = API(tokenProvider: TestMockTokenProvider(), session: MockHTTPSession(loginPage))

        await #expect(throws: APIError.endpointNotAvailable) {
            _ = try await api.login(endpoint: "http://192.168.1.205:8000", username: "user", password: "secret")
        }
    }
}
