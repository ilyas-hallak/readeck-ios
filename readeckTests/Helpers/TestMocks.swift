//
//  TestMocks.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Foundation
import CoreData
@testable import readeck

// MARK: - Mock API

@MainActor
class TestMockAPI: PAPI {
    var tokenProvider: TokenProvider = TestMockTokenProvider()

    var createBookmarkCalls: [(CreateBookmarkRequestDto, Result<CreateBookmarkResponseDto, Error>)] = []
    var createBookmarkResults: [Result<CreateBookmarkResponseDto, Error>] = []
    private var callIndex = 0

    func createBookmark(createRequest: CreateBookmarkRequestDto) async throws -> CreateBookmarkResponseDto {
        guard callIndex < createBookmarkResults.count else {
            throw APIError.serverError(500)
        }

        let result = createBookmarkResults[callIndex]
        callIndex += 1

        createBookmarkCalls.append((createRequest, result))

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func reset() {
        createBookmarkCalls.removeAll()
        callIndex = 0
    }

    // MARK: - Unimplemented Methods

    func login(endpoint: String, username: String, password: String) async throws -> UserDto {
        fatalError("Not implemented for tests")
    }

    func getBookmarks(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?, sort: String?) async throws -> BookmarksPageDto {
        fatalError("Not implemented for tests")
    }

    func getBookmark(id: String) async throws -> BookmarkDetailDto {
        fatalError("Not implemented for tests")
    }

    func getBookmarkArticle(id: String) async throws -> String {
        fatalError("Not implemented for tests")
    }

    func updateBookmark(id: String, updateRequest: UpdateBookmarkRequestDto) async throws {
        fatalError("Not implemented for tests")
    }

    func deleteBookmark(id: String) async throws {
        fatalError("Not implemented for tests")
    }

    func searchBookmarks(search: String) async throws -> BookmarksPageDto {
        fatalError("Not implemented for tests")
    }

    func getBookmarkLabels() async throws -> [BookmarkLabelDto] {
        fatalError("Not implemented for tests")
    }

    func getBookmarkAnnotations(bookmarkId: String) async throws -> [AnnotationDto] {
        fatalError("Not implemented for tests")
    }

    func createAnnotation(bookmarkId: String, color: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws -> AnnotationDto {
        fatalError("Not implemented for tests")
    }

    func deleteAnnotation(bookmarkId: String, annotationId: String) async throws {
        fatalError("Not implemented for tests")
    }

    func registerOAuthClient(endpoint: String, request: OAuthClientCreateDto) async throws -> OAuthClientResponseDto {
        fatalError("Not implemented for tests")
    }

    func exchangeOAuthToken(endpoint: String, request: OAuthTokenRequestDto) async throws -> OAuthTokenResponseDto {
        fatalError("Not implemented for tests")
    }
}

// MARK: - Mock Token Provider

class TestMockTokenProvider: TokenProvider {
    func getToken() async -> String? { return "mock-token" }
    func setToken(_ token: String) async {}
    func clearToken() async {}
    func getEndpoint() async -> String? { return "https://mock.example.com" }
    func setEndpoint(_ endpoint: String) async {}
    func clearEndpoint() async {}

    func getOAuthToken() async -> OAuthToken? { return nil }
    func setOAuthToken(_ token: OAuthToken) async {}
    func getAuthMethod() async -> AuthenticationMethod? { return .apiToken }
    func setAuthMethod(_ method: AuthenticationMethod) async {}
    func setOAuthClientId(_ clientId: String) async {}
    func getOAuthClientId() async -> String? { return nil }
}

// MARK: - Shared Test CoreData Model

/// A single model shared by every in-memory store in the tests.
///
/// Calling `NSManagedObjectModel.mergedModel(from:)` per instance creates several models
/// that all claim the same NSManagedObject subclass. CoreData can then no longer resolve
/// `+entity` ("Failed to find a unique match for an NSEntityDescription") and crashes on
/// save as soon as multiple CoreData suites run in the same process.
enum TestCoreDataModel {
    static let shared: NSManagedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
}

// MARK: - Test CoreData Manager

class TestCoreDataManager {
    let context: NSManagedObjectContext

    init() {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: TestCoreDataModel.shared)

        try! persistentStoreCoordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: nil,
            options: nil
        )

        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func createTestBookmark(url: String, title: String, tags: String? = nil) -> ArticleURLEntity {
        let entity = ArticleURLEntity(context: context)
        entity.url = url
        entity.title = title
        entity.tags = tags
        entity.id = UUID()

        try! context.save()
        return entity
    }

    func fetchAllBookmarks() -> [ArticleURLEntity] {
        let fetchRequest: NSFetchRequest<ArticleURLEntity> = ArticleURLEntity.fetchRequest()
        return (try? context.fetch(fetchRequest)) ?? []
    }

    func clearAll() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ArticleURLEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)
        try? context.save()
    }
}

// MARK: - Testable OfflineSyncManager

@MainActor
class TestableOfflineSyncManager: OfflineSyncManager {
    let mockCoreDataManager: TestCoreDataManager

    init(api: PAPI, coreDataManager: TestCoreDataManager, retryBackoffBaseSeconds: Double = 0) {
        self.mockCoreDataManager = coreDataManager
        super.init(api: api, retryBackoffBaseSeconds: retryBackoffBaseSeconds)
    }

    override func getOfflineBookmarks() -> [ArticleURLEntity] {
        return mockCoreDataManager.fetchAllBookmarks()
    }

    override func deleteOfflineBookmark(_ entity: ArticleURLEntity) {
        mockCoreDataManager.context.delete(entity)
        try? mockCoreDataManager.context.save()
    }
}