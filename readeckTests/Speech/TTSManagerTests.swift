import Testing
import Foundation
import AVFoundation
@testable import readeck

/// Guards the Swift 6 migration of the AVSpeechSynthesizerDelegate callbacks:
/// they are `nonisolated` and hop through `MainThread.run`, which must keep
/// applying a position update at the moment the callback fires, not whenever
/// the hop to the main actor happens to run.
@Suite("TTSManager Tests", .serialized)
@MainActor
struct TTSManagerTests {

    @Test("A position update from the delegate callback applies synchronously")
    func positionUpdateAppliesSynchronously() {
        let tts = TTSManager.shared
        tts.speak(text: "First article text", language: "en")
        tts.stop()

        tts.speechSynthesizer(
            AVSpeechSynthesizer(),
            willSpeakRangeOfSpeechString: NSRange(location: 0, length: 5),
            utterance: AVSpeechUtterance(string: "")
        )

        // No `await` or run loop turn happened between the callback and this
        // assertion. If the main-actor hop were still deferred (a plain
        // DispatchQueue.main.async always defers), currentCharacterIndex
        // would still be 0 here, and a seek landing in that gap would combine
        // this callback's spoken count with the seek's new offset/text.
        #expect(tts.currentCharacterIndex == 5)

        // A seek right after the callback must land cleanly on top of it,
        // not combine with the already-applied spoken count.
        tts.seek(toCharacter: 10)
        #expect(tts.currentCharacterIndex == 10)

        tts.stop()
    }
}
