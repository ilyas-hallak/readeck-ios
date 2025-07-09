import Foundation
import Combine

class SpeechPlayerViewModel: ObservableObject {
    private let ttsManager: TTSManager
    private let speechQueue: SpeechQueue
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isSpeaking: Bool = false
    @Published var currentText: String = ""
    @Published var queueCount: Int = 0
    @Published var queueItems: [String] = []
    @Published var hasItems: Bool = false
    
    init(ttsManager: TTSManager = .shared, speechQueue: SpeechQueue = .shared) {
        self.ttsManager = ttsManager
        self.speechQueue = speechQueue
        setupBindings()
    }
    
    private func setupBindings() {
        // TTSManager bindings
        ttsManager.$isSpeaking
            .assign(to: \.isSpeaking, on: self)
            .store(in: &cancellables)
        
        ttsManager.$currentUtterance
            .assign(to: \.currentText, on: self)
            .store(in: &cancellables)
        
        // SpeechQueue bindings
        speechQueue.$queueItems
            .assign(to: \.queueItems, on: self)
            .store(in: &cancellables)
        
        speechQueue.$queueItems
            .map { $0.count }
            .assign(to: \.queueCount, on: self)
            .store(in: &cancellables)
        
        speechQueue.$hasItems
            .assign(to: \.hasItems, on: self)
            .store(in: &cancellables)
    }
    
    func pause() {
        ttsManager.pause()
    }
    
    func resume() {
        ttsManager.resume()
    }
    
    func stop() {
        speechQueue.clear()
    }
} 
