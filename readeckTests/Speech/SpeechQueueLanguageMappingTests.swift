import Testing
@testable import readeck

@Suite("SpeechQueue language mapping Tests")
@MainActor
struct SpeechQueueLanguageMappingTests {
    @Test("Portuguese articles resolve to the European voice locale")
    func portugueseResolvesToEuropeanLocale() {
        #expect(SpeechQueue.convertToBCP47("pt") == "pt-PT")
    }

    @Test("A BCP 47 code is passed through unchanged")
    func bcp47CodeIsPassedThrough() {
        #expect(SpeechQueue.convertToBCP47("pt-BR") == "pt-BR")
    }

    @Test("An unmapped ISO code falls back to repeating it as the region")
    func unmappedCodeFallsBackToUppercasedRegion() {
        #expect(SpeechQueue.convertToBCP47("xx") == "xx-XX")
    }
}
