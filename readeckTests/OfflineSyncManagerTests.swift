//
//  OfflineSyncManagerTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
@testable import readeck

@Suite("OfflineSyncManager Tests")
@MainActor
struct OfflineSyncManagerTests {

    // MARK: - Test: Empty Queue

    @Test("Should handle empty bookmark queue")
    func testEmptyQueue() async throws {
        let (syncManager, mockAPI, _) = createTestEnvironment()

        await syncManager.syncOfflineBookmarks()

        #expect(syncManager.isSyncing == false)
        #expect(syncManager.syncStatus == "No bookmarks to sync")
        #expect(mockAPI.createBookmarkCalls.isEmpty)
    }

    // MARK: - Test: Successful Sync

    @Test("Should successfully sync all bookmarks")
    func testSuccessfulSync() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        _ = mockCoreData.createTestBookmark(url: "https://example.com/1", title: "Article 1", tags: "tag1,tag2")
        _ = mockCoreData.createTestBookmark(url: "https://example.com/2", title: "Article 2")
        _ = mockCoreData.createTestBookmark(url: "https://example.com/3", title: "Article 3", tags: "tag3")

        mockAPI.createBookmarkResults = Array(repeating: .success(mockSuccessResponse()), count: 3)

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(syncManager.isSyncing == false)
        #expect(syncManager.syncStatus?.contains("Successfully synced 3 bookmarks") == true)
        #expect(mockAPI.createBookmarkCalls.count == 3)
        #expect(mockCoreData.fetchAllBookmarks().isEmpty)
    }

    // MARK: - Test: Server Unreachable

    @Test("Should abort on first failure (server unreachable)")
    func testServerUnreachable() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        _ = mockCoreData.createTestBookmark(url: "https://example.com/1", title: "Article 1")
        _ = mockCoreData.createTestBookmark(url: "https://example.com/2", title: "Article 2")
        _ = mockCoreData.createTestBookmark(url: "https://example.com/3", title: "Article 3")

        mockAPI.createBookmarkResults = [.failure(APIError.serverError(503))]

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(syncManager.isSyncing == false)
        #expect(syncManager.syncStatus == "Server not reachable. Cannot sync.")
        #expect(mockAPI.createBookmarkCalls.count == 1)
        #expect(mockCoreData.fetchAllBookmarks().count == 3)
    }

    // MARK: - Test: Partial Success

    @Test("Should handle partial sync success")
    func testPartialSuccess() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        for i in 1...4 {
            _ = mockCoreData.createTestBookmark(url: "https://example.com/\(i)", title: "Article \(i)")
        }

        mockAPI.createBookmarkResults = [
            .success(mockSuccessResponse()),
            .failure(APIError.serverError(400)),
            .success(mockSuccessResponse()),
            .failure(APIError.serverError(400))
        ]

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(syncManager.isSyncing == false)
        #expect(syncManager.syncStatus?.contains("Synced 2, failed 2") == true)
        #expect(mockAPI.createBookmarkCalls.count == 4)
        #expect(mockCoreData.fetchAllBookmarks().count == 2)
    }

    // MARK: - Test: Bookmark Without URL

    @Test("Should skip bookmarks without URL")
    func testBookmarkWithoutURL() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        let invalidEntity = ArticleURLEntity(context: mockCoreData.context)
        invalidEntity.url = nil
        invalidEntity.title = "Invalid Bookmark"
        try! mockCoreData.context.save()

        _ = mockCoreData.createTestBookmark(url: "https://example.com/1", title: "Valid Article")

        mockAPI.createBookmarkResults = [.success(mockSuccessResponse())]

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(syncManager.isSyncing == false)
        #expect(mockAPI.createBookmarkCalls.count == 1)
    }

    // MARK: - Test: Tags Parsing

    @Test("Should correctly parse and send tags")
    func testTagsParsing() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        _ = mockCoreData.createTestBookmark(url: "https://example.com/1", title: "Article", tags: "swift,ios,testing")

        mockAPI.createBookmarkResults = [.success(mockSuccessResponse())]

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(mockAPI.createBookmarkCalls.count == 1)
        #expect(mockAPI.createBookmarkCalls[0].0.labels == ["swift", "ios", "testing"])
    }

    // MARK: - Test: Empty Tags

    @Test("Should handle bookmarks without tags")
    func testEmptyTags() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        _ = mockCoreData.createTestBookmark(url: "https://example.com/1", title: "Article")

        mockAPI.createBookmarkResults = [.success(mockSuccessResponse())]

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(mockAPI.createBookmarkCalls.count == 1)
        #expect(mockAPI.createBookmarkCalls[0].0.labels == nil)
    }

    // MARK: - Test Helpers

    private func createTestEnvironment() -> (TestableOfflineSyncManager, TestMockAPI, TestCoreDataManager) {
        let mockAPI = TestMockAPI()
        let mockCoreData = TestCoreDataManager()
        let syncManager = TestableOfflineSyncManager(api: mockAPI, coreDataManager: mockCoreData)
        return (syncManager, mockAPI, mockCoreData)
    }

    private func mockSuccessResponse() -> CreateBookmarkResponseDto {
        CreateBookmarkResponseDto(message: "Bookmark created", status: 200)
    }
}
