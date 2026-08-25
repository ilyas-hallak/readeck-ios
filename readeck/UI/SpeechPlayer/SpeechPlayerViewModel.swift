import Foundation

@MainActor
@Observable
final class SpeechPlayerViewModel {
    private var ttsManager: TTSManager?
    private var speechQueue: SpeechQueue?

    // Read straight from the two sources instead of mirroring 13 properties
    // through Combine — observation tracks the reads through these accessors.
    var isSpeaking: Bool { ttsManager?.isSpeaking ?? false }
    var currentText: String { ttsManager?.currentUtterance ?? "" }
    var progress: Double { ttsManager?.progress ?? 0 }
    var currentUtteranceIndex: Int { ttsManager?.currentUtteranceIndex ?? 0 }
    var totalUtterances: Int { ttsManager?.totalUtterances ?? 0 }
    var articleProgress: Double { ttsManager?.articleProgress ?? 0 }
    var volume: Float { ttsManager?.volume ?? 1.0 }
    var rate: Float { ttsManager?.rate ?? 0.5 }
    var currentCharacterIndex: Int { ttsManager?.currentCharacterIndex ?? 0 }
    var totalCharacterCount: Int { ttsManager?.totalCharacterCount ?? 0 }

    var queueItems: [SpeechQueueItem] { speechQueue?.queueItems ?? [] }
    var queueCount: Int { queueItems.count }
    var hasItems: Bool { speechQueue?.hasItems ?? false }

    var currentItem: SpeechQueueItem? { queueItems.first }

    func setup() async {
        self.ttsManager = .shared
        self.speechQueue = .shared
    }

    func setVolume(_ newVolume: Float) {
        ttsManager?.setVolume(newVolume)
    }

    func setRate(_ newRate: Float) {
        ttsManager?.setRate(newRate)
    }

    func pause() {
        ttsManager?.pause()
    }

    func resume() {
        speechQueue?.resumeOrReplay()
    }

    func stop() {
        speechQueue?.clear()
    }

    var estimatedDuration: TimeInterval {
        ttsManager?.estimatedDuration(for: totalCharacterCount) ?? 0
    }

    var estimatedCurrentTime: TimeInterval {
        ttsManager?.estimatedCurrentTime() ?? 0
    }

    func seekBack() {
        speechQueue?.seekBack(seconds: 30)
    }

    func seekForward() {
        speechQueue?.seekForward(seconds: 30)
    }

    func seekToPosition(_ percentage: Double) {
        speechQueue?.seekToPosition(percentage)
    }

    func skipToNext() {
        speechQueue?.skipToNext()
    }

    func insertAfterCurrent(_ item: SpeechQueueItem) {
        speechQueue?.insertAfterCurrent(item)
    }

    func skipTo(index: Int) {
        speechQueue?.skipTo(index: index)
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        speechQueue?.move(from: source, to: destination)
    }

    func removeItems(at offsets: IndexSet) {
        speechQueue?.remove(at: offsets)
    }

    func clearQueue() {
        speechQueue?.clear()
    }
}
