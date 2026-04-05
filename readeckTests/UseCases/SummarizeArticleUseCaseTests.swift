import Testing
import Foundation
@testable import readeck

@Suite("SummarizeArticleUseCase Tests")
struct SummarizeArticleUseCaseTests {

    // MARK: - HTML Stripping

    @Test("stripHTML removes tags and returns plain text")
    func stripHTMLRemovesTags() {
        let useCase = SummarizeArticleUseCase()
        let html = "<p>Hello <strong>world</strong></p>"
        let result = useCase.stripHTML(html)
        #expect(result.contains("Hello"))
        #expect(result.contains("world"))
        #expect(!result.contains("<p>"))
        #expect(!result.contains("<strong>"))
    }

    @Test("stripHTML handles empty string")
    func stripHTMLEmpty() {
        let useCase = SummarizeArticleUseCase()
        let result = useCase.stripHTML("")
        #expect(result.isEmpty)
    }

    // MARK: - Chunking

    @Test("splitIntoChunks returns single chunk for short text")
    func splitShortText() {
        let useCase = SummarizeArticleUseCase()
        let text = "Short text."
        let chunks = useCase.splitIntoChunks(text: text)
        #expect(chunks.count == 1)
        #expect(chunks[0] == "Short text.")
    }

    @Test("splitIntoChunks splits at paragraph boundaries")
    func splitAtParagraphs() {
        let useCase = SummarizeArticleUseCase()
        // Create text that exceeds maxChunkCharacters (12000)
        let paragraph = String(repeating: "word ", count: 2000) // ~10000 chars
        let text = paragraph + "\n\n" + paragraph
        let chunks = useCase.splitIntoChunks(text: text)
        #expect(chunks.count == 2)
    }

    @Test("splitIntoChunks handles empty text")
    func splitEmptyText() {
        let useCase = SummarizeArticleUseCase()
        let chunks = useCase.splitIntoChunks(text: "")
        #expect(chunks.isEmpty)
    }

    // MARK: - Execute with empty content

    @Test("execute throws emptyContent for whitespace-only input")
    func executeEmptyContent() async {
        let useCase = SummarizeArticleUseCase()
        do {
            _ = try await useCase.execute(articleHTML: "   ", targetLanguage: "English")
            #expect(Bool(false), "Should have thrown")
        } catch let error as SummarizeArticleError {
            #expect(error == .emptyContent)
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    // MARK: - Summary Length Instruction

    @Test("short article gets single chunk")
    func shortArticleInstruction() {
        let useCase = SummarizeArticleUseCase()
        let shortText = String(repeating: "word ", count: 100) // ~100 words
        let chunks = useCase.splitIntoChunks(text: shortText)
        #expect(chunks.count == 1)
    }
}
