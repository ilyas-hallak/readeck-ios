import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

final class SummarizationRepository: PSummarizationRepository {

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    static var supportedLanguages: [String] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.supportedLanguages.compactMap { lang in
                lang.maximalIdentifier
            }
        }
        #endif
        return []
    }

    func prewarm() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession()
            session.prewarm()
        }
        #endif
    }

    func summarize(text: String, instructions: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: instructions)
            do {
                let response = try await session.respond(to: text)
                return response.content
            } catch let error as LanguageModelSession.GenerationError {
                if case .refusal(let refusal, _) = error {
                    let explanation = (try? await refusal.explanation)?.content ?? "The model refused to summarize this content."
                    throw SummarizeArticleError.generationFailed(explanation)
                }
                throw SummarizeArticleError.generationFailed(error.localizedDescription)
            }
        }
        #endif
        throw SummarizeArticleError.modelNotAvailable
    }
}
