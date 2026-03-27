//
//  OfflineSettingsTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 21.11.25.
//

import Testing
import Foundation
@testable import readeck

@Suite("OfflineSettings Tests")
struct OfflineSettingsTests {

    // MARK: - Initialization Tests

    @Test("Default initialization has correct values")
    func testDefaultInitialization() {
        let settings = OfflineSettings()

        #expect(settings.enabled == false)
        #expect(settings.maxUnreadArticles == 20.0)
        #expect(settings.saveImages == false)
        #expect(settings.lastSyncDate == nil)
        #expect(settings.maxUnreadArticlesInt == 20)
    }

    // MARK: - maxUnreadArticlesInt Tests

    @Test("maxUnreadArticlesInt converts Double to Int correctly")
    func testMaxUnreadArticlesIntConversion() {
        var settings = OfflineSettings()

        settings.maxUnreadArticles = 15.0
        #expect(settings.maxUnreadArticlesInt == 15)

        settings.maxUnreadArticles = 50.7
        #expect(settings.maxUnreadArticlesInt == 50)

        settings.maxUnreadArticles = 99.9
        #expect(settings.maxUnreadArticlesInt == 99)
    }

    // MARK: - shouldSyncOnAppStart Tests

    @Test("shouldSyncOnAppStart returns false when disabled")
    func testShouldNotSyncWhenDisabled() {
        var settings = OfflineSettings()
        settings.enabled = false
        settings.lastSyncDate = nil // Never synced

        #expect(settings.shouldSyncOnAppStart == false)
    }

    @Test("shouldSyncOnAppStart returns true when never synced")
    func testShouldSyncWhenNeverSynced() {
        var settings = OfflineSettings()
        settings.enabled = true
        settings.lastSyncDate = nil

        #expect(settings.shouldSyncOnAppStart == true)
    }

    @Test("shouldSyncOnAppStart returns true when last sync was more than 4 hours ago")
    func testShouldSyncWhenLastSyncOlderThan4Hours() {
        var settings = OfflineSettings()
        settings.enabled = true

        // Test with 5 hours ago
        settings.lastSyncDate = Date().addingTimeInterval(-5 * 60 * 60)
        #expect(settings.shouldSyncOnAppStart == true)

        // Test with 4.5 hours ago
        settings.lastSyncDate = Date().addingTimeInterval(-4.5 * 60 * 60)
        #expect(settings.shouldSyncOnAppStart == true)

        // Test with exactly 4 hours + 1 second ago
        settings.lastSyncDate = Date().addingTimeInterval(-4 * 60 * 60 - 1)
        #expect(settings.shouldSyncOnAppStart == true)
    }

    @Test("shouldSyncOnAppStart returns false when last sync was less than 4 hours ago")
    func testShouldNotSyncWhenLastSyncWithin4Hours() {
        var settings = OfflineSettings()
        settings.enabled = true

        // Test with 3 hours ago
        settings.lastSyncDate = Date().addingTimeInterval(-3 * 60 * 60)
        #expect(settings.shouldSyncOnAppStart == false)

        // Test with 1 hour ago
        settings.lastSyncDate = Date().addingTimeInterval(-1 * 60 * 60)
        #expect(settings.shouldSyncOnAppStart == false)

        // Test with 1 minute ago
        settings.lastSyncDate = Date().addingTimeInterval(-60)
        #expect(settings.shouldSyncOnAppStart == false)

        // Test with just now
        settings.lastSyncDate = Date()
        #expect(settings.shouldSyncOnAppStart == false)
    }

    @Test("shouldSyncOnAppStart boundary test near 4 hours")
    func testShouldSyncBoundaryAt4Hours() {
        var settings = OfflineSettings()
        settings.enabled = true

        // Test slightly under 4 hours (3h 59m 30s) - should NOT sync
        settings.lastSyncDate = Date().addingTimeInterval(-3 * 60 * 60 - 59 * 60 - 30)
        #expect(settings.shouldSyncOnAppStart == false)

        // Test slightly over 4 hours (4h 0m 30s) - should sync
        settings.lastSyncDate = Date().addingTimeInterval(-4 * 60 * 60 - 30)
        #expect(settings.shouldSyncOnAppStart == true)
    }

    @Test("shouldSyncOnAppStart with future date edge case")
    func testShouldNotSyncWithFutureDate() {
        var settings = OfflineSettings()
        settings.enabled = true

        // Edge case: lastSyncDate in the future (clock skew/bug)
        settings.lastSyncDate = Date().addingTimeInterval(60 * 60) // 1 hour in future
        #expect(settings.shouldSyncOnAppStart == false)
    }

    // MARK: - Codable Tests

    @Test("OfflineSettings is encodable and decodable")
    func testCodableRoundTrip() throws {
        var original = OfflineSettings()
        original.enabled = false
        original.maxUnreadArticles = 35.0
        original.saveImages = true
        original.lastSyncDate = Date(timeIntervalSince1970: 1699999999)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OfflineSettings.self, from: data)

        #expect(decoded.enabled == original.enabled)
        #expect(decoded.maxUnreadArticles == original.maxUnreadArticles)
        #expect(decoded.saveImages == original.saveImages)
        #expect(decoded.lastSyncDate?.timeIntervalSince1970 == original.lastSyncDate?.timeIntervalSince1970)
    }

    @Test("OfflineSettings decodes with missing optional fields")
    func testDecodingWithMissingFields() throws {
        let json = """
        {
            "enabled": true,
            "maxUnreadArticles": 25.0,
            "saveImages": false
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let settings = try decoder.decode(OfflineSettings.self, from: data)

        #expect(settings.enabled == true)
        #expect(settings.maxUnreadArticles == 25.0)
        #expect(settings.saveImages == false)
        #expect(settings.lastSyncDate == nil)
    }

    // MARK: - Edge Cases

    @Test("maxUnreadArticles handles extreme values")
    func testMaxUnreadArticlesExtremeValues() {
        var settings = OfflineSettings()

        settings.maxUnreadArticles = 0.0
        #expect(settings.maxUnreadArticlesInt == 0)

        settings.maxUnreadArticles = 1000.0
        #expect(settings.maxUnreadArticlesInt == 1000)

        settings.maxUnreadArticles = 0.1
        #expect(settings.maxUnreadArticlesInt == 0)
    }
}
