//
//  SettingsRepositoryTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
@testable import readeck

/// Deckt die CoreData- und UserDefaults-gestützten Pfade ab.
/// Die Keychain-Felder (endpoint/username/password/token) bleiben ausgespart:
/// `SettingsRepository` greift dafür fest auf `KeychainHelper.shared` zu, ein Test
/// würde den echten Keychain des Geräts anfassen.
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
        let (repository, _) = makeRepository()

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

    // Dokumentiert das Ist-Verhalten, nicht das gewünschte:
    // loadSettings behandelt einen negativen horizontalMargin als "nicht gesetzt",
    // der CoreData-Default des Attributs ist aber 0. Sobald irgendeine Einstellung
    // gespeichert wurde, existiert die SettingEntity und der Margin kommt als 0
    // zurück statt als nil - der Reader nutzt dann 0 statt der gewollten 16
    // (siehe FontSettingsViewModel: `settings.horizontalMargin ?? 16`).
    @Test("known quirk: an untouched horizontalMargin reads back as 0, not nil")
    func untouchedHorizontalMarginReadsAsZero() async throws {
        let (repository, _) = makeRepository()

        try await repository.saveSettings(Settings())

        let loaded = try #require(try await repository.loadSettings())
        #expect(loaded.horizontalMargin == 0)
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
        // Zweiter Aufruf liest den nun persistierten Wert.
        #expect(try await repository.getMaxCacheSize() == size)
    }
}
