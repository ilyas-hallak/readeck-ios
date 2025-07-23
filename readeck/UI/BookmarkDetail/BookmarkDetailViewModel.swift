import Foundation
import Combine

@Observable
class BookmarkDetailViewModel {
    private let getBookmarkUseCase: PGetBookmarkUseCase
    private let getBookmarkArticleUseCase: PGetBookmarkArticleUseCase
    private let loadSettingsUseCase: PLoadSettingsUseCase
    private let updateBookmarkUseCase: PUpdateBookmarkUseCase
    private var addTextToSpeechQueueUseCase: PAddTextToSpeechQueueUseCase?
    
    var bookmarkDetail: BookmarkDetail = BookmarkDetail.empty
    var articleContent: String = ""
    var articleParagraphs: [String] = []
    var bookmark: Bookmark? = nil
    var isLoading = false
    var isLoadingArticle = true
    var errorMessage: String?
    var settings: Settings?
    var readProgress: Int = 0
    
    private var factory: UseCaseFactory?
    private var cancellables = Set<AnyCancellable>()
    private let readProgressSubject = PassthroughSubject<(id: String, progress: Double, anchor: String?), Never>()
    
    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.getBookmarkUseCase = factory.makeGetBookmarkUseCase()
        self.getBookmarkArticleUseCase = factory.makeGetBookmarkArticleUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
        self.updateBookmarkUseCase = factory.makeUpdateBookmarkUseCase()
        self.factory = factory
        
        readProgressSubject
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] (id, progress, anchor) in
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
            readProgress = bookmarkDetail.readProgress ?? 0
            
            if settings?.enableTTS == true {
                self.addTextToSpeechQueueUseCase = factory?.makeAddTextToSpeechQueueUseCase()
            }
        } catch {
            errorMessage = "Error loading bookmark"
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadArticleContent(id: String) async {
        isLoadingArticle = true
        
        do {
            articleContent = try await getBookmarkArticleUseCase.execute(id: id)
            processArticleContent()
        } catch {
            errorMessage = "Error loading article"
        }
        
        isLoadingArticle = false
    }
    
    private func processArticleContent() {
        let paragraphs = articleContent
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        articleParagraphs = paragraphs
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
    }
    
    func addBookmarkToSpeechQueue() {
        bookmarkDetail.content = articleContent
        addTextToSpeechQueueUseCase?.execute(bookmarkDetail: bookmarkDetail)
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
        do {
            try await updateBookmarkUseCase.updateReadProgress(bookmarkId: id, progress: progress, anchor: anchor)
        } catch {            
            // ignore error in this case
        }
    }
    
    func debouncedUpdateReadProgress(id: String, progress: Double, anchor: String?) {
        readProgressSubject.send((id, progress, anchor))
    }
}
