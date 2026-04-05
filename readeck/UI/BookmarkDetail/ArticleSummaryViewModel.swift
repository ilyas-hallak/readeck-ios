import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@Observable
final class ArticleSummaryViewModel {
    private let summarizeUseCase: PSummarizeArticleUseCase
    private let articleContent: String
    private var currentTask: Task<Void, Never>?

    var summary: String = ""
    var isLoading: Bool = true
    var error: Error?
    var selectedLanguage: String

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

    @MainActor
    func summarize() async {
        currentTask?.cancel()
        isLoading = true
        error = nil
        summary = ""

        let displayName = Locale.current.localizedString(forLanguageCode: selectedLanguage) ?? selectedLanguage

        do {
            try Task.checkCancellation()
            summary = try await summarizeUseCase.execute(
                articleHTML: articleContent,
                targetLanguage: displayName
            )
        } catch is CancellationError {
            // Ignore - new task will take over
            return
        } catch {
            self.error = error
        }

        isLoading = false
    }
}
