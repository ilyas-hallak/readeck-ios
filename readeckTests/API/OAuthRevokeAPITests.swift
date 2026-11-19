import Testing
import Foundation
@testable import readeck

@Suite("OAuth Revoke API Tests")
@MainActor
struct OAuthRevokeAPITests {

    private func makeAPI(_ stub: MockHTTPSession.Stub, tokenProvider: RecordingTokenProvider = RecordingTokenProvider()) -> (API, MockHTTPSession) {
        let session = MockHTTPSession(stub)
        return (API(tokenProvider: tokenProvider, session: session), session)
    }

    @Test("revokeOAuthToken posts the token to the revoke endpoint")
    func revokeSendsRequest() async throws {
        let tokenProvider = RecordingTokenProvider(token: "existing-token", endpoint: "https://mock.example.com")
        let (api, session) = makeAPI(.http(status: 200, data: Data()), tokenProvider: tokenProvider)

        try await api.revokeOAuthToken()

        let request = try #require(session.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://mock.example.com/api/oauth/revoke")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer existing-token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.timeoutInterval == 5)
        let body = try #require(request.httpBody)
        let sent = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(sent == ["token": "existing-token"])
    }

    @Test("revokeOAuthToken throws serverError on a non-2xx response")
    func revokeServerError() async {
        let (api, _) = makeAPI(.http(status: 401, data: Data()))

        await #expect(throws: APIError.serverError(401)) {
            try await api.revokeOAuthToken()
        }
    }

    @Test("revokeOAuthToken throws without sending a request when the token is missing")
    func revokeMissingToken() async {
        let tokenProvider = RecordingTokenProvider(token: nil, endpoint: "https://mock.example.com")
        let (api, session) = makeAPI(.http(status: 200, data: Data()), tokenProvider: tokenProvider)

        await #expect(throws: APIError.self) {
            try await api.revokeOAuthToken()
        }
        #expect(session.requests.isEmpty)
    }

    @Test("revokeOAuthToken throws without sending a request when the endpoint is missing")
    func revokeMissingEndpoint() async {
        let tokenProvider = RecordingTokenProvider(token: "existing-token", endpoint: nil)
        let (api, session) = makeAPI(.http(status: 200, data: Data()), tokenProvider: tokenProvider)

        await #expect(throws: APIError.self) {
            try await api.revokeOAuthToken()
        }
        #expect(session.requests.isEmpty)
    }
}
