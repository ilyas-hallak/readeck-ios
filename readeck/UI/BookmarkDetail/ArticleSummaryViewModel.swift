import Foundation

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
        SummarizationRepository.supportedLanguages.map { identifier in
            let locale = Locale(identifier: identifier)
            let langCode = locale.language.languageCode?.identifier ?? identifier
            var displayName = Locale.current.localizedString(forLanguageCode: langCode) ?? langCode
            if let region = locale.language.region {
                let regionName = Locale.current.localizedString(forRegionCode: region.identifier) ?? region.identifier
                displayName = "\(displayName) (\(regionName))"
            }
            return (code: identifier, displayName: displayName)
        }
        .sorted { $0.displayName < $1.displayName }
    }

    init(articleContent: String, summarizeUseCase: PSummarizeArticleUseCase) {
        self.articleContent = articleContent
        self.summarizeUseCase = summarizeUseCase
        self.selectedLanguage = Locale.current.language.maximalIdentifier
    }

    func prewarm() {
        summarizeUseCase.prewarm()
    }

    @MainActor
    func summarize() async {
        currentTask?.cancel()
        isLoading = true
        isExpanded = true
        error = nil
        summaryMarkdown = ""

        let locale = Locale(identifier: selectedLanguage)
        let langCode = locale.language.languageCode?.identifier ?? selectedLanguage
        let displayName = Locale.current.localizedString(forLanguageCode: langCode) ?? selectedLanguage

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
