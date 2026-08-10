import Testing
import Foundation
@testable import readeck

@Suite("UpdateUnreadBadgeUseCase")
struct UpdateUnreadBadgeUseCaseTests {

    // MARK: - Fakes

    private final class FakeBadgeService: PAppBadgeService {
        var authorizationGranted = true
        var lastBadgeCount: Int?
        var authorizationRequested = false

        func requestAuthorization() async -> Bool {
            authorizationRequested = true
            return authorizationGranted
        }
        func setBadgeCount(_ count: Int) async { lastBadgeCount = count }
    }

    private func makeSUT(
        settings: Settings?,
        totalCount: Int?,
        authorization: Bool = true
    ) -> (UpdateUnreadBadgeUseCase, FakeBadgeService) {
        let badge = FakeBadgeService()
        badge.authorizationGranted = authorization

        let settingsRepo = StubSettingsRepository()
        settingsRepo.stubbedSettings = settings

        let getBookmarks = ConfigurableGetBookmarksUseCase()
        getBookmarks.result = .success(
            BookmarksPage(bookmarks: [], currentPage: 1, totalCount: totalCount, totalPages: 1, links: nil)
        )

        let sut = UpdateUnreadBadgeUseCase(
            settingsRepository: settingsRepo,
            getBookmarksUseCase: getBookmarks,
            badgeService: badge
        )
        return (sut, badge)
    }

    // MARK: - refresh

    @Test("Enabled + logged in applies the server unread count")
    func refreshAppliesUnreadCount() async {
        let (sut, badge) = makeSUT(
            settings: Settings(token: "abc", showUnreadBadge: true),
            totalCount: 7
        )
        await sut.refresh()
        #expect(badge.lastBadgeCount == 7)
    }

    @Test("Feature off clears the badge")
    func refreshClearsWhenDisabled() async {
        let (sut, badge) = makeSUT(
            settings: Settings(token: "abc", showUnreadBadge: false),
            totalCount: 7
        )
        await sut.refresh()
        #expect(badge.lastBadgeCount == 0)
    }

    @Test("Enabled but logged out leaves the badge untouched")
    func refreshNoopWhenLoggedOut() async {
        let (sut, badge) = makeSUT(
            settings: Settings(token: nil, showUnreadBadge: true),
            totalCount: 7
        )
        await sut.refresh()
        #expect(badge.lastBadgeCount == nil)
    }

    // MARK: - setEnabled

    @Test("Enabling without permission returns false and does not set a count")
    func enableDeniedReturnsFalse() async {
        let (sut, badge) = makeSUT(
            settings: Settings(token: "abc", showUnreadBadge: true),
            totalCount: 7,
            authorization: false
        )
        let result = await sut.setEnabled(true)
        #expect(result == false)
        #expect(badge.authorizationRequested == true)
        #expect(badge.lastBadgeCount == nil)
    }

    @Test("Enabling applies the count even before the flag is persisted")
    func enableAppliesCountBeforeFlagPersisted() async {
        // Regression: setEnabled(true) must not gate on the stored showUnreadBadge,
        // which the caller persists only after this returns.
        let (sut, badge) = makeSUT(
            settings: Settings(token: "abc", showUnreadBadge: false),
            totalCount: 4
        )
        let result = await sut.setEnabled(true)
        #expect(result == true)
        #expect(badge.lastBadgeCount == 4)
    }

    @Test("Disabling clears the badge and returns true")
    func disableClears() async {
        let (sut, badge) = makeSUT(
            settings: Settings(token: "abc", showUnreadBadge: false),
            totalCount: 7
        )
        let result = await sut.setEnabled(false)
        #expect(result == true)
        #expect(badge.lastBadgeCount == 0)
    }
}

// MARK: - Stub settings repository (only loadSettings matters here)

private final class StubSettingsRepository: PSettingsRepository {
    var stubbedSettings: Settings?
    var hasFinishedSetup = true

    func loadSettings() async throws -> Settings? { stubbedSettings }

    func saveSettings(_ settings: Settings) async throws {}
    func clearSettings() async throws {}
    func saveToken(_ token: String) async throws {}
    func saveUsername(_ username: String) async throws {}
    func savePassword(_ password: String) async throws {}
    func saveHasFinishedSetup(_ hasFinishedSetup: Bool) async throws {}
    func saveServerSettings(endpoint: String, username: String, password: String, token: String) async throws {}
    func saveCardLayoutStyle(_ cardLayoutStyle: CardLayoutStyle) async throws {}
    func loadCardLayoutStyle() async throws -> CardLayoutStyle { .magazine }
    func saveTagSortOrder(_ tagSortOrder: TagSortOrder) async throws {}
    func loadTagSortOrder() async throws -> TagSortOrder { .byCount }
    func loadOfflineSettings() async throws -> OfflineSettings { OfflineSettings() }
    func saveOfflineSettings(_ settings: OfflineSettings) async throws {}
    func getCacheSize() async throws -> UInt { 0 }
    func getMaxCacheSize() async throws -> UInt { 0 }
    func updateMaxCacheSize(_ sizeInBytes: UInt) async throws {}
    func clearCache() async throws {}
}
