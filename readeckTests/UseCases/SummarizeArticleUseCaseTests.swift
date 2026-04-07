import Testing
import Foundation
@testable import readeck

@Suite("SummarizeArticleUseCase Tests")
struct SummarizeArticleUseCaseTests {

    @Test("execute throws emptyContent for whitespace-only input")
    func executeEmptyContent() async {
        let useCase = SummarizeArticleUseCase(repository: MockSummarizationRepository())
        do {
            _ = try await useCase.execute(articleHTML: "   ", targetLanguage: "English")
            #expect(Bool(false), "Should have thrown")
        } catch let error as SummarizeArticleError {
            #expect(error == .emptyContent)
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("lengthInstruction returns correct instruction for short articles")
    func shortLengthInstruction() {
        let instruction = SummarizeArticleUseCase.lengthInstruction(for: 100)
        #expect(instruction.contains("2-3 sentences"))
    }

    @Test("lengthInstruction returns correct instruction for medium articles")
    func mediumLengthInstruction() {
        let instruction = SummarizeArticleUseCase.lengthInstruction(for: 1000)
        #expect(instruction.contains("short paragraph"))
    }

    @Test("lengthInstruction returns correct instruction for long articles")
    func longLengthInstruction() {
        let instruction = SummarizeArticleUseCase.lengthInstruction(for: 3000)
        #expect(instruction.contains("multiple paragraphs"))
    }

    @Test("buildInstructions includes language and length")
    func buildInstructions() {
        let result = SummarizeArticleUseCase.buildInstructions(lengthInstruction: "Be brief.", targetLanguage: "German")
        #expect(result.contains("Be brief."))
        #expect(result.contains("German"))
    }
}

class MockSummarizationRepository: PSummarizationRepository {
    static var isAvailable: Bool { true }
    static var supportedLanguages: [String] { ["en-US", "de-DE"] }
    var summarizeCallCount = 0
    var lastInstructions: String?

    func summarize(text: String, instructions: String) async throws -> String {
        summarizeCallCount += 1
        lastInstructions = instructions
        return "Mock summary"
    }

    func prewarm() {}
}
