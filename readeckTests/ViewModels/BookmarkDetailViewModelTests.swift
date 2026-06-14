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
}
