import Foundation
import Combine

struct SpeechQueueItem: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let content: String?
    let url: String
    let labels: [String]?
    let imageUrl: String?
}

extension BookmarkDetail {
    func toSpeechQueueItem(_ content: String? = nil) -> SpeechQueueItem {
        return SpeechQueueItem(
            id: self.id,
            title: title,
            content: content ?? self.content,
            url: url,
            labels: labels,
            imageUrl: imageUrl
        )
    }
}

class SpeechQueue: ObservableObject {
    private var queue: [SpeechQueueItem] = []
    private var isProcessing = false
    private let ttsManager: TTSManager
    private let language: String
    private let queueKey = "tts_queue"
    
    static let shared = SpeechQueue()
    
    @Published var queueItems: [SpeechQueueItem] = []
    @Published var currentText: String = ""
    @Published var hasItems: Bool = false
    
    var queueCount: Int {
        return queueItems.count
    }
    
    var currentItem: SpeechQueueItem? {
        return queueItems.first
    }
    
    private init(ttsManager: TTSManager = .shared, language: String = "de-DE") {
        self.ttsManager = ttsManager
        self.language = language
        loadQueue()
        updatePublishedProperties()
    }
    
    func enqueue(_ item: SpeechQueueItem) {
        queue.append(item)
        updatePublishedProperties()
        saveQueue()
        processQueue()
    }
    
    func enqueue(contentsOf items: [SpeechQueueItem]) {
        queue.append(contentsOf: items)
        updatePublishedProperties()
        saveQueue()
        processQueue()
    }
    
    func stop() {
        print("[SpeechQueue] stop() aufgerufen")
        updatePublishedProperties()
        saveQueue()
        ttsManager.stop()
        isProcessing = false
    }
    
    func clear() {
        print("[SpeechQueue] clear() aufgerufen")
        queue.removeAll()
        updatePublishedProperties()
        saveQueue()
        ttsManager.stop()
        isProcessing = false
    }
    
    private func updatePublishedProperties() {
        queueItems = queue
        currentText = queue.first?.content ?? ""
        hasItems = !queue.isEmpty || ttsManager.isCurrentlySpeaking()
    }
    
    private func processQueue() {
        guard !isProcessing, !queue.isEmpty else { return }
        isProcessing = true
        let next = queue[0]
        updatePublishedProperties()
        saveQueue()
        let currentIndex = queueItems.count - queue.count
        let textToSpeak = (next.title + "\n" + (next.content ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
        ttsManager.speak(text: textToSpeak, language: language, utteranceIndex: currentIndex, totalUtterances: queueItems.count)
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
            if !queue.isEmpty {
                queue.removeFirst()
                print("[SpeechQueue] Artikel fertig abgespielt und aus Queue entfernt")
            }
            self.isProcessing = false
            self.updatePublishedProperties()
            self.saveQueue()
            self.processQueue()
        }
    }
    
    // MARK: - Persistenz
    private func saveQueue() {
        let defaults = UserDefaults.standard
        do {
            let data = try JSONEncoder().encode(queue)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[SpeechQueue] Speichere Queue (\(queue.count)) als JSON: \n\(jsonString)")
            }
            defaults.set(data, forKey: queueKey)
        } catch {
            print("[SpeechQueue] Fehler beim Speichern der Queue:", error)
        }
    }
    
    private func loadQueue() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: queueKey) {
            do {
                let savedQueue = try JSONDecoder().decode([SpeechQueueItem].self, from: data)
                queue = savedQueue
                print("[SpeechQueue] Queue geladen (", queue.count, ")")
            } catch {
                print("[SpeechQueue] Fehler beim Laden der Queue:", error)
                defaults.removeObject(forKey: queueKey)
                queue = []
            }
        }
        if queue.isEmpty {
            print("[SpeechQueue] Queue ist nach dem Laden leer!")
        }
    }
}
