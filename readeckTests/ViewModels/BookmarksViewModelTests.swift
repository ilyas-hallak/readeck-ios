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

        #expect(vm.errorMessage == "Error loading bookmarks")
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
}
