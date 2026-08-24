//
//  UpdateUnreadBadgeUseCase.swift
//  readeck
//
//  Business logic for the unread app-icon badge (opt-in, off by default).
//
//  The count mirrors the app's "Unread" tab (not archived; favorites count too) and is
//  read cheaply from the `Total-Count` header via a `limit: 1` bookmarks request —
//  no dedicated endpoint or full fetch. Applying the value goes through the
//  `PAppBadgeService` output port, keeping the platform API out of the domain.
//

import Foundation

protocol PUpdateUnreadBadgeUseCase {
    /// Recomputes the unread badge from the current setting and the server unread
    /// count and applies it. Clears the badge when the feature is off; leaves it
    /// untouched on fetch errors (e.g. offline).
    func refresh() async

    /// Applies the toggle state. When enabling, requests badge permission and
    /// returns whether the feature ended up enabled — the caller reverts the
    /// toggle if permission was denied.
    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool
}

final class UpdateUnreadBadgeUseCase: PUpdateUnreadBadgeUseCase {
    private let settingsRepository: PSettingsRepository
    private let getBookmarksUseCase: PGetBookmarksUseCase
    private let badgeService: PAppBadgeService

    init(
        settingsRepository: PSettingsRepository,
        getBookmarksUseCase: PGetBookmarksUseCase,
        badgeService: PAppBadgeService
    ) {
        self.settingsRepository = settingsRepository
        self.getBookmarksUseCase = getBookmarksUseCase
        self.badgeService = badgeService
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        guard enabled else {
            await badgeService.setBadgeCount(0)
            return true
        }

        guard await badgeService.requestAuthorization() else {
            Logger.general.info("Unread badge: notification permission denied")
            return false
        }
        // The user just enabled the feature — apply the count immediately without
        // gating on the stored flag, which the caller may not have persisted yet.
        await applyUnreadCount()
        return true
    }

    func refresh() async {
        let settings = try? await settingsRepository.loadSettings()

        guard settings?.showUnreadBadge == true else {
            await badgeService.setBadgeCount(0)
            return
        }
        await applyUnreadCount()
    }

    /// Fetches the current unread count and applies it to the badge. Leaves the
    /// badge untouched on fetch errors (offline or logged out — the request fails
    /// and we keep the previous value rather than resetting it). Login state is
    /// deliberately not pre-checked here: it is derived from the request result,
    /// which is the single source of truth for whether the server is reachable.
    private func applyUnreadCount() async {
        do {
            let page = try await getBookmarksUseCase.execute(
                state: .unread,
                limit: 1,
                offset: 0,
                search: nil,
                type: nil,
                tag: nil,
                sort: nil
            )
            await badgeService.setBadgeCount(page.totalCount ?? 0)
        } catch {
            Logger.general.error("Unread badge refresh failed: \(error.localizedDescription)")
        }
    }
}
