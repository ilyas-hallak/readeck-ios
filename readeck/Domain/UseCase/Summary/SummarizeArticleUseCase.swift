import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

protocol PSummarizeArticleUseCase {
    func execute(articleHTML: String, targetLanguage: String) async throws -> String
    static var isAvailable: Bool { get }
}

enum SummarizeArticleError: LocalizedError, Equatable {
    case modelNotAvailable
    case emptyContent
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "AI summarization is not available on this device.".localized
        case .emptyContent:
            return "No article content to summarize.".localized
        case .generationFailed(let message):
            return message
        }
    }
}

final class SummarizeArticleUseCase: PSummarizeArticleUseCase {

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    static var supportedLanguages: [Locale.Language] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return Array(SystemLanguageModel.default.supportedLanguages)
        }
        #endif
        return []
    }

    private let maxChunkCharacters = 12_000

    func execute(articleHTML: String, targetLanguage: String) async throws -> String {
        let plainText = stripHTML(articleHTML)

        guard !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummarizeArticleError.emptyContent
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return try await summarize(text: plainText, targetLanguage: targetLanguage)
        }
        #endif
        throw SummarizeArticleError.modelNotAvailable
    }

    // MARK: - HTML Stripping

    func stripHTML(_ html: String) -> String {
        var text = html
        // Remove script and style blocks
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        // Replace <br>, <p>, <div> with newlines
        text = text.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: .regularExpression)
        // Remove all remaining tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Decode common HTML entities
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        // Collapse multiple newlines
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Summarization

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func summarize(text: String, targetLanguage: String) async throws -> String {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let lengthInstruction = summaryLengthInstruction(wordCount: wordCount)

        if text.count <= maxChunkCharacters {
            return try await summarizeSingleChunk(text: text, targetLanguage: targetLanguage, lengthInstruction: lengthInstruction)
        } else {
            return try await summarizeWithChunking(text: text, targetLanguage: targetLanguage, lengthInstruction: lengthInstruction)
        }
    }

    @available(iOS 26.0, *)
    private func summarizeSingleChunk(text: String, targetLanguage: String, lengthInstruction: String) async throws -> String {
        let instructions = """
            You are a summarization assistant. \(lengthInstruction) \
            Write the summary in \(targetLanguage). \
            Focus on the key points and main arguments.
            """

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

    @available(iOS 26.0, *)
    private func summarizeWithChunking(text: String, targetLanguage: String, lengthInstruction: String) async throws -> String {
        let chunks = splitIntoChunks(text: text)
        var partialSummaries: [String] = []

        for chunk in chunks {
            let instructions = """
                You are a summarization assistant. Summarize the following text section concisely. \
                Write the summary in \(targetLanguage). Focus on the key points.
                """
            let session = LanguageModelSession(instructions: instructions)
            do {
                let response = try await session.respond(to: chunk)
                partialSummaries.append(response.content)
            } catch let error as LanguageModelSession.GenerationError {
                if case .refusal(let refusal, _) = error {
                    let explanation = (try? await refusal.explanation)?.content ?? "The model refused to summarize this content."
                    throw SummarizeArticleError.generationFailed(explanation)
                }
                throw SummarizeArticleError.generationFailed(error.localizedDescription)
            }
        }

        let merged = partialSummaries.joined(separator: "\n\n")

        // If merged summaries fit in one chunk, do a final merge
        if merged.count <= maxChunkCharacters {
            let mergeInstructions = """
                You are a summarization assistant. \(lengthInstruction) \
                Combine the following partial summaries into one coherent summary. \
                Write the summary in \(targetLanguage). Remove redundancies and maintain logical flow.
                """
            let mergeSession = LanguageModelSession(instructions: mergeInstructions)
            do {
                let mergeResponse = try await mergeSession.respond(to: merged)
                return mergeResponse.content
            } catch let error as LanguageModelSession.GenerationError {
                if case .refusal(let refusal, _) = error {
                    let explanation = (try? await refusal.explanation)?.content ?? "The model refused to summarize this content."
                    throw SummarizeArticleError.generationFailed(explanation)
                }
                throw SummarizeArticleError.generationFailed(error.localizedDescription)
            }
        } else {
            // Recursive: summarize the summaries
            return try await summarizeWithChunking(text: merged, targetLanguage: targetLanguage, lengthInstruction: lengthInstruction)
        }
    }
    #endif

    // MARK: - Chunking

    func splitIntoChunks(text: String) -> [String] {
        let paragraphs = text.components(separatedBy: "\n\n")
        var chunks: [String] = []
        var currentChunk = ""

        for paragraph in paragraphs {
            if currentChunk.count + paragraph.count + 2 > maxChunkCharacters {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                    currentChunk = ""
                }
                // If a single paragraph exceeds the limit, split it further
                if paragraph.count > maxChunkCharacters {
                    let sentences = paragraph.components(separatedBy: ". ")
                    for sentence in sentences {
                        if currentChunk.count + sentence.count + 2 > maxChunkCharacters {
                            if !currentChunk.isEmpty {
                                chunks.append(currentChunk)
                                currentChunk = ""
                            }
                        }
                        currentChunk += (currentChunk.isEmpty ? "" : ". ") + sentence
                    }
                } else {
                    currentChunk = paragraph
                }
            } else {
                currentChunk += (currentChunk.isEmpty ? "" : "\n\n") + paragraph
            }
        }
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        return chunks
    }

    // MARK: - Length Instruction

    private func summaryLengthInstruction(wordCount: Int) -> String {
        if wordCount < 500 {
            return "Summarize in 2-3 sentences."
        } else if wordCount <= 2000 {
            return "Summarize in a short paragraph."
        } else {
            return "Summarize in multiple paragraphs."
        }
    }
}
