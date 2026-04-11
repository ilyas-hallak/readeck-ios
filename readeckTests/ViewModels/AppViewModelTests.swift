//
//  AppViewModelTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 22.03.26.
//

import Testing
import Foundation
@testable import readeck

@Suite("AppViewModel Tests")
@MainActor
struct AppViewModelTests {

    // MARK: - Initial State

    @Test("Initial state has hasFinishedSetup true by default")
    func initialState_hasFinishedSetup() {
        let factory = TestUseCaseFactory()
        let vm = AppViewModel(factory: factory)

        #expect(vm.hasFinishedSetup == true)
    }

    // MARK: - Server Reachability

    @Test("onAppResume sets isServerReachable to true when server is reachable")
    func onAppResume_serverReachable() async {
        let factory = TestUseCaseFactory()
        factory.mockCheckReachability.isReachable = true
        let vm = AppViewModel(factory: factory)

        await vm.onAppResume()

        #expect(vm.isServerReachable == true)
    }

    @Test("onAppResume sets isServerReachable to false when server is unreachable")
    func onAppResume_serverUnreachable() async {
        let factory = TestUseCaseFactory()
        factory.mockCheckReachability.isReachable = false
        let vm = AppViewModel(factory: factory)

        await vm.onAppResume()

        #expect(vm.isServerReachable == false)
    }

    // MARK: - Unauthorized Notification

    @Test("Unauthorized notification triggers logout and reloads setup status")
    func unauthorizedNotification_logsOutAndReloadsSetup() async throws {
        let factory = TestUseCaseFactory()
        let vm = AppViewModel(factory: factory)

        // Verify initial state
        #expect(vm.hasFinishedSetup == true)

        // Simulate the settings changing after logout clears them
        factory.mockSettingsRepository.hasFinishedSetup = false

        // Post the unauthorized notification
        NotificationCenter.default.post(name: .unauthorizedAPIResponse, object: nil)

        // Wait for the async handler to complete
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(vm.hasFinishedSetup == false)
    }
}
