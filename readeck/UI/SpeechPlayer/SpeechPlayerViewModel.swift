import Foundation
import Combine

class SpeechPlayerViewModel: ObservableObject {
    private var ttsManager: TTSManager? = nil
    private var speechQueue: SpeechQueue? = nil
    private let loadSettingsUseCase: PLoadSettingsUseCase
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isSpeaking: Bool = false
    @Published var currentText: String = ""
    @Published var queueCount: Int = 0
    @Published var queueItems: [SpeechQueueItem] = []
    @Published var hasItems: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentUtteranceIndex: Int = 0
    @Published var totalUtterances: Int = 0
    @Published var articleProgress: Double = 0.0
    @Published var volume: Float = 1.0
    @Published var rate: Float = 0.5
    
    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {        
        loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }
    
    func setup() async {
        let settings = try? await loadSettingsUseCase.execute()
        if settings?.enableTTS == true {
            self.ttsManager = .shared
            self.speechQueue = .shared
            setupBindings()
        }
    }
    
    private func setupBindings() {
        // TTSManager bindings
        ttsManager?.$isSpeaking
            .assign(to: \.isSpeaking, on: self)
            .store(in: &cancellables)
        
        ttsManager?.$currentUtterance
            .assign(to: \.currentText, on: self)
            .store(in: &cancellables)
        
        // SpeechQueue bindings
        speechQueue?.$queueItems
            .assign(to: \.queueItems, on: self)
            .store(in: &cancellables)
        
        speechQueue?.$queueItems
            .map { $0.count }
            .assign(to: \.queueCount, on: self)
            .store(in: &cancellables)
        
        speechQueue?.$hasItems
            .assign(to: \.hasItems, on: self)
            .store(in: &cancellables)
        
        // TTS Progress bindings
        ttsManager?.$progress
            .assign(to: \.progress, on: self)
            .store(in: &cancellables)
        
        ttsManager?.$currentUtteranceIndex
            .assign(to: \.currentUtteranceIndex, on: self)
            .store(in: &cancellables)
        
        ttsManager?.$totalUtterances
            .assign(to: \.totalUtterances, on: self)
            .store(in: &cancellables)
        
        ttsManager?.$articleProgress
            .assign(to: \.articleProgress, on: self)
            .store(in: &cancellables)
        
        ttsManager?.$volume
            .assign(to: \.volume, on: self)
            .store(in: &cancellables)
        
        ttsManager?.$rate
            .assign(to: \.rate, on: self)
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
        ttsManager?.resume()
    }
    
    func stop() {
        ttsManager?.stop()
    }
} 
