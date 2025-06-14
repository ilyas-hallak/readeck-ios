import Foundation

@Observable
class BookmarkDetailViewModel {
    private let getBookmarkUseCase: GetBookmarkUseCase
    private let getBookmarkArticleUseCase: GetBookmarkArticleUseCase
    private let loadSettingsUseCase: LoadSettingsUseCase
    
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
    }
    
    @MainActor
    func loadBookmarkDetail(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            settings = try await loadSettingsUseCase.execute()            
            bookmarkDetail = try await getBookmarkUseCase.execute(id: id)
            
            // Auch das vollständige Bookmark für readProgress laden
            // (Falls GetBookmarkUseCase nur BookmarkDetail zurückgibt)
            // Du könntest einen separaten UseCase für das vollständige Bookmark erstellen
            
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
        // HTML in Paragraphen aufteilen
        let paragraphs = articleContent
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        articleParagraphs = paragraphs
    }
}

extension BookmarkDetail {
    static let empty = BookmarkDetail(
        id: "",
        title: "",
        url: "",
        description: "",
        siteName: "",
        authors: [],
        created: "",
        updated: "",
        wordCount: 0,
        readingTime: 0,
        hasArticle: false,
        isMarked: false,
        isArchived: false,
        thumbnailUrl: "",
        imageUrl: ""
    )
}
