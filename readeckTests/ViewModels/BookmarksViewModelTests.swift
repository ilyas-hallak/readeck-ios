import Testing
import Foundation
@testable import readeck

@Suite("BookmarksViewModel Tests")
@MainActor
struct BookmarksViewModelTests {

    private func createSUT() -> (BookmarksViewModel, TestUseCaseFactory) {
        let factory = TestUseCaseFactory()
        let vm = BookmarksViewModel(factory)
        return (vm, factory)
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
}
