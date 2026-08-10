//
//  BadgeManager.swift
//  readeck
//

import Foundation
import UserNotifications

/// Manages the app-icon badge that shows the number of unread bookmarks (opt-in, off by default).
///
/// The count mirrors the app's "Unread" tab (not archived, not favorited) and is read cheaply from
/// the `Total-Count` header via a `limit: 1` bookmarks request — no dedicated endpoint or full fetch.
/// Refresh is foreground-driven: on app resume / entering background and whenever a bookmark is
/// archived or deleted.
@MainActor
final class BadgeManager {
    static let shared = BadgeManager()

    private let factory: UseCaseFactory
    private let notificationCenter = UNUserNotificationCenter.current()

    init(factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.factory = factory
    }

    /// Applies the toggle state. When enabling, requests badge permission and returns whether the
    /// feature ended up enabled — the caller reverts the toggle if permission was denied.
    func setEnabled(_ enabled: Bool) async -> Bool {
        guard enabled else {
            await setBadge(0)
            return true
        }

        let granted = (try? await notificationCenter.requestAuthorization(options: [.badge])) ?? false
        guard granted else {
            Logger.viewModel.info("Unread badge: notification permission denied")
            return false
        }
        await refresh()
        return true
    }

    /// Recomputes and applies the badge from current settings and the server unread count.
    /// Clears the badge when the feature is off; leaves it untouched on fetch errors (e.g. offline).
    func refresh() async {
        let settings = try? await factory.makeSettingsRepository().loadSettings()

        guard settings?.showUnreadBadge == true else {
            await setBadge(0)
            return
        }
        guard settings?.isLoggedIn == true else { return }

        do {
            let page = try await factory.makeGetBookmarksUseCase().execute(
                state: .unread,
                limit: 1,
                offset: 0,
                search: nil,
                type: nil,
                tag: nil,
                sort: nil
            )
            await setBadge(page.totalCount ?? 0)
        } catch {
            Logger.viewModel.error("Unread badge refresh failed: \(error.localizedDescription)")
        }
    }

    private func setBadge(_ count: Int) async {
        do {
            try await notificationCenter.setBadgeCount(max(0, count))
        } catch {
            Logger.viewModel.error("Failed to set badge count: \(error.localizedDescription)")
        }
    }
}
