import Testing
import Foundation
import Combine
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

    @Test("Load bookmark detail falls back to cached metadata when offline")
    func loadBookmarkDetailFailureFallsBackToCachedMetadata() async {
        let (vm, factory) = createSUT()
        let cachedDetail = BookmarkDetail(
            id: "456",
            title: "Cached Title",
            url: "https://example.com/cached",
            description: "",
            siteName: "Example",
            authors: [],
            created: "2024-01-01",
            updated: "2024-01-02",
            wordCount: 0,
            readingTime: 0,
            hasArticle: false,
            loaded: false,
            isMarked: false,
            isArchived: false,
            labels: [],
            thumbnailUrl: "",
            imageUrl: "",
            lang: "en",
            readProgress: 0
        )
        factory.mockGetBookmark.result = .failure(TestError.networkError)
        factory.mockGetCachedBookmarkDetail.result = cachedDetail

        await vm.loadBookmarkDetail(id: "456")

        #expect(vm.bookmarkDetail.url == "https://example.com/cached")
        #expect(vm.bookmarkDetail.title == "Cached Title")
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Wait For Article Ready

    @Test("Wait for article ready stops after one poll when offline")
    func waitForArticleReadyStopsOnNoConnection() async {
        let (vm, factory) = createSUT()
        vm.bookmarkDetail = BookmarkDetail(
            id: "456",
            title: "Test",
            url: "https://example.com",
            description: "",
            siteName: "",
            authors: [],
            created: "",
            updated: "",
            wordCount: 0,
            readingTime: 0,
            hasArticle: false,
            loaded: false,
            isMarked: false,
            isArchived: false,
            labels: [],
            thumbnailUrl: "",
            imageUrl: "",
            lang: "en",
            readProgress: 0
        )
        factory.mockGetBookmark.result = .failure(URLError(.notConnectedToInternet))

        await vm.waitForArticleReady(id: "456", maxAttempts: 8, delay: 0.01)

        #expect(factory.mockGetBookmark.executeCallCount == 1)
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

        // Written on the main queue by the observer below, read here after the sleep.
        nonisolated(unsafe) var receivedId: String?
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

    // MARK: - Opening the Reader (Cache First)

    @Test("A cached article opens at once with cached metadata when the server is unreachable")
    func loadReaderServesCacheWhenOffline() async {
        let (vm, factory) = createSUT()
        factory.mockGetCachedArticle.result = "<p>Cached</p>"
        factory.mockGetCachedBookmarkDetail.result = makeDetail(title: "Cached title")
        factory.mockGetBookmark.result = .failure(TestError.networkError)
        factory.mockGetBookmarkArticle.result = .failure(TestError.networkError)

        let start = ContinuousClock.now
        await vm.loadReader(id: "456")

        #expect(ContinuousClock.now - start < .seconds(1))
        #expect(vm.articleContent == "<p>Cached</p>")
        #expect(vm.bookmarkDetail.title == "Cached title")
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoadingArticle == false)
        #expect(vm.isLoading == false)
    }

    @Test("A cached article without cached metadata does not wait for the server")
    func loadReaderSkipsPollingForCachedArticle() async {
        let (vm, factory) = createSUT()
        factory.mockGetCachedArticle.result = "<p>Cached</p>"
        factory.mockGetBookmark.result = .failure(TestError.networkError)

        let start = ContinuousClock.now
        await vm.loadReader(id: "456")

        #expect(ContinuousClock.now - start < .seconds(1))
        #expect(vm.articleContent == "<p>Cached</p>")
        #expect(vm.errorMessage == nil)
    }

    @Test("A cached article is shown before a hanging server request returns")
    func loadReaderShowsCacheBeforeServerResponds() async throws {
        let (vm, factory) = createSUT()
        factory.mockGetCachedArticle.result = "<p>Cached</p>"
        factory.mockGetBookmark.delay = .seconds(30)

        let loading = Task { await vm.loadReader(id: "456") }
        defer { loading.cancel() }

        let deadline = ContinuousClock.now + .seconds(1)
        while vm.articleContent.isEmpty && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(vm.articleContent == "<p>Cached</p>")
        #expect(vm.isLoadingArticle == false)
    }

    @Test("Server metadata replaces the cached metadata once it arrives")
    func loadReaderRefreshesCachedDetailFromServer() async {
        let (vm, factory) = createSUT()
        factory.mockGetCachedArticle.result = "<p>Cached</p>"
        factory.mockGetCachedBookmarkDetail.result = makeDetail(title: "Cached title")

        await vm.loadReader(id: "123")

        #expect(vm.bookmarkDetail.title == "Test")
    }

    @Test("An uncached article still loads from the server")
    func loadReaderFetchesUncachedArticle() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarkArticle.result = .success("<p>Server</p>")

        await vm.loadReader(id: "123")

        #expect(vm.articleContent == "<p>Server</p>")
        #expect(vm.bookmarkDetail.id == "123")
        #expect(vm.errorMessage == nil)
    }

    @Test("An uncached article that can't be reached fails fast instead of polling")
    func loadReaderSkipsPollingWhenDetailFails() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmark.result = .failure(URLError(.notConnectedToInternet))
        factory.mockGetBookmarkArticle.result = .failure(URLError(.notConnectedToInternet))

        let start = ContinuousClock.now
        await vm.loadReader(id: "123")

        #expect(ContinuousClock.now - start < .seconds(1))
        #expect(vm.isLoadingArticle == false)
        #expect(vm.articleContent.isEmpty)
    }

    @Test("Go Offline switches the app to offline mode")
    func goOfflineForcesOffline() async {
        let (vm, factory) = createSUT()
        var forced: [Bool] = []
        let sub = factory.mockNetworkMonitor.isForcedOffline.sink { forced.append($0) }

        vm.goOffline()

        #expect(forced.last == true)
        sub.cancel()
    }

    @Test("Reloading the detail offline keeps the bookmark that is already shown")
    func reloadBookmarkDetailOfflineKeepsDetail() async {
        let (vm, factory) = createSUT()
        await vm.loadBookmarkDetail(id: "123")
        factory.mockGetBookmark.result = .failure(TestError.networkError)

        await vm.loadBookmarkDetail(id: "123")

        #expect(vm.bookmarkDetail.id == "123")
        #expect(vm.errorMessage == nil)
    }

    @Test("Refreshing a cached article offline keeps it without an error")
    func refreshCachedArticleOfflineKeepsContent() async {
        let (vm, factory) = createSUT()
        factory.mockGetCachedArticle.result = "<p>Cached</p>"
        factory.mockGetCachedBookmarkDetail.result = makeDetail(title: "Cached title")
        factory.mockGetBookmark.result = .failure(TestError.networkError)
        factory.mockGetBookmarkArticle.result = .failure(TestError.networkError)
        await vm.loadReader(id: "123")

        await vm.refreshBookmarkDetail(id: "123")

        #expect(vm.articleContent == "<p>Cached</p>")
        #expect(vm.bookmarkDetail.title == "Cached title")
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoadingArticle == false)
    }

    private func makeDetail(title: String) -> BookmarkDetail {
        BookmarkDetail(
            id: "123", title: title, url: "https://example.com", description: "", siteName: "Example",
            authors: [], created: "", updated: "", wordCount: 100, readingTime: 1, hasArticle: true,
            loaded: true, isMarked: false, isArchived: false, labels: [], thumbnailUrl: "", imageUrl: "",
            lang: "en", readProgress: 0
        )
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

    @Test("Deleting an annotation removes it and pulls the updated HTML")
    func deleteAnnotationSuccess() async {
        let (vm, factory) = createSUT()
        await createHighlight(on: vm, factory: factory)
        factory.mockGetBookmarkArticle.result = .success("<p>highlighted</p>")

        let removed = await vm.deleteAnnotation(bookmarkId: "456", annotationId: "annotation-1")

        #expect(removed)
        #expect(factory.mockDeleteAnnotation.deletedAnnotationIds == ["annotation-1"])
        #expect(vm.annotations.isEmpty)
        #expect(vm.articleContent == "<p>highlighted</p>")
        #expect(vm.hasAnnotations == false)
    }

    @Test("Delete failure keeps the annotation and sets an error message")
    func deleteAnnotationFailure() async {
        let (vm, factory) = createSUT()
        await createHighlight(on: vm, factory: factory)
        factory.mockDeleteAnnotation.result = .failure(TestError.networkError)

        let removed = await vm.deleteAnnotation(bookmarkId: "456", annotationId: "annotation-1")

        #expect(removed == false)
        #expect(vm.errorMessage == NSLocalizedString("Error removing highlight", comment: ""))
        #expect(vm.annotations.count == 1)
    }

    @Test("Undo after creating a highlight deletes it")
    func undoDeletesNewHighlight() async {
        let (vm, factory) = createSUT()
        let undoManager = UndoManager()
        await createHighlight(on: vm, factory: factory, undoManager: undoManager)

        #expect(undoManager.canUndo)
        undoManager.undo()
        await waitUntil { vm.annotations.isEmpty }

        #expect(factory.mockDeleteAnnotation.deletedAnnotationIds == ["annotation-1"])
        #expect(vm.annotations.isEmpty)
    }

    @Test("Removing a new highlight also removes its undo action")
    func removingHighlightDiscardsUndo() async {
        let (vm, factory) = createSUT()
        let undoManager = UndoManager()
        await createHighlight(on: vm, factory: factory, undoManager: undoManager)

        await vm.deleteAnnotation(bookmarkId: "456", annotationId: "annotation-1")

        #expect(undoManager.canUndo == false)
    }

    @Test("Closing the article drops the undo actions of new highlights")
    func discardHighlightUndo() async {
        let (vm, factory) = createSUT()
        let undoManager = UndoManager()
        await createHighlight(on: vm, factory: factory, undoManager: undoManager)

        vm.discardHighlightUndo()

        #expect(undoManager.canUndo == false)
        #expect(factory.mockDeleteAnnotation.deletedAnnotationIds.isEmpty)
    }

    @Test("Text of a highlight is found by its ID")
    func annotationTextLookup() async {
        let (vm, factory) = createSUT()
        await createHighlight(on: vm, factory: factory)

        #expect(vm.annotationText(for: "annotation-1") == "highlighted")
        #expect(vm.annotationText(for: "missing") == nil)
    }

    @Test("A deletion made in the Annotations sheet also clears the reader's undo action")
    func annotationWasDeletedClearsUndoAndState() async {
        let (vm, factory) = createSUT()
        let undoManager = UndoManager()
        await createHighlight(on: vm, factory: factory, undoManager: undoManager)
        vm.articleContent = #"<p><rd-annotation data-annotation-id-value="annotation-1">highlighted</rd-annotation></p>"#
        #expect(undoManager.canUndo)

        vm.annotationWasDeleted(id: "annotation-1", bookmarkId: "456")

        #expect(undoManager.canUndo == false)
        #expect(vm.annotations.isEmpty)
        #expect(!vm.articleContent.contains("annotation-1"))
        #expect(vm.articleContent.contains("highlighted"))
    }

    @Test("Delete removes the highlight markup locally even when the background refresh fails")
    func deleteAnnotationStripsMarkupWhenRefreshFails() async {
        let (vm, factory) = createSUT()
        await createHighlight(on: vm, factory: factory)
        vm.articleContent = #"<p><rd-annotation data-annotation-id-value="annotation-1">highlighted</rd-annotation> and more</p>"#
        factory.mockGetBookmarkArticle.result = .failure(TestError.networkError)

        let removed = await vm.deleteAnnotation(bookmarkId: "456", annotationId: "annotation-1")

        #expect(removed)
        #expect(!vm.articleContent.contains("annotation-1"))
        #expect(vm.articleContent.contains("highlighted"))
    }

    @Test("Undoing only removes the most recently created highlight")
    func undoOnlyRemovesTheLatestHighlight() async {
        let (vm, factory) = createSUT()
        let undoManager = UndoManager()
        // Disable automatic per-run-loop-turn grouping and bracket each creation in its own
        // group, the way two separate user events (two taps, two run loop turns) would in
        // production, instead of letting both calls land in one group because the test runs
        // them back to back in the same turn.
        undoManager.groupsByEvent = false
        factory.mockCreateAnnotation.resultQueue = [
            .success(Annotation(id: "annotation-1", text: "first", created: "", startOffset: 0, endOffset: 1, startSelector: "", endSelector: "")),
            .success(Annotation(id: "annotation-2", text: "second", created: "", startOffset: 2, endOffset: 3, startSelector: "", endSelector: ""))
        ]
        factory.mockGetBookmarkArticle.result = .success("<p>highlighted</p>")

        undoManager.beginUndoGrouping()
        await vm.createAnnotation(
            bookmarkId: "456", color: "yellow", text: "first", startOffset: 0, endOffset: 1,
            startSelector: "p", endSelector: "p", undoManager: undoManager
        )
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        await vm.createAnnotation(
            bookmarkId: "456", color: "yellow", text: "second", startOffset: 2, endOffset: 3,
            startSelector: "p", endSelector: "p", undoManager: undoManager
        )
        undoManager.endUndoGrouping()

        undoManager.undo()
        await waitUntil { factory.mockDeleteAnnotation.deletedAnnotationIds.isEmpty == false }

        #expect(factory.mockDeleteAnnotation.deletedAnnotationIds == ["annotation-2"])
        #expect(vm.annotations.map(\.id) == ["annotation-1"])
        #expect(undoManager.canUndo)
    }

    private func createHighlight(
        on vm: BookmarkDetailViewModel,
        factory: TestUseCaseFactory,
        undoManager: UndoManager? = nil
    ) async {
        factory.mockGetBookmarkArticle.result = .success("<p><rd-annotation>highlighted</rd-annotation></p>")
        await vm.createAnnotation(
            bookmarkId: "456", color: "yellow", text: "highlighted", startOffset: 0, endOffset: 5,
            startSelector: "p", endSelector: "p", undoManager: undoManager
        )
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    // MARK: - Original Link Sharing

    @Test("Sharing the original link shares the bookmark URL only, not the annotations")
    func originalLinkSharesBookmarkURLOnly() async {
        let (vm, factory) = createSUT()
        factory.mockGetAnnotations.result = .success([
            Annotation(id: "1", text: "first note", created: "", startOffset: 0, endOffset: 1, startSelector: "", endSelector: "")
        ])

        await vm.loadBookmarkDetail(id: "456")
        let url = vm.prepareOriginalLinkShare()

        #expect(url?.absoluteString == "https://example.com")
        #expect(vm.shareErrorMessage == nil)
    }

    @Test("A bookmark with an unparseable URL fails to share the original link")
    func originalLinkShareFailsForUnparseableURL() {
        let (vm, _) = createSUT()
        // BookmarkDetail.empty has an empty url string, which URL(string:) rejects.

        let url = vm.prepareOriginalLinkShare()

        #expect(url == nil)
        #expect(vm.shareErrorMessage != nil)
    }

    // MARK: - Readeck Sharing

    @Test("Share options follow the server capabilities")
    func shareOptionsFollowCapabilities() async {
        let (vm, factory) = createSUT()
        factory.mockGetServerInfo.result = .success(
            ServerInfo(version: "0.23.2", isReachable: true, features: ["email", "oauth"])
        )

        await vm.loadBookmarkDetail(id: "123")

        #expect(vm.canShareReadeckLink)
        #expect(vm.canSendByEmail)
    }

    @Test("Email stays hidden without the email feature")
    func emailHiddenWithoutFeature() async {
        let (vm, _) = createSUT()

        await vm.loadBookmarkDetail(id: "123")

        #expect(vm.canShareReadeckLink)
        #expect(!vm.canSendByEmail)
    }

    @Test("Without server info no Readeck share option is offered")
    func shareOptionsHiddenWhenServerInfoFails() async {
        let (vm, factory) = createSUT()
        factory.mockGetServerInfo.result = .failure(TestError.networkError)

        await vm.loadBookmarkDetail(id: "123")

        #expect(!vm.canShareReadeckLink)
        #expect(!vm.canSendByEmail)
        #expect(vm.errorMessage == nil)
    }

    @Test("Creating a share link publishes the URL for the current bookmark")
    func createShareLinkSuccess() async {
        let (vm, factory) = createSUT()
        await vm.loadBookmarkDetail(id: "123")

        let created = await vm.createShareLink()

        #expect(created)
        #expect(factory.mockCreateShareLink.lastBookmarkId == "123")
        #expect(vm.shareLinkURL?.absoluteString == "https://readeck.example.com/@b/abc")
        #expect(vm.isCreatingShareLink == false)
    }

    @Test("A failed share link sets the share error, not the screen-wide error")
    func createShareLinkFailure() async {
        let (vm, factory) = createSUT()
        factory.mockCreateShareLink.result = .failure(TestError.networkError)

        let created = await vm.createShareLink()

        #expect(!created)
        #expect(vm.shareLinkURL == nil)
        #expect(vm.shareErrorMessage != nil)
        #expect(vm.errorMessage == nil)
        #expect(vm.isCreatingShareLink == false)
    }

    @Test("Dismissing the share error clears it")
    func clearShareErrorResetsState() async {
        let (vm, factory) = createSUT()
        factory.mockCreateShareLink.result = .failure(TestError.networkError)
        _ = await vm.createShareLink()
        #expect(vm.shareErrorMessage != nil)

        vm.clearShareError()

        #expect(vm.shareErrorMessage == nil)
    }

    @Test("While a share link is being created every share option is disabled")
    func allOptionsDisabledWhilePreparingShare() async {
        let (vm, factory) = createSUT()
        factory.mockCreateShareLink.holdsExecution = true

        let task = Task { await vm.createShareLink() }
        while !vm.isCreatingShareLink {
            await Task.yield()
        }

        #expect(!vm.isShareOptionEnabled(.email, isOnline: true))
        #expect(!vm.isShareOptionEnabled(.originalLink, isOnline: true))
        #expect(!vm.isShareOptionEnabled(.readeckLink, isOnline: true))
        #expect(!vm.isShareOptionEnabled(.pdf, isOnline: true))

        factory.mockCreateShareLink.resume()
        _ = await task.value
    }

    @Test("The share sheet lists every option when the server supports them")
    func shareSheetListsAllOptions() async {
        let (vm, factory) = createSUT()
        factory.mockGetServerInfo.result = .success(
            ServerInfo(version: "0.23.2", isReachable: true, features: ["email"])
        )

        await vm.loadBookmarkDetail(id: "123")

        #expect(vm.shareOptions == [.email, .originalLink, .readeckLink, .pdf])
    }

    @Test("Without server info the share sheet offers the original link and the PDF")
    func shareSheetFallsBackToLocalOptions() async {
        let (vm, factory) = createSUT()
        factory.mockGetServerInfo.result = .failure(TestError.networkError)

        await vm.loadBookmarkDetail(id: "123")

        #expect(vm.shareOptions == [.originalLink, .pdf])
    }

    @Test("Offline the server backed options are disabled")
    func serverOptionsDisabledOffline() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarkArticle.result = .success("<p>Body</p>")
        await vm.loadArticleContent(id: "123")

        #expect(!vm.isShareOptionEnabled(.email, isOnline: false))
        #expect(!vm.isShareOptionEnabled(.readeckLink, isOnline: false))
        #expect(vm.isShareOptionEnabled(.originalLink, isOnline: false))
        #expect(vm.isShareOptionEnabled(.pdf, isOnline: false))
        #expect(vm.isShareOptionEnabled(.readeckLink, isOnline: true))
    }

    @Test("The PDF option waits for the article content")
    func pdfOptionNeedsContent() {
        let (vm, _) = createSUT()

        #expect(!vm.isShareOptionEnabled(.pdf, isOnline: true))
    }
}
