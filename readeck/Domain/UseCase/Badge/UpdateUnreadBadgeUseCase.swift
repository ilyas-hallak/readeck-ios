//
//  UpdateUnreadBadgeUseCase.swift
//  readeck
//
//  Business logic for the unread app-icon badge (opt-in, off by default).
//
//  The count mirrors the app's "Unread" tab (not archived, not favorited) and is
//  read cheaply from the `Total-Count` header via a `limit: 1` bookmarks request —
//  no dedicated endpoint or full fetch. Applying the value goes through the
//  `PAppBadgeService` output port, keeping the platform API out of the domain.
//

import Foundation

protocol PUpdateUnreadBadgeUseCase {
    /// Recomputes the unread badge from current settings and the server unread
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
        await applyUnreadCount(settings: settings)
    }

    /// Fetches the current unread count and applies it to the badge. Requires the
    /// user to be logged in; leaves the badge untouched on fetch errors (e.g. offline).
    private func applyUnreadCount(settings: Settings? = nil) async {
        let resolvedSettings: Settings?
        if let settings {
            resolvedSettings = settings
        } else {
            resolvedSettings = try? await settingsRepository.loadSettings()
        }
        guard resolvedSettings?.isLoggedIn == true else { return }

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
