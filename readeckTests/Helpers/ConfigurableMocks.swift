import Foundation
import Testing
@testable import readeck

// MARK: - Configurable Mock Use Cases

class ConfigurableGetBookmarksUseCase: PGetBookmarksUseCase {
    var result: Result<BookmarksPage, Error> = .success(
        BookmarksPage(bookmarks: [.mock], currentPage: 1, totalCount: 1, totalPages: 1, links: nil)
    )
    var executeCalled = false
    var lastState: BookmarkState?

    // swiftlint:disable:next discouraged_optional_collection
    func execute(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?, sort: String?) async throws -> BookmarksPage {
        executeCalled = true
        lastState = state
        return try result.get()
    }
}

class ConfigurableUpdateBookmarkUseCase: PUpdateBookmarkUseCase {
    var result: Result<Void, Error> = .success(())
    var toggleArchiveCalled = false
    var toggleFavoriteCalled = false
    var updateProgressCalled = false
    var lastProgressValue: Int?

    func execute(bookmarkId: String, updateRequest: BookmarkUpdateRequest) async throws { try result.get() }
    func toggleArchive(bookmarkId: String, isArchived: Bool) async throws {
        toggleArchiveCalled = true
        try result.get()
    }
    func toggleFavorite(bookmarkId: String, isMarked: Bool) async throws {
        toggleFavoriteCalled = true
        try result.get()
    }
    func markAsDeleted(bookmarkId: String) async throws { try result.get() }
    func updateReadProgress(bookmarkId: String, progress: Int, anchor: String?) async throws {
        updateProgressCalled = true
        lastProgressValue = progress
        try result.get()
    }
    func updateTitle(bookmarkId: String, title: String) async throws { try result.get() }
    func updateLabels(bookmarkId: String, labels: [String]) async throws { try result.get() }
    func addLabels(bookmarkId: String, labels: [String]) async throws { try result.get() }
    func removeLabels(bookmarkId: String, labels: [String]) async throws { try result.get() }
}

class ConfigurableDeleteBookmarkUseCase: PDeleteBookmarkUseCase {
    var result: Result<Void, Error> = .success(())
    var deleteCalled = false
    var lastDeletedId: String?

    func execute(bookmarkId: String) async throws {
        deleteCalled = true
        lastDeletedId = bookmarkId
        try result.get()
    }
}

class ConfigurableGetBookmarkUseCase: PGetBookmarkUseCase {
    var result: Result<BookmarkDetail, Error> = .success(
        BookmarkDetail(id: "123", title: "Test", url: "https://example.com", description: "Test", siteName: "Test", authors: ["Test"], created: "2021-01-01", updated: "2021-01-01", wordCount: 100, readingTime: 2, hasArticle: true, isMarked: false, isArchived: false, labels: [], thumbnailUrl: "", imageUrl: "", lang: "en", readProgress: 0)
    )

    func execute(id: String) async throws -> BookmarkDetail {
        return try result.get()
    }
}

class ConfigurableGetBookmarkArticleUseCase: PGetBookmarkArticleUseCase {
    var result: Result<String, Error> = .success("<p>Test article content</p>")

    func execute(id: String) async throws -> String {
        return try result.get()
    }
}

class ConfigurableLoginUseCase: PLoginUseCase {
    var result: Result<User, Error> = .success(User(id: "123", token: "abc"))
    var executeCalled = false

    func execute(endpoint: String, username: String, password: String) async throws -> User {
        executeCalled = true
        return try result.get()
    }
}

class ConfigurableCheckServerReachabilityUseCase: PCheckServerReachabilityUseCase {
    var isReachable: Bool = true
    var serverInfo: ServerInfo = ServerInfo(version: "1.0.0", isReachable: true, features: ["oauth"])

    func execute() async -> Bool { isReachable }
    func getServerInfo() async throws -> ServerInfo { serverInfo }
}

class ConfigurableCreateBookmarkUseCase: PCreateBookmarkUseCase {
    var result: Result<String, Error> = .success("new-bookmark-id")

    func execute(createRequest: CreateBookmarkRequest) async throws -> String { try result.get() }
    func createFromURL(_ url: String) async throws -> String { try result.get() }
    func createFromURLWithTitle(_ url: String, title: String) async throws -> String { try result.get() }
    func createFromURLWithLabels(_ url: String, labels: [String]) async throws -> String { try result.get() }
    func createFromClipboard() async throws -> String? { try result.get() }
}

class ConfigurableSummarizeArticleUseCase: PSummarizeArticleUseCase {
    static var isAvailable: Bool { true }
    var result: Result<String, Error> = .success("Test summary")
    var executeCalled = false
    var lastTargetLanguage: String?

    func execute(articleHTML: String, targetLanguage: String) async throws -> String {
        executeCalled = true
        lastTargetLanguage = targetLanguage
        return try result.get()
    }
}

// MARK: - Simple Test Error

enum TestError: Error, Equatable {
    case networkError
    case unauthorized
    case serverUnreachable
}
