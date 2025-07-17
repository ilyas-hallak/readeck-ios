import Foundation

@Observable
class BookmarkDetailViewModel {
    private let getBookmarkUseCase: PGetBookmarkUseCase
    private let getBookmarkArticleUseCase: PGetBookmarkArticleUseCase
    private let loadSettingsUseCase: PLoadSettingsUseCase
    private let updateBookmarkUseCase: PUpdateBookmarkUseCase
    private let addTextToSpeechQueueUseCase: PAddTextToSpeechQueueUseCase
    
    var bookmarkDetail: BookmarkDetail = BookmarkDetail.empty
    var articleContent: String = ""
    var articleParagraphs: [String] = []
    var bookmark: Bookmark? = nil
    var isLoading = false
    var isLoadingArticle = true
    var errorMessage: String?
    var settings: Settings?
    
    init(_  factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.getBookmarkUseCase = factory.makeGetBookmarkUseCase()
        self.getBookmarkArticleUseCase = factory.makeGetBookmarkArticleUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
        self.updateBookmarkUseCase = factory.makeUpdateBookmarkUseCase()
        self.addTextToSpeechQueueUseCase = factory.makeAddTextToSpeechQueueUseCase()
    }
    
    @MainActor
    func loadBookmarkDetail(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            settings = try await loadSettingsUseCase.execute()            
            bookmarkDetail = try await getBookmarkUseCase.execute(id: id)
        } catch {
            errorMessage = "Fehler beim Laden des Bookmarks"
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
            errorMessage = "Fehler beim Laden des Artikels"
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
    func archiveBookmark(id: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await updateBookmarkUseCase.toggleArchive(bookmarkId: id, isArchived: true)
            bookmarkDetail.isArchived = true
        } catch {
            errorMessage = "Fehler beim Archivieren des Bookmarks"
        }
        isLoading = false
    }
    
    @MainActor
    func refreshBookmarkDetail(id: String) async {
        await loadBookmarkDetail(id: id)
    }
    
    func addBookmarkToSpeechQueue() {
        bookmarkDetail.content = articleContent
        addTextToSpeechQueueUseCase.execute(bookmarkDetail: bookmarkDetail)
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
            errorMessage = "Fehler beim Aktualisieren des Favoriten-Status"
        }
        isLoading = false
    }
}
