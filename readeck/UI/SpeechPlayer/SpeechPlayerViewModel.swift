import Foundation
import Combine

@MainActor
final class SpeechPlayerViewModel: ObservableObject {
    private var ttsManager: TTSManager?
    private var speechQueue: SpeechQueue?
    private let loadSettingsUseCase: PLoadSettingsUseCase
    private var cancellables = Set<AnyCancellable>()

    @Published var isSpeaking = false
    @Published var currentText = ""
    @Published var queueCount = 0
    @Published var queueItems: [SpeechQueueItem] = []
    @Published var hasItems = false
    @Published var progress = 0.0
    @Published var currentUtteranceIndex = 0
    @Published var totalUtterances = 0
    @Published var articleProgress = 0.0
    @Published var volume: Float = 1.0
    @Published var rate: Float = 0.5
    @Published var currentCharacterIndex: Int = 0
    @Published var totalCharacterCount: Int = 0

    var currentItem: SpeechQueueItem? { queueItems.first }

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }

    func setup() async {
        self.ttsManager = .shared
        self.speechQueue = .shared
        setupBindings()
    }

    private func setupBindings() {
        // TTSManager bindings
        ttsManager?.$isSpeaking
            .receive(on: RunLoop.main)
            .assign(to: \.isSpeaking, on: self)
            .store(in: &cancellables)

        ttsManager?.$currentUtterance
            .receive(on: RunLoop.main)
            .assign(to: \.currentText, on: self)
            .store(in: &cancellables)

        // SpeechQueue bindings
        speechQueue?.$queueItems
            .receive(on: RunLoop.main)
            .assign(to: \.queueItems, on: self)
            .store(in: &cancellables)

        speechQueue?.$queueItems
            .receive(on: RunLoop.main)
            .map(\.count)
            .assign(to: \.queueCount, on: self)
            .store(in: &cancellables)

        speechQueue?.$hasItems
            .receive(on: RunLoop.main)
            .assign(to: \.hasItems, on: self)
            .store(in: &cancellables)

        // TTS Progress bindings
        ttsManager?.$progress
            .receive(on: RunLoop.main)
            .assign(to: \.progress, on: self)
            .store(in: &cancellables)

        ttsManager?.$currentUtteranceIndex
            .receive(on: RunLoop.main)
            .assign(to: \.currentUtteranceIndex, on: self)
            .store(in: &cancellables)

        ttsManager?.$totalUtterances
            .receive(on: RunLoop.main)
            .assign(to: \.totalUtterances, on: self)
            .store(in: &cancellables)

        ttsManager?.$articleProgress
            .receive(on: RunLoop.main)
            .assign(to: \.articleProgress, on: self)
            .store(in: &cancellables)

        ttsManager?.$volume
            .receive(on: RunLoop.main)
            .assign(to: \.volume, on: self)
            .store(in: &cancellables)

        ttsManager?.$rate
            .receive(on: RunLoop.main)
            .assign(to: \.rate, on: self)
            .store(in: &cancellables)

        ttsManager?.$currentCharacterIndex
            .receive(on: RunLoop.main)
            .assign(to: \.currentCharacterIndex, on: self)
            .store(in: &cancellables)

        ttsManager?.$totalCharacterCount
            .receive(on: RunLoop.main)
            .assign(to: \.totalCharacterCount, on: self)
            .store(in: &cancellables)
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
