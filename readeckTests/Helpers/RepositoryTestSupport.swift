//
//  RepositoryTestSupport.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Foundation
import CoreData
@testable import readeck

// MARK: - Stub API

/// PAPI-Stub mit Closure-Handlern statt `fatalError`-Platzhaltern.
/// Nicht gesetzte Handler werfen `notStubbed`, damit ein Test sofort zeigt,
/// welchen Aufruf er nicht erwartet hat.
final class StubAPI: PAPI, @unchecked Sendable {
    enum StubError: Error, Equatable {
        case notStubbed(String)
    }

    var tokenProvider: TokenProvider = TestMockTokenProvider()

    // swiftlint:disable:next discouraged_optional_collection
    var getBookmarksHandler: ((BookmarkState?, Int?, Int?, String?, [BookmarkType]?, String?, String?) async throws -> BookmarksPageDto)?
    var getBookmarkHandler: ((String) async throws -> BookmarkDetailDto)?
    var getBookmarkArticleHandler: ((String) async throws -> String)?
    var createBookmarkHandler: ((CreateBookmarkRequestDto) async throws -> CreateBookmarkResponseDto)?
    var updateBookmarkHandler: ((String, UpdateBookmarkRequestDto) async throws -> Void)?
    var deleteBookmarkHandler: ((String) async throws -> Void)?
    var searchBookmarksHandler: ((String) async throws -> BookmarksPageDto)?
    var getBookmarkLabelsHandler: (() async throws -> [BookmarkLabelDto])?
    var loginHandler: ((String, String, String) async throws -> UserDto)?

    // Aufzeichnungen für Assertions
    private(set) var updateBookmarkCalls: [(String, UpdateBookmarkRequestDto)] = []
    private(set) var deleteBookmarkCalls: [String] = []
    private(set) var createBookmarkCalls: [CreateBookmarkRequestDto] = []

    func login(endpoint: String, username: String, password: String) async throws -> UserDto {
        guard let loginHandler else { throw StubError.notStubbed("login") }
        return try await loginHandler(endpoint, username, password)
    }

    // swiftlint:disable:next discouraged_optional_collection
    func getBookmarks(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?, sort: String?) async throws -> BookmarksPageDto {
        guard let getBookmarksHandler else { throw StubError.notStubbed("getBookmarks") }
        return try await getBookmarksHandler(state, limit, offset, search, type, tag, sort)
    }

    func getBookmark(id: String) async throws -> BookmarkDetailDto {
        guard let getBookmarkHandler else { throw StubError.notStubbed("getBookmark") }
        return try await getBookmarkHandler(id)
    }

    func getBookmarkArticle(id: String) async throws -> String {
        guard let getBookmarkArticleHandler else { throw StubError.notStubbed("getBookmarkArticle") }
        return try await getBookmarkArticleHandler(id)
    }

    func createBookmark(createRequest: CreateBookmarkRequestDto) async throws -> CreateBookmarkResponseDto {
        createBookmarkCalls.append(createRequest)
        guard let createBookmarkHandler else { throw StubError.notStubbed("createBookmark") }
        return try await createBookmarkHandler(createRequest)
    }

    func updateBookmark(id: String, updateRequest: UpdateBookmarkRequestDto) async throws {
        updateBookmarkCalls.append((id, updateRequest))
        guard let updateBookmarkHandler else { throw StubError.notStubbed("updateBookmark") }
        try await updateBookmarkHandler(id, updateRequest)
    }

    func deleteBookmark(id: String) async throws {
        deleteBookmarkCalls.append(id)
        guard let deleteBookmarkHandler else { throw StubError.notStubbed("deleteBookmark") }
        try await deleteBookmarkHandler(id)
    }

    func searchBookmarks(search: String) async throws -> BookmarksPageDto {
        guard let searchBookmarksHandler else { throw StubError.notStubbed("searchBookmarks") }
        return try await searchBookmarksHandler(search)
    }

    func getBookmarkLabels() async throws -> [BookmarkLabelDto] {
        guard let getBookmarkLabelsHandler else { throw StubError.notStubbed("getBookmarkLabels") }
        return try await getBookmarkLabelsHandler()
    }

    func getBookmarkAnnotations(bookmarkId: String) async throws -> [AnnotationDto] { [] }

    func createAnnotation(bookmarkId: String, color: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws -> AnnotationDto {
        throw StubError.notStubbed("createAnnotation")
    }

    func deleteAnnotation(bookmarkId: String, annotationId: String) async throws {
        throw StubError.notStubbed("deleteAnnotation")
    }

    func registerOAuthClient(endpoint: String, request: OAuthClientCreateDto) async throws -> OAuthClientResponseDto {
        throw StubError.notStubbed("registerOAuthClient")
    }

    func exchangeOAuthToken(endpoint: String, request: OAuthTokenRequestDto) async throws -> OAuthTokenResponseDto {
        throw StubError.notStubbed("exchangeOAuthToken")
    }
}

// MARK: - Recording Token Provider

/// TokenProvider, der Schreibzugriffe im Speicher hält und mitschreibt.
final class RecordingTokenProvider: TokenProvider, @unchecked Sendable {
    private(set) var token: String?
    private(set) var endpoint: String?
    private(set) var oauthToken: OAuthToken?
    private(set) var authMethod: AuthenticationMethod?
    private(set) var oauthClientId: String?
    private(set) var clearTokenCallCount = 0

    init(token: String? = "existing-token", endpoint: String? = "https://mock.example.com") {
        self.token = token
        self.endpoint = endpoint
    }

    func getToken() async -> String? { token }
    func setToken(_ token: String) async { self.token = token }
    func clearToken() async {
        clearTokenCallCount += 1
        token = nil
    }
    func getEndpoint() async -> String? { endpoint }
    func setEndpoint(_ endpoint: String) async { self.endpoint = endpoint }
    func clearEndpoint() async { endpoint = nil }

    func getOAuthToken() async -> OAuthToken? { oauthToken }
    func setOAuthToken(_ token: OAuthToken) async { oauthToken = token }
    func getAuthMethod() async -> AuthenticationMethod? { authMethod }
    func setAuthMethod(_ method: AuthenticationMethod) async { authMethod = method }
    func setOAuthClientId(_ clientId: String) async { oauthClientId = clientId }
    func getOAuthClientId() async -> String? { oauthClientId }
}

// MARK: - Recording Settings Repository

/// PSettingsRepository-Double, das gespeicherte Settings festhält.
/// `MockSettingsRepository` aus dem App-Target hat feste Rückgaben und zeichnet nichts auf.
final class RecordingSettingsRepository: PSettingsRepository, @unchecked Sendable {
    var storedSettings: Settings?
    var loadSettingsError: Error?
    private(set) var savedSettings: [Settings] = []

    var hasFinishedSetup = true

    init(storedSettings: Settings? = Settings()) {
        self.storedSettings = storedSettings
    }

    func saveSettings(_ settings: Settings) async throws {
        savedSettings.append(settings)
        storedSettings = settings
    }

    func loadSettings() async throws -> Settings? {
        if let loadSettingsError { throw loadSettingsError }
        return storedSettings
    }

    func clearSettings() async throws { storedSettings = nil }
    func saveToken(_ token: String) async throws {}
    func saveUsername(_ username: String) async throws {}
    func savePassword(_ password: String) async throws {}
    func saveHasFinishedSetup(_ hasFinishedSetup: Bool) async throws { self.hasFinishedSetup = hasFinishedSetup }
    func saveServerSettings(endpoint: String, username: String, password: String, token: String) async throws {}
    func saveCardLayoutStyle(_ cardLayoutStyle: CardLayoutStyle) async throws {}
    func loadCardLayoutStyle() async throws -> CardLayoutStyle { .magazine }
    func saveTagSortOrder(_ tagSortOrder: TagSortOrder) async throws {}
    func loadTagSortOrder() async throws -> TagSortOrder { .byCount }
    func loadOfflineSettings() async throws -> OfflineSettings { OfflineSettings() }
    func saveOfflineSettings(_ settings: OfflineSettings) async throws {}
    func getCacheSize() async throws -> UInt { 0 }
    func getMaxCacheSize() async throws -> UInt { 200 * 1024 * 1024 }
    func updateMaxCacheSize(_ sizeInBytes: UInt) async throws {}
    func clearCache() async throws {}
    func applyCacheSizeLimit() async throws {}
}

// MARK: - Stub GetUserProfileUseCase

final class StubGetUserProfileUseCase: PGetUserProfileUseCase, @unchecked Sendable {
    var result: Result<String, Error>

    init(username: String = "ilyas") {
        self.result = .success(username)
    }

    func execute() async throws -> String {
        try result.get()
    }
}

// MARK: - OAuth Fixtures

extension OAuthToken {
    static func fixture(
        accessToken: String = "access-123",
        refreshToken: String? = "refresh-123",
        expiresIn: Int? = 3600
    ) -> OAuthToken {
        OAuthToken(
            accessToken: accessToken,
            tokenType: "Bearer",
            scope: nil,
            expiresIn: expiresIn,
            refreshToken: refreshToken,
            createdAt: Date(timeIntervalSince1970: 1_767_225_600)
        )
    }
}

// MARK: - In-Memory CoreDataManager

extension CoreDataManager {
    /// CoreDataManager auf einem In-Memory-Store, für Repositories die den Manager injiziert bekommen.
    static func inMemory() -> CoreDataManager {
        let container = NSPersistentContainer(name: "readeck", managedObjectModel: TestCoreDataModel.shared)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            precondition(error == nil, "In-memory store failed to load: \(String(describing: error))")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return CoreDataManager(container: container)
    }
}

// MARK: - Isolated UserDefaults

/// UserDefaults in einer eigenen Suite, damit Tests sich nicht gegenseitig
/// und nicht die echten App-Einstellungen beeinflussen.
func makeIsolatedUserDefaults(suiteName: String = UUID().uuidString) -> UserDefaults {
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        preconditionFailure("Could not create UserDefaults suite \(suiteName)")
    }
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

// MARK: - DTO Fixtures

enum DtoFixture {
    static func bookmark(
        id: String = "bm1",
        title: String = "Test Bookmark",
        labels: [String] = [],
        isArchived: Bool = false,
        isMarked: Bool = false,
        readProgress: Int = 0
    ) -> BookmarkDto {
        BookmarkDto(
            id: id,
            title: title,
            url: "https://example.com/\(id)",
            href: "https://api.example.com/bookmarks/\(id)",
            description: "A description",
            authors: ["Author"],
            created: "2026-01-01T00:00:00Z",
            published: nil,
            updated: "2026-01-02T00:00:00Z",
            siteName: "Example",
            site: "example.com",
            readingTime: 5,
            wordCount: 1000,
            hasArticle: true,
            isArchived: isArchived,
            isDeleted: false,
            isMarked: isMarked,
            labels: labels,
            lang: "en",
            loaded: true,
            readProgress: readProgress,
            documentType: "article",
            state: 0,
            textDirection: "ltr",
            type: "article",
            resources: BookmarkResourcesDto(
                article: ResourceDto(src: "https://example.com/\(id)/article"),
                icon: nil,
                image: ImageResourceDto(src: "https://example.com/\(id)/image.jpg", height: 600, width: 800),
                log: nil,
                props: nil,
                thumbnail: ImageResourceDto(src: "https://example.com/\(id)/thumb.jpg", height: 150, width: 200)
            )
        )
    }

    static func page(
        bookmarks: [BookmarkDto],
        currentPage: Int? = 1,
        totalCount: Int? = nil,
        totalPages: Int? = 1
    ) -> BookmarksPageDto {
        BookmarksPageDto(
            bookmarks: bookmarks,
            currentPage: currentPage,
            totalCount: totalCount ?? bookmarks.count,
            totalPages: totalPages,
            links: nil
        )
    }
}
