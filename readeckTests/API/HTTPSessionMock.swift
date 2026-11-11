//
//  HTTPSessionMock.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Foundation
import Synchronization
@testable import readeck

/// Simple HTTPSession mock: returns the given responses in order and records the
/// requests it was handed. Once the stub list runs out, the last stub repeats.
final class MockHTTPSession: HTTPSession {
    enum Stub {
        /// Successful HTTP response with status code, body and optional headers.
        case http(status: Int, data: Data, headers: [String: String] = [:])
        /// Any (Data, URLResponse) pair, e.g. a non-HTTP response to exercise invalidResponse.
        case raw(Data, URLResponse)
        /// Throws an error, e.g. a URLError standing in for an unreachable server.
        case failure(Error)
    }

    private struct State {
        let stubs: [Stub]
        var requests: [URLRequest] = []
        var index = 0
    }

    private let state: Mutex<State>

    init(_ stubs: [Stub]) {
        self.state = Mutex(State(stubs: stubs))
    }

    convenience init(_ stub: Stub) {
        self.init([stub])
    }

    var requests: [URLRequest] { state.withLock { $0.requests } }
    var lastRequest: URLRequest? { requests.last }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let stub = state.withLock { state -> Stub? in
            state.requests.append(request)
            let stub = state.index < state.stubs.count ? state.stubs[state.index] : state.stubs.last
            state.index += 1
            return stub
        }
        guard let stub else {
            throw APIError.invalidResponse
        }

        switch stub {
        case let .http(status, data, headers):
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://mock.example.com")!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            )!
            return (data, response)
        case let .raw(data, response):
            return (data, response)
        case let .failure(error):
            throw error
        }
    }
}

extension MockHTTPSession.Stub {
    /// Convenience success with a JSON string body.
    static func json(_ json: String, status: Int = 200) -> MockHTTPSession.Stub {
        .http(status: status, data: Data(json.utf8))
    }
}
