//
//  PAppBadgeService.swift
//  readeck
//
//  Output port for the app-icon badge. Abstracts the platform badge/notification
//  API so the domain layer stays free of UIKit/UserNotifications and can be tested
//  with a fake. Implemented in the data layer by `AppBadgeService`.
//

protocol PAppBadgeService {
    /// Requests permission to display a badge. Returns whether it was granted.
    func requestAuthorization() async -> Bool
    /// Sets the app-icon badge to `count` (values < 0 are clamped to 0).
    func setBadgeCount(_ count: Int) async
}
