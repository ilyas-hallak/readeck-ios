//
//  NetworkMonitorRepositoryTests.swift
//  readeckTests
//

import Testing
import Combine
@testable import readeck

@Suite("NetworkMonitorRepository Tests")
struct NetworkMonitorRepositoryTests {

    @Test("isConnected starts true before startMonitoring() is called")
    func isConnectedStartsTrueBeforeMonitoring() {
        let repository = NetworkMonitorRepository()
        var received: Bool?
        let cancellable = repository.isConnected.sink { received = $0 }
        defer { cancellable.cancel() }

        #expect(received == true)
    }
}
