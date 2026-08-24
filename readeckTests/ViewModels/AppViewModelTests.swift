//
//  AppViewModelTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 22.03.26.
//

import Testing
import Foundation
@testable import readeck

/// Serialized because the tests drive the view model through app-wide
/// NotificationCenter events, which would otherwise cross between parallel cases.
@Suite("AppViewModel Tests", .serialized)
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

        await waitUntil { vm.hasFinishedSetup == false }

        #expect(vm.hasFinishedSetup == false)
        #expect(factory.mockLogout.executeCalled == true)
    }

    @Test("A failing logout is swallowed and does not block later attempts")
    func unauthorizedNotification_logoutFailureIsRecoverable() async throws {
        let factory = TestUseCaseFactory()
        factory.mockLogout.result = .failure(TestError.networkError)
        let vm = AppViewModel(factory: factory)

        NotificationCenter.default.post(name: .unauthorizedAPIResponse, object: nil)
        await waitUntil { factory.mockLogout.executeCount == 1 }

        // A second 401 must still trigger a logout attempt.
        factory.mockLogout.result = .success(())
        NotificationCenter.default.post(name: .unauthorizedAPIResponse, object: nil)
        await waitUntil { factory.mockLogout.executeCount == 2 }

        #expect(factory.mockLogout.executeCount == 2)
        withExtendedLifetime(vm) {}
    }

    // MARK: - Setup Status

    @Test("setupStatusChanged notification reloads the setup status")
    func setupStatusChangedNotification_reloadsSetup() async {
        let factory = TestUseCaseFactory()
        factory.mockSettingsRepository.hasFinishedSetup = false
        let vm = AppViewModel(factory: factory)
        #expect(vm.hasFinishedSetup == false)

        factory.mockSettingsRepository.hasFinishedSetup = true
        NotificationCenter.default.post(name: .setupStatusChanged, object: nil)

        await waitUntil { vm.hasFinishedSetup }

        #expect(vm.hasFinishedSetup == true)
    }

    // MARK: - Unread Badge

    @Test("Archiving or deleting a bookmark refreshes the unread badge")
    func bookmarkMutationNotifications_refreshBadge() async {
        let factory = TestUseCaseFactory()
        // Must stay alive: the observers capture the view model weakly.
        let vm = AppViewModel(factory: factory)

        NotificationCenter.default.post(name: .bookmarkArchived, object: nil, userInfo: ["id": "1"])
        await waitUntil { factory.mockUpdateUnreadBadge.refreshCount >= 1 }
        #expect(factory.mockUpdateUnreadBadge.refreshCount >= 1)

        NotificationCenter.default.post(name: .bookmarkDeleted, object: nil, userInfo: ["id": "1"])
        await waitUntil { factory.mockUpdateUnreadBadge.refreshCount >= 2 }
        #expect(factory.mockUpdateUnreadBadge.refreshCount >= 2)

        withExtendedLifetime(vm) {}
    }

    @Test("Resuming the app refreshes the unread badge")
    func onAppResume_refreshesBadge() async {
        let factory = TestUseCaseFactory()
        let vm = AppViewModel(factory: factory)

        await vm.onAppResume()

        #expect(factory.mockUpdateUnreadBadge.refreshCount >= 1)
    }

    // MARK: - Helpers

    /// Polls until `condition` holds instead of sleeping for a fixed interval,
    /// so notification-driven tests neither flake nor pay a fixed delay.
    private func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
