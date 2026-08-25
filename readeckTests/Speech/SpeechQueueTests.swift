import Testing
import Foundation
@testable import readeck

/// Exercises the queue transitions through the shared TTSManager callbacks,
/// which is how the real player drives them.
@Suite("SpeechQueue Tests", .serialized)
@MainActor
struct SpeechQueueTests {

    private func makeItem(id: String) -> SpeechQueueItem {
        SpeechQueueItem(
            id: id,
            title: "Article \(id)",
            content: "Content of article \(id)",
            url: "https://example.com/\(id)",
            labels: nil,
            imageUrl: nil,
            language: "en",
            lastCharacterIndex: 0,
            totalCharacters: 20
        )
    }

    /// Stands in for the synthesizer reporting the current utterance as done.
    private func finishCurrentUtterance() {
        TTSManager.shared.onUtteranceFinished?()
    }

    /// Stands in for a cancel, which the synthesizer also emits when `speak`
    /// interrupts itself for a seek or a rate change.
    private func cancelCurrentUtterance() {
        TTSManager.shared.onUtteranceCancelled?()
    }

    @Test("A second article is appended while the first one plays")
    func secondArticleIsQueued() {
        let queue = SpeechQueue.shared
        queue.clear()

        queue.enqueue(makeItem(id: "A"))
        queue.enqueue(makeItem(id: "B"))

        #expect(queue.queueItems.map(\.id) == ["A", "B"])
        #expect(queue.currentItem?.id == "A")

        queue.clear()
    }

    @Test("A finished article is dropped so the next one can play")
    func finishedArticleDoesNotBlockTheQueue() {
        let queue = SpeechQueue.shared
        queue.clear()
        queue.enqueue(makeItem(id: "A"))

        finishCurrentUtterance()
        queue.enqueue(makeItem(id: "B"))

        // A already played to the end. Adding B must not put it behind a
        // finished item that gets replayed instead.
        #expect(queue.currentItem?.id == "B")

        queue.clear()
    }

    @Test("A finished article gives way to one queued as next")
    func finishedArticleGivesWayToListenNext() {
        let queue = SpeechQueue.shared
        queue.clear()
        queue.enqueue(makeItem(id: "A"))

        finishCurrentUtterance()
        queue.insertAfterCurrent(makeItem(id: "B"))

        #expect(queue.currentItem?.id == "B")

        queue.clear()
    }

    @Test("A still-playing article keeps its place when another is queued next")
    func playingArticleKeepsItsPlace() {
        let queue = SpeechQueue.shared
        queue.clear()
        queue.enqueue(makeItem(id: "A"))

        queue.insertAfterCurrent(makeItem(id: "B"))

        #expect(queue.queueItems.map(\.id) == ["A", "B"])
        #expect(queue.currentItem?.id == "A")

        queue.clear()
    }

    @Test("A seek does not make the queue restart the article")
    func cancelFromSeekKeepsTheItemPlaying() {
        let queue = SpeechQueue.shared
        queue.clear()
        queue.enqueue(makeItem(id: "A"))

        // A seek or rate change stops the current utterance and starts a new
        // one; the cancel callback must not mark the queue as idle.
        cancelCurrentUtterance()
        queue.enqueue(makeItem(id: "B"))

        #expect(queue.queueItems.map(\.id) == ["A", "B"])
        #expect(queue.currentItem?.id == "A")

        queue.clear()
    }
}
