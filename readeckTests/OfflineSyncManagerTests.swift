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

    // MARK: - Test: One Bad Item Does Not Block The Rest

    @Test("A single permanently failing item does not abort the rest")
    func testOneBadItemDoesNotBlockRest() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        for i in 1...3 {
            _ = mockCoreData.createTestBookmark(url: "https://example.com/\(i)", title: "Article \(i)")
        }

        // First call is a permanent (non-retryable) 400, the rest succeed.
        // fetchAllBookmarks is unsorted, so exactly one item fails regardless of order.
        mockAPI.createBookmarkResults = [
            .failure(APIError.serverError(400)),
            .success(mockSuccessResponse()),
            .success(mockSuccessResponse())
        ]

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(syncManager.isSyncing == false)
        // All 3 items attempted (no retry on the 400), 2 succeeded, 1 kept.
        #expect(mockAPI.createBookmarkCalls.count == 3)
        #expect(mockCoreData.fetchAllBookmarks().count == 1)
        #expect(syncManager.syncStatus?.contains("Synced 2, 1 kept for retry") == true)
    }

    // MARK: - Test: Retry On Transient Error Then Success

    @Test("Retries a transient error and then succeeds")
    func testRetryTransientThenSuccess() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        _ = mockCoreData.createTestBookmark(url: "https://example.com/1", title: "Article 1")

        mockAPI.createBookmarkResults = [
            .failure(APIError.serverError(503)),
            .success(mockSuccessResponse())
        ]

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(syncManager.isSyncing == false)
        #expect(mockAPI.createBookmarkCalls.count == 2)
        #expect(mockCoreData.fetchAllBookmarks().isEmpty)
        #expect(syncManager.syncStatus?.contains("Successfully synced 1") == true)
    }

    // MARK: - Test: Permanent Error Is Not Retried

    @Test("A permanent error is not retried and the item is kept")
    func testPermanentErrorNotRetried() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        _ = mockCoreData.createTestBookmark(url: "https://example.com/1", title: "Article 1")

        mockAPI.createBookmarkResults = [.failure(APIError.serverError(400))]

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(syncManager.isSyncing == false)
        #expect(mockAPI.createBookmarkCalls.count == 1)
        #expect(mockCoreData.fetchAllBookmarks().count == 1)
    }

    // MARK: - Test: Exhausted Retries Keep Item In Queue

    @Test("Exhausted retries keep the item in the queue")
    func testExhaustedRetriesKeepItem() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        _ = mockCoreData.createTestBookmark(url: "https://example.com/1", title: "Article 1")

        mockAPI.createBookmarkResults = Array(repeating: .failure(APIError.serverError(503)), count: 3)

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(syncManager.isSyncing == false)
        // 1 initial attempt + 2 retries.
        #expect(mockAPI.createBookmarkCalls.count == 3)
        #expect(mockCoreData.fetchAllBookmarks().count == 1)
    }

    // MARK: - Test: Connectivity Error Stops Early, Queue Intact

    @Test("Connectivity error on the first item stops early and keeps the whole queue")
    func testConnectivityErrorStopsEarly() async throws {
        let (syncManager, mockAPI, mockCoreData) = createTestEnvironment()

        for i in 1...3 {
            _ = mockCoreData.createTestBookmark(url: "https://example.com/\(i)", title: "Article \(i)")
        }

        // notConnectedToInternet is retryable AND a connectivity error, so the first
        // item is attempted 3 times (1 + 2 retries), then the whole run aborts.
        mockAPI.createBookmarkResults = Array(
            repeating: .failure(URLError(.notConnectedToInternet)),
            count: 3
        )

        await syncManager.syncOfflineBookmarks()
        try await Task.sleep(for: .milliseconds(100))

        #expect(syncManager.isSyncing == false)
        // Only the first item was touched (with retries); the other 2 were not attempted.
        #expect(mockAPI.createBookmarkCalls.count == 3)
        #expect(mockCoreData.fetchAllBookmarks().count == 3)
        #expect(syncManager.syncStatus?.hasPrefix("Server not reachable") == true)
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
        let syncManager = TestableOfflineSyncManager(api: mockAPI, coreDataManager: mockCoreData, retryBackoffBaseSeconds: 0)
        return (syncManager, mockAPI, mockCoreData)
    }

    private func mockSuccessResponse() -> CreateBookmarkResponseDto {
        CreateBookmarkResponseDto(message: "Bookmark created", status: 200)
    }
}
