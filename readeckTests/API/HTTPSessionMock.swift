//
//  HTTPSessionMock.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Foundation
@testable import readeck

/// Einfacher HTTPSession-Mock: liefert vorgegebene Antworten nacheinander und
/// zeichnet die gesendeten Requests auf. Reicht die Stub-Liste nicht aus, wird
/// der letzte Stub wiederholt.
final class MockHTTPSession: HTTPSession {
    enum Stub {
        /// Erfolgreiche HTTP-Antwort mit Statuscode, Body und optionalen Headern.
        case http(status: Int, data: Data, headers: [String: String] = [:])
        /// Beliebige (Data, URLResponse) - z. B. eine Nicht-HTTP-Antwort zum Testen von invalidResponse.
        case raw(Data, URLResponse)
        /// Wirft einen Fehler, etwa einen URLError für Server-nicht-erreichbar.
        case failure(Error)
    }

    var stubs: [Stub]
    private(set) var requests: [URLRequest] = []
    private var index = 0

    init(_ stubs: [Stub]) {
        self.stubs = stubs
    }

    convenience init(_ stub: Stub) {
        self.init([stub])
    }

    var lastRequest: URLRequest? { requests.last }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)

        guard let stub = index < stubs.count ? stubs[index] : stubs.last else {
            throw APIError.invalidResponse
        }
        index += 1

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
    /// Bequemer Erfolg mit JSON-String-Body.
    static func json(_ json: String, status: Int = 200) -> MockHTTPSession.Stub {
        .http(status: status, data: Data(json.utf8))
    }
}
