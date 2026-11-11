import Testing
import Foundation
import Combine
@testable import readeck

@Suite("BookmarksViewModel Tests")
@MainActor
struct BookmarksViewModelTests {

    private func createSUT() -> (BookmarksViewModel, TestUseCaseFactory) {
        let factory = TestUseCaseFactory()
        let vm = BookmarksViewModel(factory)
        return (vm, factory)
    }

    private func bookmark(id: String) -> Bookmark {
        Bookmark(
            id: id, title: id, url: "https://example.com/\(id)", href: "https://example.com/\(id)",
            description: "", authors: [], created: "", published: "", updated: "",
            siteName: "example.com", site: "https://example.com", readingTime: 2, wordCount: 20,
            hasArticle: true, isArchived: false, isDeleted: false, isMarked: false, labels: [],
            lang: "EN", loaded: false, readProgress: 0, documentType: "", state: 0,
            textDirection: "ltr", type: "",
            resources: .init(article: nil, icon: nil, image: nil, log: nil, props: nil, thumbnail: nil)
        )
    }

    // MARK: - Load Bookmarks

    @Test("Load bookmarks populates list")
    func loadBookmarksPopulatesList() async {
        let (vm, factory) = createSUT()
        let page = BookmarksPage(
            bookmarks: [.mock],
            currentPage: 1,
            totalCount: 1,
            totalPages: 1,
            links: nil
        )
        factory.mockGetBookmarks.result = .success(page)

        await vm.loadBookmarks()

        #expect(vm.bookmarks?.bookmarks.count == 1)
        #expect(vm.bookmarks?.bookmarks.first?.id == Bookmark.mock.id)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load bookmarks with empty result")
    func loadBookmarksEmpty() async {
        let (vm, factory) = createSUT()
        let emptyPage = BookmarksPage(
            bookmarks: [],
            currentPage: 1,
            totalCount: 0,
            totalPages: 1,
            links: nil
        )
        factory.mockGetBookmarks.result = .success(emptyPage)

        await vm.loadBookmarks()

        #expect(vm.bookmarks?.bookmarks.isEmpty == true)
        #expect(vm.errorMessage == nil)
    }

    @Test("Load bookmarks failure sets error state")
    func loadBookmarksFailure() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .failure(TestError.networkError)

        await vm.loadBookmarks()

        #expect(vm.errorMessage?.hasPrefix("Error loading bookmarks") == true)
        #expect(vm.isLoading == false)
    }

    // MARK: - Toggle Archive

    @Test("Toggle archive calls update use case")
    func toggleArchive() async {
        let (vm, factory) = createSUT()
        // Pre-populate so loadBookmarks inside toggleArchive succeeds
        let page = BookmarksPage(
            bookmarks: [.mock],
            currentPage: 1,
            totalCount: 1,
            totalPages: 1,
            links: nil
        )
        factory.mockGetBookmarks.result = .success(page)

        await vm.toggleArchive(bookmark: .mock)

        #expect(factory.mockUpdateBookmark.toggleArchiveCalled == true)
    }

    @Test("Archiving preserves the active type filter (regression: Codeberg #39)")
    func toggleArchivePreservesTypeFilter() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: [.mock], currentPage: 1, totalCount: 1, totalPages: 1, links: nil)
        )
        // Load the Unread tab showing all types (articles, videos, photos).
        await vm.loadBookmarks(state: .unread, type: [.article, .video, .photo])

        await vm.toggleArchive(bookmark: .mock)

        // The reload after archiving must keep the active filter instead of falling back to
        // [.article]; otherwise videos/photos vanish from the list until the tab is switched.
        #expect(factory.mockGetBookmarks.lastType == [.article, .video, .photo])
    }

    @Test("A load requested while a refresh is in flight keeps its filter (regression: Codeberg #39)")
    func loadDuringRefreshKeepsRequestedFilter() async {
        let (vm, factory) = createSUT()
        let allTypes: [BookmarkType] = [.article, .video, .photo]

        // At launch a network change triggers a refresh before the view has set its filter.
        factory.mockGetBookmarks.holdNextCall = true
        let refresh = Task { await vm.refreshBookmarks() }
        while factory.mockGetBookmarks.heldCall == nil { await Task.yield() }

        // The view's own initial load arrives while that refresh is still running.
        await vm.loadBookmarks(state: .unread, type: allTypes)
        factory.mockGetBookmarks.releaseHeldCall()
        await refresh.value

        #expect(vm.currentType == allTypes)
        #expect(factory.mockGetBookmarks.lastType == allTypes)

        await vm.toggleArchive(bookmark: .mock)
        #expect(factory.mockGetBookmarks.lastType == allTypes)
    }

    @Test("A load requested while more pages are loading still runs with its filter")
    func loadDuringLoadMoreRunsAfterwards() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: [.mock], currentPage: 1, totalCount: 2, totalPages: 2, links: nil)
        )
        await vm.loadBookmarks(state: .unread, type: [.article])

        factory.mockGetBookmarks.holdNextCall = true
        let loadMore = Task { await vm.loadMoreBookmarks() }
        while factory.mockGetBookmarks.heldCall == nil { await Task.yield() }

        await vm.loadBookmarks(state: .unread, type: [.video])
        factory.mockGetBookmarks.releaseHeldCall()
        await loadMore.value

        #expect(factory.mockGetBookmarks.lastType == [.video])
    }

    @Test("A filter change while loading the next page discards that stale page (regression: Codeberg #39)")
    func filterChangeDuringLoadMoreDiscardsStalePage() async {
        let (vm, factory) = createSUT()
        let firstBookmark = bookmark(id: "page1")
        let staleBookmark = bookmark(id: "stale-page2")
        let newFilterBookmark = bookmark(id: "video-page1")

        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: [firstBookmark], currentPage: 1, totalCount: 2, totalPages: 2, links: nil)
        )
        await vm.loadBookmarks(state: .unread, type: [.article])

        // The in-flight "load more" call still targets the old filter.
        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: [staleBookmark], currentPage: 2, totalCount: 2, totalPages: 2, links: nil)
        )
        factory.mockGetBookmarks.holdNextCall = true
        let loadMore = Task { await vm.loadMoreBookmarks() }
        while factory.mockGetBookmarks.heldCall == nil { await Task.yield() }

        // The filter changes while that request is still in flight.
        await vm.loadBookmarks(state: .unread, type: [.video])

        // Hold the refresh's own fetch too, so we can inspect the state right after the
        // stale page's request resolves but before the refresh has replaced the list.
        factory.mockGetBookmarks.holdNextCall = true
        factory.mockGetBookmarks.releaseHeldCall()
        while factory.mockGetBookmarks.heldCall == nil { await Task.yield() }

        #expect(vm.bookmarks?.bookmarks.contains(where: { $0.id == staleBookmark.id }) == false)

        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: [newFilterBookmark], currentPage: 1, totalCount: 1, totalPages: 1, links: nil)
        )
        factory.mockGetBookmarks.releaseHeldCall()
        await loadMore.value

        #expect(vm.bookmarks?.bookmarks.map(\.id) == [newFilterBookmark.id])
    }

    // MARK: - Toggle Favorite

    @Test("Toggle favorite calls update use case")
    func toggleFavorite() async {
        let (vm, factory) = createSUT()
        let page = BookmarksPage(
            bookmarks: [.mock],
            currentPage: 1,
            totalCount: 1,
            totalPages: 1,
            links: nil
        )
        factory.mockGetBookmarks.result = .success(page)

        await vm.toggleFavorite(bookmark: .mock)

        #expect(factory.mockUpdateBookmark.toggleFavoriteCalled == true)
    }

    // MARK: - Delete with Undo

    @Test("Delete bookmark with undo tracks pending delete")
    func deleteBookmarkWithUndo() {
        let (vm, _) = createSUT()
        let bookmark = Bookmark.mock

        vm.deleteBookmarkWithUndo(bookmark: bookmark)

        #expect(vm.pendingDeletes[bookmark.id] != nil)
        #expect(vm.pendingDeletes[bookmark.id]?.bookmark.id == bookmark.id)

        // Clean up: cancel the pending delete to avoid background task leaking
        vm.undoDelete(bookmarkId: bookmark.id)
    }

    // MARK: - Error Mapping

    @Test("Network-level errors are flagged as network errors")
    func loadBookmarksNetworkErrorSetsNetworkFlag() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .failure(URLError(.notConnectedToInternet))

        await vm.loadBookmarks()

        #expect(vm.isNetworkError == true)
        #expect(vm.errorMessage == "No internet connection")
    }

    @Test("Other URLErrors are not flagged as network errors")
    func loadBookmarksOtherURLErrorKeepsNetworkFlagOff() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .failure(URLError(.badServerResponse))

        await vm.loadBookmarks()

        #expect(vm.isNetworkError == false)
        #expect(vm.errorMessage?.hasPrefix("Network error") == true)
    }

    @Test("401 maps to a session-expired message")
    func loadBookmarksUnauthorizedMessage() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .failure(APIError.serverError(401))

        await vm.loadBookmarks()

        #expect(vm.errorMessage == "Session expired. Please log in again.")
        #expect(vm.isNetworkError == false)
    }

    @Test("5xx maps to a retryable server error message")
    func loadBookmarksServerErrorMessage() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .failure(APIError.serverError(503))

        await vm.loadBookmarks()

        #expect(vm.errorMessage == "Server error (code: 503). Please try again later.")
    }

    @Test("Invalid URL maps to a settings hint")
    func loadBookmarksInvalidURLMessage() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .failure(APIError.invalidURL)

        await vm.loadBookmarks()

        #expect(vm.errorMessage == "Invalid server URL. Please check your settings.")
    }

    @Test("Server errors carrying a message surface that message instead of failing silently")
    func loadBookmarksServerErrorWithMessageIsSurfaced() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .failure(
            APIError.serverErrorWithMessage(statusCode: 422, message: "Invalid sort field")
        )

        await vm.loadBookmarks()

        // Used to leave errorMessage nil, so the list looked healthy while nothing loaded.
        #expect(vm.errorMessage == "Invalid sort field")
    }

    @Test("A failed reload keeps the previously loaded bookmarks visible")
    func loadBookmarksFailureKeepsExistingData() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: [.mock], currentPage: 1, totalCount: 1, totalPages: 1, links: nil)
        )
        await vm.loadBookmarks()

        factory.mockGetBookmarks.result = .failure(TestError.networkError)
        await vm.loadBookmarks()

        #expect(vm.bookmarks?.bookmarks.count == 1)
        #expect(vm.errorMessage != nil)
    }

    @Test("Retrying clears the previous error state")
    func retryLoadingClearsErrorState() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .failure(URLError(.notConnectedToInternet))
        await vm.loadBookmarks()
        #expect(vm.isNetworkError == true)

        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: [.mock], currentPage: 1, totalCount: 1, totalPages: 1, links: nil)
        )
        await vm.retryLoading()

        #expect(vm.errorMessage == nil)
        #expect(vm.isNetworkError == false)
    }

    // MARK: - Mutation Error Paths

    @Test("Archive failure sets an error message")
    func toggleArchiveFailure() async {
        let (vm, factory) = createSUT()
        factory.mockUpdateBookmark.result = .failure(TestError.networkError)

        await vm.toggleArchive(bookmark: .mock)

        #expect(vm.errorMessage == "Error archiving bookmark")
    }

    @Test("Favorite failure sets an error message")
    func toggleFavoriteFailure() async {
        let (vm, factory) = createSUT()
        factory.mockUpdateBookmark.result = .failure(TestError.networkError)

        await vm.toggleFavorite(bookmark: .mock)

        #expect(vm.errorMessage == "Error marking bookmark")
    }

    @Test("Reset read progress failure sets an error message")
    func resetReadProgressFailure() async {
        let (vm, factory) = createSUT()
        factory.mockUpdateBookmark.result = .failure(TestError.networkError)

        await vm.resetReadProgress(bookmark: .mock)

        #expect(vm.errorMessage == "Error resetting reading progress")
    }

    // MARK: - Offline Fallback

    @Test("Offline load falls back to cached bookmarks")
    func loadCachedBookmarksFromUIUsesCache() async {
        let (vm, factory) = createSUT()
        factory.mockGetCachedBookmarks.result = .success([.mock])

        await vm.loadCachedBookmarksFromUI()

        #expect(factory.mockGetCachedBookmarks.executeCalled == true)
        #expect(vm.bookmarks?.bookmarks.count == 1)
        #expect(vm.isNetworkError == true)
        #expect(vm.errorMessage == "No internet connection")
    }

    @Test("Offline fallback only reads the cache on the Unread tab")
    func cachedBookmarksSkippedOutsideUnread() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: [.mock], currentPage: 1, totalCount: 1, totalPages: 1, links: nil)
        )
        await vm.loadBookmarks(state: .archived)

        await vm.loadCachedBookmarksFromUI()

        // Only the Unread list is cached for offline use; the other tabs must not
        // silently show unread items.
        #expect(factory.mockGetCachedBookmarks.executeCalled == false)
    }

    @Test("A failing cache read leaves the offline error message in place")
    func cachedBookmarksFailureKeepsOfflineMessage() async {
        let (vm, factory) = createSUT()
        factory.mockGetCachedBookmarks.result = .failure(TestError.networkError)

        await vm.loadCachedBookmarksFromUI()

        #expect(vm.bookmarks == nil)
        #expect(vm.errorMessage == "No internet connection")
    }

    @Test("Go Offline and Go Online toggle the forced offline mode")
    func goOfflineAndOnlineToggleForcedOffline() {
        let (vm, factory) = createSUT()
        var forced: [Bool] = []
        let sub = factory.mockNetworkMonitor.isForcedOffline.sink { forced.append($0) }

        vm.goOffline()
        vm.goOnline()

        #expect(forced == [false, true, false])
        sub.cancel()
    }
}
