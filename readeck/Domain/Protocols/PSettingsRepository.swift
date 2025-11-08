//
//  PSettingsRepository.swift
//  readeck
//
//  Created by Claude on 08.11.25.
//

import Foundation

protocol PSettingsRepository {
    // Existing Settings methods
    func saveSettings(_ settings: Settings) async throws
    func loadSettings() async throws -> Settings?
    func clearSettings() async throws
    func saveToken(_ token: String) async throws
    func saveUsername(_ username: String) async throws
    func savePassword(_ password: String) async throws
    func saveHasFinishedSetup(_ hasFinishedSetup: Bool) async throws
    func saveServerSettings(endpoint: String, username: String, password: String, token: String) async throws
    func saveCardLayoutStyle(_ cardLayoutStyle: CardLayoutStyle) async throws
    func loadCardLayoutStyle() async throws -> CardLayoutStyle
    func saveTagSortOrder(_ tagSortOrder: TagSortOrder) async throws
    func loadTagSortOrder() async throws -> TagSortOrder
    var hasFinishedSetup: Bool { get }

    // Offline Settings methods
    func loadOfflineSettings() async throws -> OfflineSettings
    func saveOfflineSettings(_ settings: OfflineSettings) async throws
}
