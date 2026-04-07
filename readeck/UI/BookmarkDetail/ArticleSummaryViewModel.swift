import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@Observable
final class ArticleSummaryViewModel {
    private let summarizeUseCase: PSummarizeArticleUseCase
    private let articleContent: String
    private var currentTask: Task<Void, Never>?

    var summaryMarkdown: String = ""
    var isLoading: Bool = false
    var isExpanded: Bool = false
    var error: Error?
    var selectedLanguage: String
    var hasGenerated: Bool = false

    var availableLanguages: [(code: String, displayName: String)] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SummarizeArticleUseCase.supportedLanguages.compactMap { lang in
                guard let code = lang.languageCode?.identifier else { return nil }
                let displayName = Locale.current.localizedString(forLanguageCode: code) ?? code
                return (code: code, displayName: displayName)
            }
            .sorted { $0.displayName < $1.displayName }
        }
        #endif
        return []
    }

    init(articleContent: String, summarizeUseCase: PSummarizeArticleUseCase) {
        self.articleContent = articleContent
        self.summarizeUseCase = summarizeUseCase
        self.selectedLanguage = Locale.current.language.languageCode?.identifier ?? "en"
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    func prewarm() {
        let session = LanguageModelSession()
        session.prewarm()
    }
    #endif

    @MainActor
    func summarize() async {
        currentTask?.cancel()
        isLoading = true
        isExpanded = true
        error = nil
        summaryMarkdown = ""

        let displayName = Locale.current.localizedString(forLanguageCode: selectedLanguage) ?? selectedLanguage

        do {
            try Task.checkCancellation()
            summaryMarkdown = try await summarizeUseCase.execute(
                articleHTML: articleContent,
                targetLanguage: displayName
            )
            hasGenerated = true
        } catch is CancellationError {
            return
        } catch {
            self.error = error
        }

        isLoading = false
    }
}
