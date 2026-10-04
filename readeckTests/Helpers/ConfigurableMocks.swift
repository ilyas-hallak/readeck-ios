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
    var lastType: [BookmarkType]?
    var lastTag: String?
    // Suspends the next call until releaseHeldCall(), to model a request that is still in flight.
    var holdNextCall = false
    private(set) var heldCall: CheckedContinuation<Void, Never>?

    // swiftlint:disable:next discouraged_optional_collection
    func execute(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?, sort: String?) async throws -> BookmarksPage {
        executeCalled = true
        lastState = state
        lastType = type
        lastTag = tag
        if holdNextCall {
            holdNextCall = false
            await withCheckedContinuation { heldCall = $0 }
        }
        return try result.get()
    }

    func releaseHeldCall() {
        heldCall?.resume()
        heldCall = nil
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
        BookmarkDetail(id: "123", title: "Test", url: "https://example.com", description: "Test", siteName: "Test", authors: ["Test"], created: "2021-01-01", updated: "2021-01-01", wordCount: 100, readingTime: 2, hasArticle: true, loaded: true, isMarked: false, isArchived: false, labels: [], thumbnailUrl: "", imageUrl: "", lang: "en", readProgress: 0)
    )
    var delay: Duration?
    var executeCallCount = 0

    func execute(id: String) async throws -> BookmarkDetail {
        executeCallCount += 1
        if let delay {
            try await Task.sleep(for: delay)
        }
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
    private(set) var executeCount = 0

    func execute() async -> Bool {
        executeCount += 1
        return isReachable
    }
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

class ConfigurableGetCachedArticleUseCase: PGetCachedArticleUseCase {
    /// `nil` by default so tests exercise the server path instead of the bundled sample article.
    var result: String?

    func execute(id: String) -> String? { result }
}

class ConfigurableGetCachedBookmarkDetailUseCase: PGetCachedBookmarkDetailUseCase {
    var result: BookmarkDetail?

    func execute(id: String) -> BookmarkDetail? { result }
}

class ConfigurableGetCachedBookmarksUseCase: PGetCachedBookmarksUseCase {
    var result: Result<[Bookmark], Error> = .success([.mock])
    var executeCalled = false

    func execute() async throws -> [Bookmark] {
        executeCalled = true
        return try result.get()
    }
}

class ConfigurableGetBookmarkAnnotationsUseCase: PGetBookmarkAnnotationsUseCase {
    var result: Result<[Annotation], Error> = .success([])

    func execute(bookmarkId: String) async throws -> [Annotation] { try result.get() }
}

class ConfigurableCreateAnnotationUseCase: PCreateAnnotationUseCase {
    var result: Result<Annotation, Error> = .success(
        Annotation(id: "annotation-1", text: "highlighted", created: "", startOffset: 0, endOffset: 1, startSelector: "", endSelector: "")
    )
    /// Results returned before falling back to `result`, for tests that create several
    /// annotations and need each one to get a different ID.
    var resultQueue: [Result<Annotation, Error>] = []

    func execute(bookmarkId: String, color: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws -> Annotation {
        if !resultQueue.isEmpty {
            return try resultQueue.removeFirst().get()
        }
        return try result.get()
    }

    func execute(bookmarkId: String, text: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws {
        _ = try result.get()
    }
}

class ConfigurableDeleteAnnotationUseCase: PDeleteAnnotationUseCase {
    var result: Result<Void, Error> = .success(())
    private(set) var deletedAnnotationIds: [String] = []

    func execute(bookmarkId: String, annotationId: String) async throws {
        deletedAnnotationIds.append(annotationId)
        try result.get()
    }
}

class ConfigurableLogoutUseCase: PLogoutUseCase {
    var result: Result<Void, Error> = .success(())
    var executeCount = 0
    var executeCalled: Bool { executeCount > 0 }

    func execute() async throws {
        executeCount += 1
        try result.get()
    }
}

class ConfigurableUpdateUnreadBadgeUseCase: PUpdateUnreadBadgeUseCase {
    var refreshCount = 0

    func refresh() async { refreshCount += 1 }

    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool { true }
}

class ConfigurableExportArticlePDFUseCase: PExportArticlePDFUseCase {
    var result: Result<URL, Error> = .success(URL(fileURLWithPath: "/tmp/article.pdf"))
    var executeCount = 0
    var lastArticleHTML: String?

    func execute(bookmark: BookmarkDetail, articleHTML: String, settings: Settings?) async throws -> URL {
        executeCount += 1
        lastArticleHTML = articleHTML
        return try result.get()
    }
}

class ConfigurableGetServerInfoUseCase: PGetServerInfoUseCase {
    var result: Result<ServerInfo, Error> = .success(
        ServerInfo(version: "0.23.2", isReachable: true, features: ["oauth"])
    )

    func execute(endpoint: String?) async throws -> ServerInfo {
        try result.get()
    }
}

class ConfigurableCreateShareLinkUseCase: PCreateShareLinkUseCase {
    var result: Result<URL, Error> = .success(URL(string: "https://readeck.example.com/@b/abc")!)
    var lastBookmarkId: String?
    /// When true, `execute` suspends until `resume()` is called, so tests can observe
    /// state while the call is still in flight.
    var holdsExecution = false
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?
    private var isReleased = false

    func execute(bookmarkId: String) async throws -> URL {
        lastBookmarkId = bookmarkId
        if holdsExecution {
            await withCheckedContinuation { continuation in
                lock.withLock {
                    if isReleased {
                        continuation.resume()
                    } else {
                        self.continuation = continuation
                    }
                }
            }
        }
        return try result.get()
    }

    /// Safe to call before `execute` reached its suspension point.
    func resume() {
        let pending = lock.withLock {
            isReleased = true
            defer { continuation = nil }
            return continuation
        }
        pending?.resume()
    }
}

class ConfigurableShareByEmailUseCase: PShareByEmailUseCase {
    var result: Result<Void, Error> = .success(())
    var executeCount = 0
    var lastEmail: String?
    var lastFormat: EmailShareFormat?

    func execute(bookmarkId: String, email: String, format: EmailShareFormat) async throws {
        executeCount += 1
        lastEmail = email
        lastFormat = format
        try result.get()
    }
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

    func prewarm() {}
}

// MARK: - Simple Test Error

enum TestError: Error, Equatable {
    case networkError
    case unauthorized
    case serverUnreachable
}
