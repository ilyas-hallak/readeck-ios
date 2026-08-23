//
//  HTTPSession.swift
//  readeck
//
//  Created by Ilyas Hallak
//

import Foundation

/// Slim abstraction over the one URLSession method the app actually uses.
/// `URLSession` already satisfies the signature natively, so the extension stays empty.
/// Tests can inject a simple mock without any URLProtocol setup.
protocol HTTPSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

enum HTTPSessionFactory {
    /// Default session with timeouts tuned for self-hosted / slow servers.
    /// The 60s default otherwise feels like a freeze.
    ///
    /// `waitsForConnectivity` is deliberately left off: OfflineSyncManager detects an
    /// unreachable server through URLError codes such as `.notConnectedToInternet` and
    /// aborts the sync early. Waiting would surface a `.timedOut` only after
    /// `timeoutIntervalForResource`, and that offline detection would silently stop working.
    static func makeDefault() -> HTTPSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        return URLSession(configuration: configuration)
    }
}
