//
//  AppBadgeService.swift
//  readeck
//
//  Data-layer implementation of `PAppBadgeService` backed by UserNotifications.
//

import Foundation
import UserNotifications

final class AppBadgeService: PAppBadgeService {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.badge])
        } catch {
            Logger.data.error("Failed to request badge authorization: \(error.localizedDescription)")
            return false
        }
    }

    func setBadgeCount(_ count: Int) async {
        do {
            try await notificationCenter.setBadgeCount(max(0, count))
        } catch {
            Logger.data.error("Failed to set badge count: \(error.localizedDescription)")
        }
    }
}
