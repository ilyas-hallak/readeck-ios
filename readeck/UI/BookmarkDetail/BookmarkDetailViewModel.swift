import Foundation
import Combine

@Observable
final class BookmarkDetailViewModel {
    private let getBookmarkUseCase: PGetBookmarkUseCase
    private let getBookmarkArticleUseCase: PGetBookmarkArticleUseCase
    private let loadSettingsUseCase: PLoadSettingsUseCase
    private let updateBookmarkUseCase: PUpdateBookmarkUseCase
    private var addTextToSpeechQueueUseCase: PAddTextToSpeechQueueUseCase?
    private let getCachedArticleUseCase: PGetCachedArticleUseCase
    private let getCachedBookmarkDetailUseCase: PGetCachedBookmarkDetailUseCase
    private let createAnnotationUseCase: PCreateAnnotationUseCase
    private let getBookmarkAnnotationsUseCase: PGetBookmarkAnnotationsUseCase
    private let deleteAnnotationUseCase: PDeleteAnnotationUseCase
    private let deleteBookmarkUseCase: PDeleteBookmarkUseCase
    private let exportArticlePDFUseCase: PExportArticlePDFUseCase
    private let networkMonitorUseCase: PNetworkMonitorUseCase
    private let getServerInfoUseCase: PGetServerInfoUseCase
    private let createShareLinkUseCase: PCreateShareLinkUseCase

    var bookmarkDetail = BookmarkDetail.empty
    var articleContent = ""
    var articleParagraphs: [String] = []
    var annotations: [Annotation] = []
    var bookmark: Bookmark?
    var isLoading = false
    var isLoadingArticle = true
    var errorMessage: String?
    var settings: Settings?
    var readProgress = 0
    var selectedAnnotationId: String?
    var hasAnnotations = false
    var isExportingPDF = false
    var exportedPDFURL: URL?
    var serverCapabilities: ServerCapabilities = .unknown
    var isCreatingShareLink = false
    var shareLinkURL: URL?
    var shareErrorMessage: String?

    // One undo target per new highlight, so removing a highlight also removes its undo action.
    @ObservationIgnored private var highlightUndoTargets: [String: HighlightUndoTarget] = [:]
    @ObservationIgnored private weak var highlightUndoManager: UndoManager?

    var canExportPDF: Bool { !articleContent.isEmpty }
    var canShareReadeckLink: Bool { serverCapabilities.supportsShareLink }
    var canSendByEmail: Bool { serverCapabilities.supportsEmailSharing }

    /// Whether a share-producing task (Readeck link or PDF) is still running. While
    /// true every option stays disabled, so a slow task can't pop an unsolicited
    /// share sheet after the user already shared a different way.
    private var isPreparingShare: Bool { isCreatingShareLink || isExportingPDF }

    /// The share options this server supports, in display order.
    var shareOptions: [ArticleShareOption] {
        ArticleShareOption.allCases.filter { option in
            switch option {
            case .email: canSendByEmail
            case .readeckLink: canShareReadeckLink
            case .originalLink, .pdf: true
            }
        }
    }

    func isShareOptionEnabled(_ option: ArticleShareOption, isOnline: Bool) -> Bool {
        guard !isPreparingShare else { return false }
        return switch option {
        case .email: isOnline
        case .readeckLink: isOnline
        case .originalLink: true
        case .pdf: canExportPDF
        }
    }

    /// Resolves the URL to share for "Share Original Link". Returns nil and sets
    /// `shareErrorMessage` when the bookmark's URL string doesn't parse.
    @MainActor
    func prepareOriginalLinkShare() -> URL? {
        guard let url = URL(string: bookmarkDetail.url) else {
            shareErrorMessage = NSLocalizedString("Could not open the original link", comment: "Original link share error")
            return nil
        }
        return url
    }

    @MainActor
    func clearShareError() {
        shareErrorMessage = nil
    }

    var showProgressBar: Bool { settings?.hideProgressBar != true }
    var showHeroImage: Bool { settings?.hideHeroImage != true }
    var showWordCount: Bool { settings?.hideWordCount != true }
    var hasVisibleHeroImage: Bool { showHeroImage && !bookmarkDetail.imageUrl.isEmpty }
    var canSummarize: Bool { SummarizeArticleUseCase.isAvailable && !articleContent.isEmpty && settings?.hideSummary != true }

    private(set) var summaryViewModel: ArticleSummaryViewModel!

    private var factory: UseCaseFactory?
    private var cancellables = Set<AnyCancellable>()
    private let readProgressSubject = PassthroughSubject<(id: String, progress: Double, anchor: String?), Never>()

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.getBookmarkUseCase = factory.makeGetBookmarkUseCase()
        self.getBookmarkArticleUseCase = factory.makeGetBookmarkArticleUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
        self.updateBookmarkUseCase = factory.makeUpdateBookmarkUseCase()
        self.getCachedArticleUseCase = factory.makeGetCachedArticleUseCase()
        self.getCachedBookmarkDetailUseCase = factory.makeGetCachedBookmarkDetailUseCase()
        self.createAnnotationUseCase = factory.makeCreateAnnotationUseCase()
        self.getBookmarkAnnotationsUseCase = factory.makeGetBookmarkAnnotationsUseCase()
        self.deleteAnnotationUseCase = factory.makeDeleteAnnotationUseCase()
        self.deleteBookmarkUseCase = factory.makeDeleteBookmarkUseCase()
        self.exportArticlePDFUseCase = factory.makeExportArticlePDFUseCase()
        self.networkMonitorUseCase = factory.makeNetworkMonitorUseCase()
        self.getServerInfoUseCase = factory.makeGetServerInfoUseCase()
        self.createShareLinkUseCase = factory.makeCreateShareLinkUseCase()
        self.factory = factory
        self.summaryViewModel = ArticleSummaryViewModel()

        readProgressSubject
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] id, progress, anchor in
                let progressInt = Int(progress * 100)
                Task {
                    await self?.updateReadProgress(id: id, progress: progressInt, anchor: anchor)
                }
            }
            .store(in: &cancellables)
    }

    /// Opens the reader. A cached article is shown at once and the server is only
    /// asked afterwards, so a dead or flaky network never blocks reading.
    @MainActor
    func loadReader(id: String) async {
        guard let cachedHTML = getCachedArticleUseCase.execute(id: id) else {
            await loadBookmarkDetail(id: id)
            // Polling only makes sense when the server answered at all.
            if bookmarkDetail.id == id {
                await waitForArticleReady(id: id)
            }
            await loadArticleContent(id: id)
            return
        }

        try? await loadSettings()
        if let cachedDetail = getCachedBookmarkDetailUseCase.execute(id: id) {
            applyBookmarkDetail(cachedDetail)
        }
        showCachedArticle(cachedHTML, id: id)

        do {
            try await fetchBookmarkDetail(id: id)
        } catch {
            Logger.viewModel.info("⚠️ Showing cached bookmark \(id), server refresh failed: \(error.localizedDescription)")
        }
    }

    /// Switches the app to offline mode, which also cuts off the requests still waiting.
    func goOffline() {
        networkMonitorUseCase.setForcedOffline(true)
    }

    @MainActor
    func loadBookmarkDetail(id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await loadSettings()
            try await fetchBookmarkDetail(id: id)
        } catch {
            // Keep showing the detail we already have, e.g. when offline.
            if bookmarkDetail.id != id {
                if let cachedDetail = getCachedBookmarkDetailUseCase.execute(id: id) {
                    applyBookmarkDetail(cachedDetail)
                } else {
                    errorMessage = "Error loading bookmark"
                }
            }
        }

        isLoading = false
        await loadServerCapabilities()
    }

    /// Without server info the Readeck share options simply stay hidden.
    @MainActor
    private func loadServerCapabilities() async {
        guard let info = try? await getServerInfoUseCase.execute(endpoint: nil) else { return }
        serverCapabilities = info.capabilities
    }

    @MainActor
    private func loadSettings() async throws {
        settings = try await loadSettingsUseCase.execute()
        if settings?.enableTTS == true {
            self.addTextToSpeechQueueUseCase = factory?.makeAddTextToSpeechQueueUseCase()
        }
    }

    @MainActor
    private func fetchBookmarkDetail(id: String) async throws {
        applyBookmarkDetail(try await getBookmarkUseCase.execute(id: id))

        do {
            annotations = try await getBookmarkAnnotationsUseCase.execute(bookmarkId: id)
        } catch {
            // Silent fail, annotations are supplementary
        }
    }

    @MainActor
    private func applyBookmarkDetail(_ detail: BookmarkDetail) {
        bookmarkDetail = detail
        // Always take the higher value between server and local progress
        readProgress = max(readProgress, detail.readProgress ?? 0)
    }

    /// After a bookmark is created the server fetches and extracts the page
    /// asynchronously, so its article isn't available immediately. Polls the bookmark
    /// until the server reports it as `loaded` (or an article shows up) so a freshly
    /// shared article isn't rendered as a blank page. Returns at once when already
    /// ready, so normal navigation is unaffected.
    @MainActor
    func waitForArticleReady(id: String, maxAttempts: Int = 8, delay: TimeInterval = 1.5) async {
        guard !bookmarkDetail.loaded, !bookmarkDetail.hasArticle else { return }

        isLoadingArticle = true
        for attempt in 1...maxAttempts {
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            do {
                let refreshed = try await getBookmarkUseCase.execute(id: id)
                bookmarkDetail = refreshed
                readProgress = max(readProgress, refreshed.readProgress ?? 0)
                if refreshed.loaded || refreshed.hasArticle {
                    Logger.viewModel.info("📦 Bookmark \(id) ready after \(attempt) poll(s)")
                    return
                }
            } catch let error as URLError where error.code == .notConnectedToInternet {
                return
            } catch {
                // Transient, keep polling until the attempts run out.
            }
        }
        Logger.viewModel.info("⏳ Bookmark \(id) still not loaded after \(maxAttempts) polls; showing as-is")
    }

    @MainActor
    func loadArticleContent(id: String, forceRefresh: Bool = false) async {
        isLoadingArticle = true

        // First, try to load from cache (unless force refresh)
        if !forceRefresh, let cachedHTML = getCachedArticleUseCase.execute(id: id) {
            showCachedArticle(cachedHTML, id: id)
            return
        }

        // If not cached or force refresh, fetch from server
        Logger.viewModel.info("📡 Fetching article \(id) from server \(forceRefresh ? "(force refresh)" : "(not in cache)")")
        do {
            presentArticle(try await getBookmarkArticleUseCase.execute(id: id))
            Logger.viewModel.info("✅ Fetched article from server (\(articleContent.utf8.count) bytes)")
        } catch {
            // Keep the article that is already shown, e.g. when a refresh fails offline.
            if articleContent.isEmpty {
                errorMessage = "Error loading article"
            }
            Logger.viewModel.error("❌ Failed to load article: \(error.localizedDescription)")
        }

        isLoadingArticle = false
    }

    @MainActor
    private func showCachedArticle(_ cachedHTML: String, id: String) {
        presentArticle(cachedHTML)
        isLoadingArticle = false
        Logger.viewModel.info("📱 Loaded article \(id) from cache (\(cachedHTML.utf8.count) bytes)")

        // Debug: Check for Base64 images
        let base64Count = countOccurrences(in: cachedHTML, of: "data:image/")
        let httpCount = countOccurrences(in: cachedHTML, of: "src=\"http")
        Logger.viewModel.info("   Images in cached HTML: \(base64Count) Base64, \(httpCount) HTTP")

        // Refresh from server in background to pick up annotations
        // that were added or removed since the article was cached
        Task {
            do {
                let serverHTML = try await getBookmarkArticleUseCase.execute(id: id)
                if AnnotationMarkup.annotationIds(in: serverHTML) != AnnotationMarkup.annotationIds(in: cachedHTML) {
                    Logger.viewModel.info("🔄 Server annotations differ from cache, updating")
                    articleContent = serverHTML
                    processArticleContent()
                }
            } catch {
                Logger.viewModel.info("⚠️ Background refresh failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func presentArticle(_ html: String) {
        articleContent = html
        processArticleContent()
        self.summaryViewModel = ArticleSummaryViewModel(articleContent: html)
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            summaryViewModel.prewarm()
        }
        #endif
    }

    @MainActor
    private func refreshArticleInBackground(id: String) async {
        Logger.viewModel.info("🔄 Background refresh for article \(id) to check for annotations")
        do {
            let serverHTML = try await getBookmarkArticleUseCase.execute(id: id)
            let serverHasAnnotations = serverHTML.contains("<rd-annotation")

            // Only update if server has different annotation state
            if serverHasAnnotations != hasAnnotations || serverHasAnnotations {
                articleContent = serverHTML
                processArticleContent()
                Logger.viewModel.info("✅ Updated article with server content (annotations: \(hasAnnotations))")
            }
        } catch {
            Logger.viewModel.debug("Background refresh failed (offline?): \(error.localizedDescription)")
        }
    }

    private func countOccurrences(in text: String, of substring: String) -> Int {
        text.components(separatedBy: substring).count - 1
    }

    private func processArticleContent() {
        let paragraphs = articleContent
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        articleParagraphs = paragraphs

        // Check if article contains annotations
        hasAnnotations = articleContent.contains("<rd-annotation")
    }

    /// Renders the article as a PDF and publishes the file URL for the share sheet.
    /// Returns whether the export succeeded, so the caller can present either the
    /// share sheet or the error.
    @MainActor
    @discardableResult
    func exportArticleAsPDF() async -> Bool {
        guard !isExportingPDF else { return false }

        isExportingPDF = true
        shareErrorMessage = nil
        exportedPDFURL = nil
        defer { isExportingPDF = false }

        do {
            exportedPDFURL = try await exportArticlePDFUseCase.execute(
                bookmark: bookmarkDetail,
                articleHTML: articleContent,
                settings: settings
            )
            return true
        } catch {
            Logger.viewModel.error("❌ PDF export failed: \(error.localizedDescription)")
            shareErrorMessage = NSLocalizedString("Could not export this article as a PDF", comment: "PDF export error")
            return false
        }
    }

    /// Asks the server for a public link to this bookmark and publishes it for
    /// the share sheet. Returns whether that worked, like the PDF export.
    @MainActor
    @discardableResult
    func createShareLink() async -> Bool {
        guard !isCreatingShareLink else { return false }

        isCreatingShareLink = true
        shareErrorMessage = nil
        shareLinkURL = nil
        defer { isCreatingShareLink = false }

        do {
            shareLinkURL = try await createShareLinkUseCase.execute(bookmarkId: bookmarkDetail.id)
            return true
        } catch {
            Logger.viewModel.error("❌ Share link failed: \(error.localizedDescription)")
            shareErrorMessage = NSLocalizedString("Could not create a share link", comment: "Share link error")
            return false
        }
    }

    @MainActor
    func archiveBookmark(id: String, isArchive: Bool = true) async {
        isLoading = true
        errorMessage = nil
        do {
            try await updateBookmarkUseCase.toggleArchive(bookmarkId: id, isArchived: isArchive)
            bookmarkDetail.isArchived = isArchive
            if isArchive {
                NotificationCenter.default.post(
                    name: .bookmarkArchived,
                    object: nil,
                    userInfo: ["id": id]
                )
            }
        } catch {
            errorMessage = "Error archiving bookmark"
        }
        isLoading = false
    }

    @MainActor
    func deleteBookmark(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            try await deleteBookmarkUseCase.execute(bookmarkId: id)
            isLoading = false
            NotificationCenter.default.post(
                name: .bookmarkDeleted,
                object: nil,
                userInfo: ["id": id]
            )
            return true
        } catch {
            errorMessage = "Error deleting bookmark"
            isLoading = false
            return false
        }
    }

    @MainActor
    func refreshBookmarkDetail(id: String) async {
        await loadBookmarkDetail(id: id)
        await loadArticleContent(id: id, forceRefresh: true)
    }

    func addBookmarkToSpeechQueue() {
        bookmarkDetail.content = articleContent
        addTextToSpeechQueueUseCase?.execute(bookmarkDetail: bookmarkDetail)
    }

    func addBookmarkToSpeechQueueNext() {
        bookmarkDetail.content = articleContent
        var text = bookmarkDetail.title + "\n"
        if !articleContent.isEmpty {
            text += articleContent.stripHTML
        } else {
            text += bookmarkDetail.description.stripHTML
        }
        SpeechQueue.shared.insertAfterCurrent(bookmarkDetail.toSpeechQueueItem(text))
    }

    @MainActor
    func toggleFavorite(id: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let newValue = !bookmarkDetail.isMarked
            try await updateBookmarkUseCase.toggleFavorite(bookmarkId: id, isMarked: newValue)
            bookmarkDetail.isMarked = newValue
        } catch {
            errorMessage = "Error updating favorite status"
        }
        isLoading = false
    }

    func updateReadProgress(id: String, progress: Int, anchor: String?) async {
        // Only update if the new progress is higher than current
        if progress > readProgress {
            do {
                try await updateBookmarkUseCase.updateReadProgress(bookmarkId: id, progress: progress, anchor: anchor)
            } catch {
                // ignore error in this case
            }
        }
    }

    func debouncedUpdateReadProgress(id: String, progress: Double, anchor: String?) {
        readProgressSubject.send((id, progress, anchor))
    }

    /// Registers the new highlight with `undoManager`, so shake to undo removes it again.
    @MainActor
    func createAnnotation(
        bookmarkId: String,
        color: String,
        text: String,
        startOffset: Int,
        endOffset: Int,
        startSelector: String,
        endSelector: String,
        undoManager: UndoManager? = nil
    ) async {
        do {
            let annotation = try await createAnnotationUseCase.execute(
                bookmarkId: bookmarkId,
                color: color,
                startOffset: startOffset,
                endOffset: endOffset,
                startSelector: startSelector,
                endSelector: endSelector
            )
            Logger.viewModel.info("✅ Annotation created: \(annotation.id)")
            annotations.append(annotation)
            hasAnnotations = true
            registerUndo(of: annotation.id, bookmarkId: bookmarkId, with: undoManager)
            await refreshArticleInBackground(id: bookmarkId)
        } catch {
            Logger.viewModel.error("❌ Failed to create annotation: \(error.localizedDescription)")
            // Check for specific error messages from server
            if error.localizedDescription.contains("overlapping") {
                errorMessage = NSLocalizedString("This text overlaps with an existing highlight", comment: "Overlapping annotation error")
            } else {
                errorMessage = NSLocalizedString("Error creating highlight", comment: "Generic annotation error")
            }
        }
    }

    /// Removes a highlight and re-renders the article without it.
    @MainActor
    @discardableResult
    func deleteAnnotation(bookmarkId: String, annotationId: String) async -> Bool {
        do {
            try await deleteAnnotationUseCase.execute(bookmarkId: bookmarkId, annotationId: annotationId)
            removeAnnotationLocally(id: annotationId)
            await refreshArticleInBackground(id: bookmarkId)
            return true
        } catch {
            Logger.viewModel.error("❌ Failed to delete annotation: \(error.localizedDescription)")
            errorMessage = NSLocalizedString("Error removing highlight", comment: "Annotation delete error")
            return false
        }
    }

    /// Brings the reader in sync with a highlight deleted elsewhere (the Annotations sheet),
    /// so shake-to-undo and the article content don't keep pointing at a removed highlight.
    @MainActor
    func annotationWasDeleted(id: String, bookmarkId: String) {
        removeAnnotationLocally(id: id)
        Task {
            await refreshArticleInBackground(id: bookmarkId)
        }
    }

    /// Drops the annotation from state and strips its markup from the article right away,
    /// instead of waiting for `refreshArticleInBackground`, which silently fails offline.
    private func removeAnnotationLocally(id: String) {
        annotations.removeAll { $0.id == id }
        discardUndo(of: id)
        articleContent = AnnotationMarkup.removingAnnotation(id: id, from: articleContent)
        processArticleContent()
    }

    func annotationText(for annotationId: String) -> String? {
        annotations.first { $0.id == annotationId }?.text
    }

    /// Drops the undo actions of all new highlights, e.g. when the article is closed.
    func discardHighlightUndo() {
        for annotationId in highlightUndoTargets.keys {
            discardUndo(of: annotationId)
        }
    }

    private func registerUndo(of annotationId: String, bookmarkId: String, with undoManager: UndoManager?) {
        guard let undoManager else { return }
        let target = HighlightUndoTarget()
        highlightUndoTargets[annotationId] = target
        highlightUndoManager = undoManager
        undoManager.registerUndo(withTarget: target) { [weak self] _ in
            Task { @MainActor in
                await self?.deleteAnnotation(bookmarkId: bookmarkId, annotationId: annotationId)
            }
        }
        undoManager.setActionName(NSLocalizedString("Highlight", comment: "Undo action name for a new highlight"))
    }

    private func discardUndo(of annotationId: String) {
        guard let target = highlightUndoTargets.removeValue(forKey: annotationId) else { return }
        highlightUndoManager?.removeAllActions(withTarget: target)
    }
}

private final class HighlightUndoTarget {}
