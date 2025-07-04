import Foundation

@Observable
class BookmarkDetailViewModel {
    private let getBookmarkUseCase: GetBookmarkUseCase
    private let getBookmarkArticleUseCase: GetBookmarkArticleUseCase
    private let loadSettingsUseCase: LoadSettingsUseCase
    private let updateBookmarkUseCase: UpdateBookmarkUseCase
    
    var bookmarkDetail: BookmarkDetail = BookmarkDetail.empty
    var articleContent: String = ""
    var articleParagraphs: [String] = []
    var bookmark: Bookmark? = nil
    var isLoading = false
    var isLoadingArticle = false
    var errorMessage: String?
    var settings: Settings?
    
    init() {
        let factory = DefaultUseCaseFactory.shared
        self.getBookmarkUseCase = factory.makeGetBookmarkUseCase()
        self.getBookmarkArticleUseCase = factory.makeGetBookmarkArticleUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
        self.updateBookmarkUseCase = factory.makeUpdateBookmarkUseCase()
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
}
