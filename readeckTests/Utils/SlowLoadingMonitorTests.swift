//
//  SlowLoadingMonitorTests.swift
//  readeckTests
//

import Testing
import Foundation
@testable import readeck

@Suite("SlowLoadingMonitor Tests")
@MainActor
struct SlowLoadingMonitorTests {

    @Test("Loading turns slow once the threshold has passed")
    func becomesSlowAfterThreshold() async throws {
        let monitor = SlowLoadingMonitor(threshold: .milliseconds(50))

        monitor.update(isLoading: true)
        #expect(monitor.isSlow == false)

        try await Task.sleep(for: .milliseconds(200))
        #expect(monitor.isSlow == true)
    }

    @Test("Loading that ends before the threshold never turns slow")
    func fastLoadStaysFast() async throws {
        let monitor = SlowLoadingMonitor(threshold: .milliseconds(100))

        monitor.update(isLoading: true)
        try await Task.sleep(for: .milliseconds(20))
        monitor.update(isLoading: false)
        try await Task.sleep(for: .milliseconds(200))

        #expect(monitor.isSlow == false)
    }

    @Test("Finishing a slow load clears the flag")
    func finishingResets() async throws {
        let monitor = SlowLoadingMonitor(threshold: .milliseconds(20))
        monitor.update(isLoading: true)
        try await Task.sleep(for: .milliseconds(150))
        #expect(monitor.isSlow == true)

        monitor.update(isLoading: false)

        #expect(monitor.isSlow == false)
    }
}
