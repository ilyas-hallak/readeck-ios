import Testing
import AVFoundation
@testable import readeck

/// Exercises the per-language voice fallback in isolation from the real,
/// possibly-missing system voice catalog `VoiceManager.shared` depends on.
@Suite("VoiceManager per-language voice resolution Tests")
@MainActor
struct VoiceManagerTests {
    private func requireVoice(_ language: String) throws -> AVSpeechSynthesisVoice {
        try #require(AVSpeechSynthesisVoice(language: language))
    }

    @Test("An exact match for the requested language wins")
    func exactMatchWins() throws {
        let ptPT = try requireVoice("pt-PT")

        let resolved = VoiceManager.resolvePerLanguageVoice(
            for: "pt-PT",
            perLanguageVoices: ["pt-PT": ptPT.identifier],
            availableVoices: [ptPT]
        )

        #expect(resolved?.identifier == ptPT.identifier)
    }

    @Test("A choice for a different region of the same language is used as a fallback")
    func sameLanguagePrefixFallsBack() throws {
        let ptPT = try requireVoice("pt-PT")

        // The article resolves to pt-BR, but only a pt-PT voice was ever picked.
        let resolved = VoiceManager.resolvePerLanguageVoice(
            for: "pt-BR",
            perLanguageVoices: ["pt-PT": ptPT.identifier],
            availableVoices: [ptPT]
        )

        #expect(resolved?.identifier == ptPT.identifier)
    }

    @Test("With no choice at all, nothing is resolved")
    func noChoiceResolvesToNil() throws {
        let resolved = VoiceManager.resolvePerLanguageVoice(
            for: "pt-BR",
            perLanguageVoices: [:],
            availableVoices: []
        )

        #expect(resolved == nil)
    }

    @Test("Several same-language choices resolve deterministically")
    func multipleFallbacksPickDeterministically() throws {
        let ptBR = try requireVoice("pt-BR")
        let ptPT = try requireVoice("pt-PT")

        // Sorted by key, "pt-BR" comes before "pt-PT".
        let resolved = VoiceManager.resolvePerLanguageVoice(
            for: "pt-AO",
            perLanguageVoices: ["pt-PT": ptPT.identifier, "pt-BR": ptBR.identifier],
            availableVoices: [ptBR, ptPT]
        )

        #expect(resolved?.identifier == ptBR.identifier)
    }
}
