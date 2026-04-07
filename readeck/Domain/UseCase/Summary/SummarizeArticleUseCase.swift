import Foundation

protocol PSummarizeArticleUseCase {
    func execute(articleHTML: String, targetLanguage: String) async throws -> String
    func prewarm()
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

    private let repository: PSummarizationRepository

    init(repository: PSummarizationRepository) {
        self.repository = repository
    }

    static var isAvailable: Bool {
        SummarizationRepository.isAvailable
    }

    func prewarm() {
        repository.prewarm()
    }

    func execute(articleHTML: String, targetLanguage: String) async throws -> String {
        let plainText = HTMLStringUtils.stripHTML(articleHTML)

        guard !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummarizeArticleError.emptyContent
        }

        let wordCount = plainText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let lengthInstruction = Self.lengthInstruction(for: wordCount)

        let chunks = HTMLStringUtils.splitIntoChunks(text: plainText)

        if chunks.count <= 1 {
            let instructions = Self.buildInstructions(lengthInstruction: lengthInstruction, targetLanguage: targetLanguage)
            return try await repository.summarize(text: plainText, instructions: instructions)
        } else {
            return try await summarizeChunks(chunks, targetLanguage: targetLanguage, lengthInstruction: lengthInstruction)
        }
    }

    // MARK: - Chunked Summarization

    private func summarizeChunks(_ chunks: [String], targetLanguage: String, lengthInstruction: String) async throws -> String {
        var partialSummaries: [String] = []

        let chunkInstructions = Self.buildInstructions(
            lengthInstruction: "Summarize this section concisely.",
            targetLanguage: targetLanguage
        )

        for chunk in chunks {
            let summary = try await repository.summarize(text: chunk, instructions: chunkInstructions)
            partialSummaries.append(summary)
        }

        let merged = partialSummaries.joined(separator: "\n\n")

        let mergeChunks = HTMLStringUtils.splitIntoChunks(text: merged)
        if mergeChunks.count <= 1 {
            let mergeInstructions = Self.buildInstructions(
                lengthInstruction: "\(lengthInstruction) Combine these partial summaries into one coherent summary. Remove redundancies and maintain logical flow.",
                targetLanguage: targetLanguage
            )
            return try await repository.summarize(text: merged, instructions: mergeInstructions)
        } else {
            return try await summarizeChunks(mergeChunks, targetLanguage: targetLanguage, lengthInstruction: lengthInstruction)
        }
    }

    // MARK: - Prompt Building

    static func buildInstructions(lengthInstruction: String, targetLanguage: String) -> String {
        "You are a summarization assistant. \(lengthInstruction) Write the summary in \(targetLanguage). Focus on the key points and main arguments."
    }

    static func lengthInstruction(for wordCount: Int) -> String {
        if wordCount < 500 {
            return "Summarize in 2-3 sentences."
        } else if wordCount <= 2000 {
            return "Summarize in a short paragraph."
        } else {
            return "Summarize in multiple paragraphs."
        }
    }
}
