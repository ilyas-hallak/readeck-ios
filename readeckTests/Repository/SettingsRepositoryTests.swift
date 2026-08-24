//
//  SettingsRepositoryTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
@testable import readeck

/// Covers the CoreData- and UserDefaults-backed paths.
/// The keychain fields (endpoint/username/password/token) are left out on purpose:
/// `SettingsRepository` reaches for `KeychainHelper.shared` directly there, so a test
/// would touch the real device keychain.
@Suite("SettingsRepository Tests")
struct SettingsRepositoryTests {

    private func makeRepository() -> (SettingsRepository, UserDefaults) {
        let defaults = makeIsolatedUserDefaults()
        let repository = SettingsRepository(
            tokenProvider: RecordingTokenProvider(),
            coreDataManager: .inMemory(),
            userDefaults: defaults
        )
        return (repository, defaults)
    }

    // MARK: - UI Preferences Round-Trip

    @Test("saveSettings persists the UI preferences and loadSettings reads them back")
    func uiPreferencesRoundTrip() async throws {
        let (repository, _) = makeRepository()

        var settings = Settings()
        settings.fontFamily = .serif
        settings.fontSize = .large
        settings.theme = .dark
        settings.enableTTS = true
        settings.cardLayoutStyle = .compact
        settings.tagSortOrder = .alphabetically

        try await repository.saveSettings(settings)
        let loaded = try #require(try await repository.loadSettings())

        #expect(loaded.fontFamily == .serif)
        #expect(loaded.fontSize == .large)
        #expect(loaded.theme == .dark)
        #expect(loaded.enableTTS == true)
        #expect(loaded.cardLayoutStyle == .compact)
        #expect(loaded.tagSortOrder == .alphabetically)
    }

    @Test("loadSettings falls back to defaults on an empty store")
    func loadSettingsDefaults() async throws {
        let (repository, _) = makeRepository()

        let loaded = try #require(try await repository.loadSettings())

        #expect(loaded.fontFamily == .system)
        #expect(loaded.fontSize == .medium)
        #expect(loaded.theme == .system)
        #expect(loaded.cardLayoutStyle == .magazine)
        #expect(loaded.tagSortOrder == .byCount)
    }

    @Test("saveSettings updates the existing entity instead of adding a second one")
    func saveSettingsUpdatesInPlace() async throws {
        let (repository, _) = makeRepository()

        var first = Settings()
        first.fontSize = .small
        try await repository.saveSettings(first)

        var second = Settings()
        second.fontSize = .large
        try await repository.saveSettings(second)

        let loaded = try #require(try await repository.loadSettings())
        #expect(loaded.fontSize == .large)
    }

    // MARK: - Reader Styling Sentinels

    @Test("horizontalMargin 0 survives the round-trip, since 0 is a valid value")
    func horizontalMarginZeroIsPreserved() async throws {
        let (repository, defaults) = makeRepository()
        // Simulates an install where the one-time #103 repair already ran, so a deliberate
        // 0 is not mistaken for the old accidental default.
        defaults.set(true, forKey: "didResetAccidentalHorizontalMargin")

        var settings = Settings()
        settings.horizontalMargin = 0
        try await repository.saveSettings(settings)

        let loaded = try #require(try await repository.loadSettings())
        #expect(loaded.horizontalMargin == 0)
    }

    @Test("unset fontSizeNumeric and lineHeight come back as nil rather than 0")
    func unsetNumericValuesAreNil() async throws {
        let (repository, _) = makeRepository()

        try await repository.saveSettings(Settings())

        let loaded = try #require(try await repository.loadSettings())
        #expect(loaded.fontSizeNumeric == nil)
        #expect(loaded.lineHeight == nil)
    }

    // Regression test for #103: saving any setting must not silently pin the margin to 0,
    // otherwise the reader uses 0 instead of the intended 16
    // (see FontSettingsViewModel: `settings.horizontalMargin ?? 16`).
    @Test("an untouched horizontalMargin comes back as nil, not 0")
    func untouchedHorizontalMarginIsNil() async throws {
        let (repository, _) = makeRepository()

        try await repository.saveSettings(Settings())

        let loaded = try #require(try await repository.loadSettings())
        #expect(loaded.horizontalMargin == nil)
    }

    // MARK: - One-Time Repair (#103)

    @Test("a margin left at the old 0 default is repaired to unset on load")
    func repairResetsAccidentalZeroMargin() async throws {
        let (repository, _) = makeRepository()

        // Reproduces the old state: an entity that was written while the CoreData
        // default was still 0 and the slider was never touched.
        var settings = Settings()
        settings.horizontalMargin = 0
        try await repository.saveSettings(settings)

        let loaded = try #require(try await repository.loadSettings())
        #expect(loaded.horizontalMargin == nil)
    }

    @Test("the repair runs only once, so a deliberate 0 set afterwards is kept")
    func repairRunsOnlyOnce() async throws {
        let (repository, _) = makeRepository()

        try await repository.saveSettings(Settings())
        _ = try await repository.loadSettings()

        var settings = Settings()
        settings.horizontalMargin = 0
        try await repository.saveSettings(settings)

        let loaded = try #require(try await repository.loadSettings())
        #expect(loaded.horizontalMargin == 0)
    }

    // Guards the CoreData default itself. The tests above would also pass with the old
    // default of 0, because the repair would clean that up, so this one skips the repair.
    @Test("a freshly written entity starts out with the margin unset, without the repair")
    func modelDefaultMarksMarginUnset() async throws {
        let (repository, defaults) = makeRepository()
        defaults.set(true, forKey: "didResetAccidentalHorizontalMargin")

        try await repository.saveSettings(Settings())

        let loaded = try #require(try await repository.loadSettings())
        #expect(loaded.horizontalMargin == nil)
    }

    @Test("the repair records that it ran in the injected UserDefaults")
    func repairSetsItsFlag() async throws {
        let (repository, defaults) = makeRepository()

        #expect(defaults.bool(forKey: "didResetAccidentalHorizontalMargin") == false)

        _ = try await repository.loadSettings()

        #expect(defaults.bool(forKey: "didResetAccidentalHorizontalMargin") == true)
    }

    // MARK: - Card Layout / Tag Sort

    @Test("saveCardLayoutStyle and loadCardLayoutStyle round-trip")
    func cardLayoutRoundTrip() async throws {
        let (repository, _) = makeRepository()

        try await repository.saveCardLayoutStyle(.compact)

        #expect(try await repository.loadCardLayoutStyle() == .compact)
    }

    @Test("loadCardLayoutStyle defaults to magazine")
    func cardLayoutDefault() async throws {
        let (repository, _) = makeRepository()

        #expect(try await repository.loadCardLayoutStyle() == .magazine)
    }

    @Test("saveTagSortOrder and loadTagSortOrder round-trip")
    func tagSortRoundTrip() async throws {
        let (repository, _) = makeRepository()

        try await repository.saveTagSortOrder(.alphabetically)

        #expect(try await repository.loadTagSortOrder() == .alphabetically)
    }

    // MARK: - Offline Settings

    @Test("offline settings round-trip through CoreData")
    func offlineSettingsRoundTrip() async throws {
        let (repository, _) = makeRepository()
        let syncDate = Date(timeIntervalSince1970: 1_767_225_600)

        try await repository.saveOfflineSettings(
            OfflineSettings(enabled: true, maxUnreadArticles: 50, saveImages: true, lastSyncDate: syncDate)
        )

        let loaded = try await repository.loadOfflineSettings()
        #expect(loaded.enabled == true)
        #expect(loaded.maxUnreadArticles == 50)
        #expect(loaded.saveImages == true)
        #expect(loaded.lastSyncDate == syncDate)
    }

    @Test("offline settings default to disabled with 20 articles")
    func offlineSettingsDefaults() async throws {
        let (repository, _) = makeRepository()

        let loaded = try await repository.loadOfflineSettings()

        #expect(loaded.enabled == false)
        #expect(loaded.maxUnreadArticles == 20)
        #expect(loaded.lastSyncDate == nil)
    }

    // MARK: - UserDefaults-backed

    @Test("hasFinishedSetup is stored in the injected UserDefaults")
    func hasFinishedSetupUsesInjectedDefaults() async throws {
        let (repository, defaults) = makeRepository()

        #expect(repository.hasFinishedSetup == false)

        try await repository.saveHasFinishedSetup(true)

        #expect(repository.hasFinishedSetup == true)
        #expect(defaults.bool(forKey: "hasFinishedSetup") == true)
    }

    @Test("getMaxCacheSize returns and persists the 200 MB default")
    func maxCacheSizeDefault() async throws {
        let (repository, _) = makeRepository()

        let size = try await repository.getMaxCacheSize()

        #expect(size == UInt(200 * 1024 * 1024))
        // The second call reads the value that has now been persisted.
        #expect(try await repository.getMaxCacheSize() == size)
    }
}
