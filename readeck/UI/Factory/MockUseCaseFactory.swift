//
//  MockUseCaseFactory.swift
//  readeck
//
//  Created by Ilyas Hallak on 18.07.25.
//

import Foundation
import Combine

class MockUseCaseFactory: UseCaseFactory {
    func makeGetCachedBookmarksUseCase() -> any PGetCachedBookmarksUseCase {
        MockGetCachedBookmarksUseCase()
    }
    
    func makeGetCachedArticleUseCase() -> any PGetCachedArticleUseCase {
        MockGetCachedArticleUseCase()
    }
    
    func makeCreateAnnotationUseCase() -> any PCreateAnnotationUseCase {
        MockCreateAnnotationUseCase()
    }
    
    func makeCheckServerReachabilityUseCase() -> any PCheckServerReachabilityUseCase {
        MockCheckServerReachabilityUseCase()
    }

    func makeGetServerInfoUseCase() -> any PGetServerInfoUseCase {
        MockGetServerInfoUseCase()
    }

    func makeOfflineBookmarkSyncUseCase() -> any POfflineBookmarkSyncUseCase {
        MockOfflineBookmarkSyncUseCase()
    }
    
    func makeLoginUseCase() -> any PLoginUseCase {
        MockLoginUserCase()
    }
    
    func makeGetBookmarksUseCase() -> any PGetBookmarksUseCase {
        MockGetBookmarksUseCase()
    }
    
    func makeGetBookmarkUseCase() -> any PGetBookmarkUseCase {
        MockGetBookmarkUseCase()
    }
    
    func makeGetBookmarkArticleUseCase() -> any PGetBookmarkArticleUseCase {
        MockGetBookmarkArticleUseCase()
    }
    
    func makeSaveSettingsUseCase() -> any PSaveSettingsUseCase {
        MockSaveSettingsUseCase()
    }
    
    func makeLoadSettingsUseCase() -> any PLoadSettingsUseCase {
        MockLoadSettingsUseCase()
    }
    
    func makeUpdateBookmarkUseCase() -> any PUpdateBookmarkUseCase {
        MockUpdateBookmarkUseCase()
    }
    
    func makeDeleteBookmarkUseCase() -> any PDeleteBookmarkUseCase {
        MockDeleteBookmarkUseCase()
    }
    
    func makeCreateBookmarkUseCase() -> any PCreateBookmarkUseCase {
        MockCreateBookmarkUseCase()
    }
    
    func makeLogoutUseCase() -> any PLogoutUseCase {
        MockLogoutUseCase()
    }
    
    func makeSearchBookmarksUseCase() -> any PSearchBookmarksUseCase {
        MockSearchBookmarksUseCase()
    }
    
    func makeSaveServerSettingsUseCase() -> any PSaveServerSettingsUseCase {
        MockSaveServerSettingsUseCase()
    }
    
    func makeAddLabelsToBookmarkUseCase() -> any PAddLabelsToBookmarkUseCase {
        MockAddLabelsToBookmarkUseCase()
    }
    
    func makeRemoveLabelsFromBookmarkUseCase() -> any PRemoveLabelsFromBookmarkUseCase {
        MockRemoveLabelsFromBookmarkUseCase()
    }
    
    func makeGetLabelsUseCase() -> any PGetLabelsUseCase {
        MockGetLabelsUseCase()
    }

    func makeCreateLabelUseCase() -> any PCreateLabelUseCase {
        MockCreateLabelUseCase()
    }

    func makeSyncTagsUseCase() -> any PSyncTagsUseCase {
        MockSyncTagsUseCase()
    }

    func makeAddTextToSpeechQueueUseCase() -> any PAddTextToSpeechQueueUseCase {
        MockAddTextToSpeechQueueUseCase()
    }
    
    func makeLoadCardLayoutUseCase() -> PLoadCardLayoutUseCase {
        MockLoadCardLayoutUseCase()
    }
    
    func makeSaveCardLayoutUseCase() -> PSaveCardLayoutUseCase {
        MockSaveCardLayoutUseCase()
    }

    func makeGetBookmarkAnnotationsUseCase() -> PGetBookmarkAnnotationsUseCase {
        MockGetBookmarkAnnotationsUseCase()
    }

    func makeDeleteAnnotationUseCase() -> PDeleteAnnotationUseCase {
        MockDeleteAnnotationUseCase()
    }

    func makeSettingsRepository() -> PSettingsRepository {
        MockSettingsRepository()
    }

    func makeOfflineCacheSyncUseCase() -> POfflineCacheSyncUseCase {
        MockOfflineCacheSyncUseCase()
    }

    func makeNetworkMonitorUseCase() -> PNetworkMonitorUseCase {
        MockNetworkMonitorUseCase()
    }

    func makeGetCacheSizeUseCase() -> PGetCacheSizeUseCase {
        MockGetCacheSizeUseCase()
    }

    func makeGetMaxCacheSizeUseCase() -> PGetMaxCacheSizeUseCase {
        MockGetMaxCacheSizeUseCase()
    }

    func makeUpdateMaxCacheSizeUseCase() -> PUpdateMaxCacheSizeUseCase {
        MockUpdateMaxCacheSizeUseCase()
    }

    func makeClearCacheUseCase() -> PClearCacheUseCase {
        MockClearCacheUseCase()
    }
}
    

// MARK: Mocked Use Cases

class MockLoginUserCase: PLoginUseCase {
    func execute(endpoint: String, username: String, password: String) async throws -> User {
        return User(id: "123", token: "abc")
    }
}

class MockLogoutUseCase: PLogoutUseCase {
    func execute() async throws {}
}

class MockCreateBookmarkUseCase: PCreateBookmarkUseCase {
    func execute(createRequest: CreateBookmarkRequest) async throws -> String { "mock-bookmark-id" }
    func createFromURL(_ url: String) async throws -> String { "mock-bookmark-id" }
    func createFromURLWithTitle(_ url: String, title: String) async throws -> String { "mock-bookmark-id" }
    func createFromURLWithLabels(_ url: String, labels: [String]) async throws -> String { "mock-bookmark-id" }
    func createFromClipboard() async throws -> String? { "mock-bookmark-id" }
}

class MockGetLabelsUseCase: PGetLabelsUseCase {
    func execute() async throws -> [BookmarkLabel] {
        [BookmarkLabel(name: "Test", count: 1, href: "mock-href")]
    }
}

class MockCreateLabelUseCase: PCreateLabelUseCase {
    func execute(name: String) async throws {
        // Mock implementation - does nothing
    }
}

class MockSyncTagsUseCase: PSyncTagsUseCase {
    func execute() async throws {
        // Mock implementation - does nothing
    }
}

class MockSearchBookmarksUseCase: PSearchBookmarksUseCase {
    func execute(search: String) async throws -> BookmarksPage {
        BookmarksPage(bookmarks: [], currentPage: 1, totalCount: 0, totalPages: 1, links: nil)
    }
}

class MockReadBookmarkUseCase: PReadBookmarkUseCase {
    func execute(bookmarkDetail: BookmarkDetail) {}
}

class MockGetBookmarksUseCase: PGetBookmarksUseCase {
    func execute(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?) async throws -> BookmarksPage {
        BookmarksPage(bookmarks: [
            Bookmark.mock
        ], currentPage: 1, totalCount: 0, totalPages: 1, links: nil)
    }
}

class MockUpdateBookmarkUseCase: PUpdateBookmarkUseCase {
    func execute(bookmarkId: String, updateRequest: BookmarkUpdateRequest) async throws {}
    func toggleArchive(bookmarkId: String, isArchived: Bool) async throws {}
    func toggleFavorite(bookmarkId: String, isMarked: Bool) async throws {}
    func markAsDeleted(bookmarkId: String) async throws {}
    func updateReadProgress(bookmarkId: String, progress: Int, anchor: String?) async throws {}
    func updateTitle(bookmarkId: String, title: String) async throws {}
    func updateLabels(bookmarkId: String, labels: [String]) async throws {}
    func addLabels(bookmarkId: String, labels: [String]) async throws {}
    func removeLabels(bookmarkId: String, labels: [String]) async throws {}
}

class MockSaveSettingsUseCase: PSaveSettingsUseCase {
    func execute(endpoint: String, username: String, password: String) async throws {}
    func execute(endpoint: String, username: String, password: String, hasFinishedSetup: Bool) async throws {}
    func execute(token: String) async throws {}
    func execute(selectedFontFamily: FontFamily, selectedFontSize: FontSize) async throws {}
    func execute(selectedFontFamily: FontFamily, fontSizeNumeric: Double) async throws {}
    func execute(readerLayout horizontalMargin: Double, lineHeight: Double) async throws {}
    func execute(readerVisibility hideProgressBar: Bool, hideWordCount: Bool, hideHeroImage: Bool) async throws {}
    func execute(customCSS: String) async throws {}
    func execute(enableTTS: Bool) async throws {}
    func execute(theme: Theme) async throws {}
    func execute(urlOpener: UrlOpener) async throws {}
}

class MockGetBookmarkUseCase: PGetBookmarkUseCase {
    func execute(id: String) async throws -> BookmarkDetail {
        BookmarkDetail(id: "123", title: "Test", url: "https://www.google.com", description: "Test", siteName: "Test", authors: ["Test"], created: "2021-01-01", updated: "2021-01-01", wordCount: 100, readingTime: 100, hasArticle: true, isMarked: false, isArchived: false, labels: ["Test"], thumbnailUrl: "https://picsum.photos/30/30", imageUrl: "https://picsum.photos/400/400", lang: "en", readProgress: 0)
    }
}

class MockLoadSettingsUseCase: PLoadSettingsUseCase {
    func execute() async throws -> Settings? {
        Settings(endpoint: "mock-endpoint", username: "mock-user", password: "mock-pw", token: "mock-token", fontFamily: .system, fontSize: .medium, hasFinishedSetup: true)
    }
}

class MockDeleteBookmarkUseCase: PDeleteBookmarkUseCase {
    func execute(bookmarkId: String) async throws {}
}

class MockGetBookmarkArticleUseCase: PGetBookmarkArticleUseCase {
    func execute(id: String) async throws -> String { 
        let path = Bundle.main.path(forResource: "article", ofType: "html")
        return try String(contentsOfFile: path!)
    }
}

class MockAddLabelsToBookmarkUseCase: PAddLabelsToBookmarkUseCase {
    func execute(bookmarkId: String, labels: [String]) async throws {}
    func execute(bookmarkId: String, label: String) async throws {}
}

class MockRemoveLabelsFromBookmarkUseCase: PRemoveLabelsFromBookmarkUseCase {
    func execute(bookmarkId: String, labels: [String]) async throws {}
    func execute(bookmarkId: String, label: String) async throws {}
}

class MockSaveServerSettingsUseCase: PSaveServerSettingsUseCase {
    func execute(endpoint: String, username: String, password: String, token: String) async throws {}
}

class MockAddTextToSpeechQueueUseCase: PAddTextToSpeechQueueUseCase {
    func execute(bookmarkDetail: BookmarkDetail) {}
}

class MockOfflineBookmarkSyncUseCase: POfflineBookmarkSyncUseCase {
    var isSyncing: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
    
    var syncStatus: AnyPublisher<String?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
    
    func getOfflineBookmarksCount() -> Int {
        return 0
    }
    
    func syncOfflineBookmarks() async {
        // Mock implementation - do nothing
    }
}

class MockLoadCardLayoutUseCase: PLoadCardLayoutUseCase {
    func execute() async -> CardLayoutStyle {
        return .magazine
    }
}

class MockSaveCardLayoutUseCase: PSaveCardLayoutUseCase {
    func execute(layout: CardLayoutStyle) async {
        // Mock implementation - do nothing
    }
}

class MockCheckServerReachabilityUseCase: PCheckServerReachabilityUseCase {
    func execute() async -> Bool {
        return true
    }

    func getServerInfo() async throws -> ServerInfo {
        return ServerInfo(version: "1.0.0", isReachable: true, features: [])
    }
}

class MockGetServerInfoUseCase: PGetServerInfoUseCase {
    func execute(endpoint: String? = nil) async throws -> ServerInfo {
        return ServerInfo(version: "1.0.0", isReachable: true, features: ["oauth"])
    }
}

class MockGetBookmarkAnnotationsUseCase: PGetBookmarkAnnotationsUseCase {
    func execute(bookmarkId: String) async throws -> [Annotation] {
        return [
            .init(id: "1", text: "bla", created: "", startOffset: 0, endOffset: 1, startSelector: "", endSelector: "")
        ]
    }
}

class MockDeleteAnnotationUseCase: PDeleteAnnotationUseCase {
    func execute(bookmarkId: String, annotationId: String) async throws {
        // Mock implementation - do nothing
    }
}

class MockSettingsRepository: PSettingsRepository {
    var hasFinishedSetup: Bool = true

    func saveSettings(_ settings: Settings) async throws {}
    func loadSettings() async throws -> Settings? {
        return Settings(endpoint: "mock-endpoint", username: "mock-user", password: "mock-pw", token: "mock-token", fontFamily: .system, fontSize: .medium, hasFinishedSetup: true)
    }
    func clearSettings() async throws {}
    func saveToken(_ token: String) async throws {}
    func saveUsername(_ username: String) async throws {}
    func savePassword(_ password: String) async throws {}
    func saveHasFinishedSetup(_ hasFinishedSetup: Bool) async throws {}
    func saveServerSettings(endpoint: String, username: String, password: String, token: String) async throws {}
    func saveCardLayoutStyle(_ cardLayoutStyle: CardLayoutStyle) async throws {}
    func loadCardLayoutStyle() async throws -> CardLayoutStyle { return .magazine }
    func saveTagSortOrder(_ tagSortOrder: TagSortOrder) async throws {}
    func loadTagSortOrder() async throws -> TagSortOrder { return .byCount }
    func loadOfflineSettings() async throws -> OfflineSettings {
        return OfflineSettings()
    }
    func saveOfflineSettings(_ settings: OfflineSettings) async throws {}
    func getCacheSize() async throws -> UInt { return 0 }
    func getMaxCacheSize() async throws -> UInt { return 200 * 1024 * 1024 }
    func updateMaxCacheSize(_ sizeInBytes: UInt) async throws {}
    func clearCache() async throws {}
}

class MockOfflineCacheSyncUseCase: POfflineCacheSyncUseCase {
    var isSyncing: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }

    var syncProgress: AnyPublisher<String?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    func syncOfflineArticles(settings: OfflineSettings) async {}

    func getCachedArticlesCount() -> Int {
        return 0
    }

    func getCacheSize() -> String {
        return "0 KB"
    }
}

class MockNetworkMonitorRepository: PNetworkMonitorRepository {
    var isConnected: AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }

    func startMonitoring() {}
    func stopMonitoring() {}
    func reportConnectionFailure() {}
    func reportConnectionSuccess() {}
}

class MockNetworkMonitorUseCase: PNetworkMonitorUseCase {
    private let repository: PNetworkMonitorRepository

    init(repository: PNetworkMonitorRepository = MockNetworkMonitorRepository()) {
        self.repository = repository
    }

    var isConnected: AnyPublisher<Bool, Never> {
        repository.isConnected
    }

    func startMonitoring() {
        repository.startMonitoring()
    }

    func stopMonitoring() {
        repository.stopMonitoring()
    }

    func reportConnectionFailure() {
        repository.reportConnectionFailure()
    }

    func reportConnectionSuccess() {
        repository.reportConnectionSuccess()
    }
}

class MockGetCachedBookmarksUseCase: PGetCachedBookmarksUseCase {
    func execute() async throws -> [Bookmark] {
        return [Bookmark.mock]
    }
}

class MockGetCachedArticleUseCase: PGetCachedArticleUseCase {
    func execute(id: String) -> String? {
        let path = Bundle.main.path(forResource: "article", ofType: "html")
        return try? String(contentsOfFile: path!)
    }
}

class MockCreateAnnotationUseCase: PCreateAnnotationUseCase {
    func execute(bookmarkId: String, color: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws -> Annotation {
        return Annotation(id: "", text: "", created: "", startOffset: 0, endOffset: 1, startSelector: "", endSelector: "")
            
            
    }
    
    func execute(bookmarkId: String, text: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws {
        // Mock implementation - do nothing
    }
}

extension Bookmark {
    static let mock: Bookmark = .init(
        id: "123", title: "title", url: "https://example.com", href: "https://example.com", description: "description", authors: ["Tom"], created: "", published: "", updated: "", siteName: "example.com", site: "https://example.com", readingTime: 2, wordCount: 20, hasArticle: true, isArchived: false, isDeleted: false, isMarked: true, labels: ["Test"], lang: "EN", loaded: false, readProgress: 0, documentType: "", state: 0, textDirection: "ltr", type: "", resources: .init(article: nil, icon: nil, image: nil, log: nil, props: nil, thumbnail: nil)
    )
}

class MockGetCacheSizeUseCase: PGetCacheSizeUseCase {
    func execute() async throws -> UInt {
        return 0
    }
}

class MockGetMaxCacheSizeUseCase: PGetMaxCacheSizeUseCase {
    func execute() async throws -> UInt {
        return 200 * 1024 * 1024
    }
}

class MockUpdateMaxCacheSizeUseCase: PUpdateMaxCacheSizeUseCase {
    func execute(sizeInBytes: UInt) async throws {}
}

class MockClearCacheUseCase: PClearCacheUseCase {
    func execute() async throws {}
}

// MARK: - OAuth Mock Extensions
extension MockUseCaseFactory {
    func makeLoginWithOAuthUseCase() -> PLoginWithOAuthUseCase {
        MockLoginWithOAuthUseCase()
    }

    func makeAuthRepository() -> PAuthRepository {
        MockAuthRepository()
    }
}

class MockLoginWithOAuthUseCase: PLoginWithOAuthUseCase {
    func execute(endpoint: String) async throws -> (OAuthToken, String) {
        let token = OAuthToken(
            accessToken: "mock_access_token",
            tokenType: "Bearer",
            scope: "read write",
            expiresIn: 3600,
            refreshToken: "mock_refresh_token",
            createdAt: Date()
        )
        return (token, "mock_client_id")
    }
}

class MockAuthRepository: PAuthRepository {
    func login(endpoint: String, username: String, password: String) async throws -> User {
        return User(id: "mock_user", token: "mock_token")
    }

    func logout() async throws {}

    func getCurrentSettings() async throws -> Settings? {
        return nil
    }

    func loginWithOAuth(endpoint: String, token: OAuthToken, clientId: String) async throws {
        // Mock: No need to fetch profile in mock
    }

    func getAuthenticationMethod() async -> AuthenticationMethod? {
        return .apiToken
    }

    func switchToClassicAuth(endpoint: String, username: String, password: String) async throws -> User {
        return User(id: "mock_user", token: "mock_token")
    }
}
