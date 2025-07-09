import Foundation

@Observable
class SpeechQueue {
    private var queue: [String] = []
    private var isProcessing = false
    private let ttsManager: TTSManager
    private let language: String
    
    static let shared = SpeechQueue()
    
    var hasItems: Bool {
        return !queue.isEmpty || ttsManager.isCurrentlySpeaking()
    }
    
    var queueCount: Int {
        return queue.count
    }
    
    var currentItem: String? {
        return queue.first
    }
    
    var queueItems: [String] {
        return queue
    }
    
    var currentText: String {
        return queue.first ?? ""
    }
    
    private init(ttsManager: TTSManager = .shared, language: String = "de-DE") {
        self.ttsManager = ttsManager
        self.language = language
    }
    
    func enqueue(_ text: String) {
        queue.append(text)
        processQueue()
    }
    
    func enqueue(contentsOf texts: [String]) {
        queue.append(contentsOf: texts)
        processQueue()
    }
    
    func clear() {
        queue.removeAll()
        ttsManager.stop()
        isProcessing = false
    }
    
    private func processQueue() {
        guard !isProcessing, !queue.isEmpty else { return }
        isProcessing = true
        let next = queue.removeFirst()
        ttsManager.speak(text: next, language: language)
        // Delegate/Notification für didFinish kann hier angebunden werden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.waitForSpeechToFinish()
        }
    }
    
    private func waitForSpeechToFinish() {
        if ttsManager.isCurrentlySpeaking() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.waitForSpeechToFinish()
            }
        } else {
            self.isProcessing = false
            self.processQueue()
        }
    }
} 
