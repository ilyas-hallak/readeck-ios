//
//  NetworkMonitorRepositoryTests.swift
//  readeckTests
//

import Testing
import Foundation
import Combine
@testable import readeck

@Suite("NetworkMonitorRepository Tests")
@MainActor
struct NetworkMonitorRepositoryTests {

    @Test("isConnected starts true before startMonitoring() is called")
    func isConnectedStartsTrueBeforeMonitoring() {
        let repository = NetworkMonitorRepository()
        var received: Bool?
        let cancellable = repository.isConnected.sink { received = $0 }
        defer { cancellable.cancel() }

        #expect(received == true)
    }

    @Test("Forcing offline reports the app as offline")
    func forcedOfflineReportsOffline() async {
        let repository = NetworkMonitorRepository()
        var connected: [Bool] = []
        var forced: [Bool] = []
        let connectedSub = repository.isConnected.sink { connected.append($0) }
        let forcedSub = repository.isForcedOffline.sink { forced.append($0) }

        repository.setForcedOffline(true)
        await waitUntil { connected.last == false }

        #expect(connected.last == false)
        #expect(forced == [false, true])
        connectedSub.cancel()
        forcedSub.cancel()
    }

    @Test("Leaving forced offline clears the flag")
    func leavingForcedOfflineClearsFlag() {
        let repository = NetworkMonitorRepository()
        var forced: [Bool] = []
        let sub = repository.isForcedOffline.sink { forced.append($0) }

        repository.setForcedOffline(true)
        repository.setForcedOffline(true)
        repository.setForcedOffline(false)

        #expect(forced == [false, true, false])
        sub.cancel()
    }

    // The connection state is published on the main queue, so give it a moment.
    private func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() && ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
