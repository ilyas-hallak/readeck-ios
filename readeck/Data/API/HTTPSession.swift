//
//  HTTPSession.swift
//  readeck
//
//  Created by Ilyas Hallak
//

import Foundation

/// Schmale Abstraktion über die eine URLSession-Methode, die die App tatsächlich nutzt.
/// `URLSession` erfüllt die Signatur bereits nativ, dadurch bleibt die Extension leer.
/// In Tests lässt sich ein einfacher Mock injizieren, ohne URLProtocol-Setup.
protocol HTTPSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

enum HTTPSessionFactory {
    /// Default-Session mit konfigurierten Timeouts für self-hosted / langsame Server.
    /// Der 60s-Default fühlt sich sonst wie ein Freeze an.
    ///
    /// `waitsForConnectivity` bleibt bewusst aus: OfflineSyncManager erkennt einen
    /// nicht erreichbaren Server an URLError-Codes wie `.notConnectedToInternet` und
    /// bricht den Sync dann früh ab. Mit Warten käme stattdessen erst nach
    /// `timeoutIntervalForResource` ein `.timedOut`, und die Offline-Erkennung liefe ins Leere.
    static func makeDefault() -> HTTPSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        return URLSession(configuration: configuration)
    }
}
