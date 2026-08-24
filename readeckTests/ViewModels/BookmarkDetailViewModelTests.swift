import Testing
import Foundation
@testable import readeck

@Suite("BookmarkDetailViewModel Tests")
@MainActor
struct BookmarkDetailViewModelTests {

    private func createSUT() -> (BookmarkDetailViewModel, TestUseCaseFactory) {
        let factory = TestUseCaseFactory()
        let vm = BookmarkDetailViewModel(factory)
        return (vm, factory)
    }

    // MARK: - Load Bookmark Detail

    @Test("Load bookmark detail populates state")
    func loadBookmarkDetailPopulatesState() async {
        let (vm, factory) = createSUT()
        let detail = BookmarkDetail(
            id: "456",
            title: "Test Bookmark",
            url: "https://example.com",
            description: "A test bookmark",
            siteName: "Example",
            authors: ["Author"],
            created: "2024-01-01",
            updated: "2024-01-02",
            wordCount: 500,
            readingTime: 5,
            hasArticle: true,
            loaded: true,
            isMarked: false,
            isArchived: false,
            labels: [],
            thumbnailUrl: "",
            imageUrl: "",
            lang: "en",
            readProgress: 0
        )
        factory.mockGetBookmark.result = .success(detail)

        await vm.loadBookmarkDetail(id: "456")

        #expect(vm.bookmarkDetail.id == "456")
        #expect(vm.bookmarkDetail.title == "Test Bookmark")
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load bookmark detail failure sets error")
    func loadBookmarkDetailFailure() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmark.result = .failure(TestError.networkError)

        await vm.loadBookmarkDetail(id: "456")

        #expect(vm.errorMessage == "Error loading bookmark")
        #expect(vm.isLoading == false)
    }

    // MARK: - Load Article Content

    @Test("Load article content populates articleContent")
    func loadArticleContentPopulatesContent() async {
        let (vm, factory) = createSUT()
        let html = "<p>Hello World</p>"
        factory.mockGetBookmarkArticle.result = .success(html)

        await vm.loadArticleContent(id: "456")

        // Article content is loaded (either from cache or server)
        #expect(!vm.articleContent.isEmpty)
        #expect(vm.isLoadingArticle == false)
    }

    // MARK: - Archive Bookmark

    @Test("Archive bookmark calls update use case")
    func archiveBookmarkCallsUseCase() async {
        let (vm, factory) = createSUT()

        await vm.archiveBookmark(id: "456")

        #expect(factory.mockUpdateBookmark.toggleArchiveCalled == true)
        #expect(vm.bookmarkDetail.isArchived == true)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Update Read Progress

    @Test("Update read progress calls use case with correct value")
    func updateReadProgressCallsUseCase() async {
        let (vm, factory) = createSUT()
        // readProgress starts at 0, so progress > 0 will trigger the update
        await vm.updateReadProgress(id: "456", progress: 50, anchor: nil)

        #expect(factory.mockUpdateBookmark.updateProgressCalled == true)
        #expect(factory.mockUpdateBookmark.lastProgressValue == 50)
    }

    // MARK: - Delete Bookmark

    @Test("Delete bookmark calls use case and returns true on success")
    func deleteBookmarkSuccess() async {
        let (vm, factory) = createSUT()
        factory.mockDeleteBookmark.result = .success(())

        let success = await vm.deleteBookmark(id: "789")

        #expect(success == true)
        #expect(factory.mockDeleteBookmark.deleteCalled == true)
        #expect(factory.mockDeleteBookmark.lastDeletedId == "789")
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test("Delete bookmark returns false and sets error on failure")
    func deleteBookmarkFailure() async {
        let (vm, factory) = createSUT()
        factory.mockDeleteBookmark.result = .failure(TestError.networkError)

        let success = await vm.deleteBookmark(id: "789")

        #expect(success == false)
        #expect(vm.errorMessage == "Error deleting bookmark")
        #expect(vm.isLoading == false)
    }

    @Test("Delete bookmark posts bookmarkDeleted notification on success")
    func deleteBookmarkPostsNotification() async {
        let (vm, factory) = createSUT()
        factory.mockDeleteBookmark.result = .success(())

        var receivedId: String?
        let observer = NotificationCenter.default.addObserver(
            forName: .bookmarkDeleted,
            object: nil,
            queue: .main
        ) { notification in
            receivedId = notification.userInfo?["id"] as? String
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        _ = await vm.deleteBookmark(id: "789")

        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(receivedId == "789")
    }

    // MARK: - Article Content Error Paths

    @Test("Article load failure sets error and stops the loading indicator")
    func loadArticleContentFailure() async {
        let (vm, factory) = createSUT()
        factory.mockGetCachedArticle.result = nil
        factory.mockGetBookmarkArticle.result = .failure(TestError.networkError)

        await vm.loadArticleContent(id: "456")

        #expect(vm.errorMessage == "Error loading article")
        #expect(vm.articleContent.isEmpty)
        #expect(vm.isLoadingArticle == false)
    }

    @Test("A cached article is served even when the server is unreachable")
    func loadArticleContentFallsBackToCache() async {
        let (vm, factory) = createSUT()
        factory.mockGetCachedArticle.result = "<p>Cached</p>"
        factory.mockGetBookmarkArticle.result = .failure(TestError.networkError)

        await vm.loadArticleContent(id: "456")

        #expect(vm.articleContent == "<p>Cached</p>")
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoadingArticle == false)
    }

    // MARK: - Bookmark Detail Error Paths

    @Test("Failing annotations do not break loading the bookmark itself")
    func loadBookmarkDetailToleratesAnnotationFailure() async {
        let (vm, factory) = createSUT()
        factory.mockGetAnnotations.result = .failure(TestError.networkError)

        await vm.loadBookmarkDetail(id: "456")

        // Annotations are supplementary — the article must still open.
        #expect(vm.bookmarkDetail.id == "123")
        #expect(vm.annotations.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Archive

    @Test("Un-archiving clears the archived flag instead of setting it")
    func unarchiveClearsArchivedFlag() async {
        let (vm, _) = createSUT()
        await vm.archiveBookmark(id: "456", isArchive: true)
        #expect(vm.bookmarkDetail.isArchived == true)

        await vm.archiveBookmark(id: "456", isArchive: false)

        // The flag used to be hardcoded to true, so the reader's toggle stayed
        // on "archived" after un-archiving.
        #expect(vm.bookmarkDetail.isArchived == false)
    }

    @Test("Archive failure sets an error and leaves the flag untouched")
    func archiveBookmarkFailure() async {
        let (vm, factory) = createSUT()
        factory.mockUpdateBookmark.result = .failure(TestError.networkError)

        await vm.archiveBookmark(id: "456")

        #expect(vm.errorMessage == "Error archiving bookmark")
        #expect(vm.bookmarkDetail.isArchived == false)
        #expect(vm.isLoading == false)
    }

    // MARK: - Favorite

    @Test("Toggle favorite flips the flag")
    func toggleFavoriteSuccess() async {
        let (vm, factory) = createSUT()

        await vm.toggleFavorite(id: "456")

        #expect(factory.mockUpdateBookmark.toggleFavoriteCalled == true)
        #expect(vm.bookmarkDetail.isMarked == true)
        #expect(vm.errorMessage == nil)
    }

    @Test("Favorite failure sets an error and leaves the flag untouched")
    func toggleFavoriteFailure() async {
        let (vm, factory) = createSUT()
        factory.mockUpdateBookmark.result = .failure(TestError.networkError)

        await vm.toggleFavorite(id: "456")

        #expect(vm.errorMessage == "Error updating favorite status")
        #expect(vm.bookmarkDetail.isMarked == false)
        #expect(vm.isLoading == false)
    }

    // MARK: - Read Progress

    @Test("Read progress is not pushed backwards")
    func updateReadProgressIgnoresLowerValue() async {
        let (vm, factory) = createSUT()
        vm.readProgress = 80

        await vm.updateReadProgress(id: "456", progress: 20, anchor: nil)

        #expect(factory.mockUpdateBookmark.updateProgressCalled == false)
    }

    // MARK: - Annotations

    @Test("Creating an annotation appends it and pulls the annotated HTML")
    func createAnnotationSuccess() async {
        let (vm, factory) = createSUT()
        // The server re-renders the article with the highlight markup afterwards.
        factory.mockGetBookmarkArticle.result = .success("<p><rd-annotation>highlighted</rd-annotation></p>")

        await vm.createAnnotation(bookmarkId: "456", color: "yellow", text: "highlighted", startOffset: 0, endOffset: 5, startSelector: "p", endSelector: "p")

        #expect(vm.annotations.count == 1)
        #expect(vm.hasAnnotations == true)
        #expect(vm.articleContent.contains("rd-annotation"))
        #expect(vm.errorMessage == nil)
    }

    @Test("Annotation failure sets a generic error message")
    func createAnnotationFailure() async {
        let (vm, factory) = createSUT()
        factory.mockCreateAnnotation.result = .failure(TestError.networkError)

        await vm.createAnnotation(bookmarkId: "456", color: "yellow", text: "highlighted", startOffset: 0, endOffset: 5, startSelector: "p", endSelector: "p")

        #expect(vm.errorMessage == "Error creating highlight")
        #expect(vm.annotations.isEmpty)
    }

    @Test("Overlapping annotations get their own error message")
    func createAnnotationOverlapError() async {
        let (vm, factory) = createSUT()
        factory.mockCreateAnnotation.result = .failure(
            APIError.serverErrorWithMessage(statusCode: 422, message: "annotation is overlapping an existing one")
        )

        await vm.createAnnotation(bookmarkId: "456", color: "yellow", text: "highlighted", startOffset: 0, endOffset: 5, startSelector: "p", endSelector: "p")

        #expect(vm.errorMessage == "This text overlaps with an existing highlight")
    }

    // MARK: - Share Content

    @Test("Share text combines title, URL and annotations")
    func shareContentIncludesAnnotations() async {
        let (vm, factory) = createSUT()
        factory.mockGetAnnotations.result = .success([
            Annotation(id: "1", text: "first note", created: "", startOffset: 0, endOffset: 1, startSelector: "", endSelector: "")
        ])

        await vm.loadBookmarkDetail(id: "456")

        #expect(vm.shareContent.contains("https://example.com"))
        #expect(vm.shareContent.contains("first note"))
    }
}
