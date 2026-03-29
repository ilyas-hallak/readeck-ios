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
    private let createAnnotationUseCase: PCreateAnnotationUseCase

    var bookmarkDetail = BookmarkDetail.empty
    var articleContent = ""
    var articleParagraphs: [String] = []
    var bookmark: Bookmark?
    var isLoading = false
    var isLoadingArticle = true
    var errorMessage: String?
    var settings: Settings?
    var readProgress = 0
    var selectedAnnotationId: String?
    var hasAnnotations = false

    var showProgressBar: Bool { settings?.hideProgressBar != true }
    var showHeroImage: Bool { settings?.hideHeroImage != true }
    var showWordCount: Bool { settings?.hideWordCount != true }
    var hasVisibleHeroImage: Bool { showHeroImage && !bookmarkDetail.imageUrl.isEmpty }

    private var factory: UseCaseFactory?
    private var cancellables = Set<AnyCancellable>()
    private let readProgressSubject = PassthroughSubject<(id: String, progress: Double, anchor: String?), Never>()

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.getBookmarkUseCase = factory.makeGetBookmarkUseCase()
        self.getBookmarkArticleUseCase = factory.makeGetBookmarkArticleUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
        self.updateBookmarkUseCase = factory.makeUpdateBookmarkUseCase()
        self.getCachedArticleUseCase = factory.makeGetCachedArticleUseCase()
        self.createAnnotationUseCase = factory.makeCreateAnnotationUseCase()
        self.factory = factory

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

    @MainActor
    func loadBookmarkDetail(id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            settings = try await loadSettingsUseCase.execute()
            bookmarkDetail = try await getBookmarkUseCase.execute(id: id)

            // Always take the higher value between server and local progress
            let serverProgress = bookmarkDetail.readProgress ?? 0
            readProgress = max(readProgress, serverProgress)

            if settings?.enableTTS == true {
                self.addTextToSpeechQueueUseCase = factory?.makeAddTextToSpeechQueueUseCase()
            }
        } catch {
            errorMessage = "Error loading bookmark"
        }

        isLoading = false
    }

    @MainActor
    func loadArticleContent(id: String, forceRefresh: Bool = false) async {
        isLoadingArticle = true

        // First, try to load from cache (unless force refresh)
        if !forceRefresh, let cachedHTML = getCachedArticleUseCase.execute(id: id) {
            articleContent = cachedHTML
            processArticleContent()
            isLoadingArticle = false
            Logger.viewModel.info("📱 Loaded article \(id) from cache (\(cachedHTML.utf8.count) bytes)")

            // Debug: Check for Base64 images
            let base64Count = countOccurrences(in: cachedHTML, of: "data:image/")
            let httpCount = countOccurrences(in: cachedHTML, of: "src=\"http")
            Logger.viewModel.info("   Images in cached HTML: \(base64Count) Base64, \(httpCount) HTTP")

            // Refresh from server in background to pick up annotations
            // that may have been added since the article was cached
            Task {
                do {
                    let serverHTML = try await getBookmarkArticleUseCase.execute(id: id)
                    if serverHTML.contains("<rd-annotation") && !cachedHTML.contains("<rd-annotation") {
                        Logger.viewModel.info("🔄 Server has annotations not in cache, updating")
                        articleContent = serverHTML
                        processArticleContent()
                    }
                } catch {
                    Logger.viewModel.info("⚠️ Background refresh failed: \(error.localizedDescription)")
                }
            }

            return
        }

        // If not cached or force refresh, fetch from server
        Logger.viewModel.info("📡 Fetching article \(id) from server \(forceRefresh ? "(force refresh)" : "(not in cache)")")
        do {
            articleContent = try await getBookmarkArticleUseCase.execute(id: id)
            processArticleContent()
            Logger.viewModel.info("✅ Fetched article from server (\(articleContent.utf8.count) bytes)")
        } catch {
            errorMessage = "Error loading article"
            Logger.viewModel.error("❌ Failed to load article: \(error.localizedDescription)")
        }

        isLoadingArticle = false
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

    @MainActor
    func archiveBookmark(id: String, isArchive: Bool = true) async {
        isLoading = true
        errorMessage = nil
        do {
            try await updateBookmarkUseCase.toggleArchive(bookmarkId: id, isArchived: isArchive)
            bookmarkDetail.isArchived = true
        } catch {
            errorMessage = "Error archiving bookmark"
        }
        isLoading = false
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

    @MainActor
    func createAnnotation(bookmarkId: String, color: String, text: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async {
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
            hasAnnotations = true
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
}
