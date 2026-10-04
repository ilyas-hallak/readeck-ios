//
//  OfflineGatedHTTPSessionTests.swift
//  readeckTests
//

import Testing
import Foundation
import Combine
@testable import readeck

/// Never answers, like a server behind a connection that drops every packet.
private final class HangingHTTPSession: HTTPSession {
    private(set) var callCount = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        callCount += 1
        try await Task.sleep(for: .seconds(60))
        throw URLError(.timedOut)
    }
}

@Suite("OfflineGatedHTTPSession Tests")
struct OfflineGatedHTTPSessionTests {
    private let request = URLRequest(url: URL(string: "https://readeck.example.com/api/bookmarks")!)

    @Test("Requests pass through while online")
    func passesThroughWhileOnline() async throws {
        let base = MockHTTPSession(.json("{}"))
        let session = OfflineGatedHTTPSession(base: base, isForcedOffline: Just(false).eraseToAnyPublisher())

        let (data, _) = try await session.data(for: request)

        #expect(data == Data("{}".utf8))
        #expect(base.requests.count == 1)
    }

    @Test("Requests fail at once while forced offline")
    func failsFastWhileForcedOffline() async {
        let base = MockHTTPSession(.json("{}"))
        let session = OfflineGatedHTTPSession(base: base, isForcedOffline: Just(true).eraseToAnyPublisher())

        await #expect(throws: URLError(.notConnectedToInternet)) {
            _ = try await session.data(for: request)
        }
        #expect(base.requests.isEmpty)
    }

    @Test("Going offline cuts off a hanging request")
    func goingOfflineCancelsHangingRequest() async throws {
        let forcedOffline = CurrentValueSubject<Bool, Never>(false)
        let session = OfflineGatedHTTPSession(
            base: HangingHTTPSession(),
            isForcedOffline: forcedOffline.eraseToAnyPublisher()
        )
        let request = request
        let pending = Task { try await session.data(for: request) }
        try await Task.sleep(for: .milliseconds(50))

        let start = ContinuousClock.now
        forcedOffline.send(true)

        await #expect(throws: URLError(.notConnectedToInternet)) {
            _ = try await pending.value
        }
        #expect(ContinuousClock.now - start < .seconds(1))
    }
}
