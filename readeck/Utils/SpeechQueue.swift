import Foundation
import Combine

class SpeechQueue: ObservableObject {
    private var queue: [String] = []
    private var isProcessing = false
    private let ttsManager: TTSManager
    private let language: String
    
    static let shared = SpeechQueue()
    
    @Published var queueItems: [String] = []
    @Published var currentText: String = ""
    @Published var hasItems: Bool = false
    
    var queueCount: Int {
        return queueItems.count
    }
    
    var currentItem: String? {
        return queueItems.first
    }
    
    private init(ttsManager: TTSManager = .shared, language: String = "de-DE") {
        self.ttsManager = ttsManager
        self.language = language
    }
    
    func enqueue(_ text: String) {
        queue.append(text)
        updatePublishedProperties()
        processQueue()
    }
    
    func enqueue(contentsOf texts: [String]) {
        queue.append(contentsOf: texts)
        updatePublishedProperties()
        processQueue()
    }
    
    func clear() {
        queue.removeAll()
        ttsManager.stop()
        isProcessing = false
        updatePublishedProperties()
    }
    
    private func updatePublishedProperties() {
        queueItems = queue
        currentText = queue.first ?? ""
        hasItems = !queue.isEmpty || ttsManager.isCurrentlySpeaking()
    }
    
    private func processQueue() {
        guard !isProcessing, !queue.isEmpty else { return }
        isProcessing = true
        let next = queue.removeFirst()
        ttsManager.speak(text: next, language: language)
        // Delegate/Notification für didFinish kann hier angebunden werden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.waitForSpeechToFinish()
        }
    }
    
    private func waitForSpeechToFinish() {
        if ttsManager.isCurrentlySpeaking() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.waitForSpeechToFinish()
            }
        } else {
            self.isProcessing = false
            self.updatePublishedProperties()
            self.processQueue()
        }
    }
} 
