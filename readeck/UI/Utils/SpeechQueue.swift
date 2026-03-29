import Foundation
import Combine

struct SpeechQueueItem: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let content: String?
    let url: String
    let labels: [String]?
    let imageUrl: String?
    let language: String
}

extension BookmarkDetail {
    func toSpeechQueueItem(_ content: String? = nil) -> SpeechQueueItem {
        return SpeechQueueItem(
            id: self.id,
            title: title,
            content: content ?? self.content,
            url: url,
            labels: labels,
            imageUrl: imageUrl,
            language: lang.isEmpty ? "en" : lang
        )
    }
}

class SpeechQueue: ObservableObject {
    private var queue: [SpeechQueueItem] = []
    private var isProcessing = false
    private let ttsManager: TTSManager
    private let queueKey = "tts_queue"

    static let shared = SpeechQueue()

    // Convert ISO 639-1 language codes (e.g., "de", "en") to BCP 47 (e.g., "de-DE", "en-US")
    private func convertToBCP47(_ isoCode: String) -> String {
        let mapping: [String: String] = [
            "de": "de-DE",
            "en": "en-US",
            "es": "es-ES",
            "fr": "fr-FR",
            "it": "it-IT",
            "pt": "pt-PT",
            "nl": "nl-NL",
            "pl": "pl-PL",
            "ru": "ru-RU",
            "ja": "ja-JP",
            "zh": "zh-CN",
            "ko": "ko-KR",
            "ar": "ar-SA",
            "tr": "tr-TR",
            "sv": "sv-SE",
            "da": "da-DK",
            "no": "nb-NO",
            "fi": "fi-FI",
            "cs": "cs-CZ",
            "hu": "hu-HU",
            "ro": "ro-RO",
            "sk": "sk-SK",
            "uk": "uk-UA",
            "el": "el-GR",
            "he": "he-IL",
            "hi": "hi-IN",
            "th": "th-TH",
            "id": "id-ID",
            "vi": "vi-VN"
        ]
        return mapping[isoCode.lowercased()] ?? "en-US"
    }

    @Published var queueItems: [SpeechQueueItem] = []
    @Published var currentText: String = ""
    @Published var hasItems: Bool = false

    var queueCount: Int {
        return queueItems.count
    }

    var currentItem: SpeechQueueItem? {
        return queueItems.first
    }

    private init(ttsManager: TTSManager = .shared) {
        self.ttsManager = ttsManager
        loadQueue()
        updatePublishedProperties()

        ttsManager.onUtteranceFinished = { [weak self] in
            self?.onCurrentItemFinished()
        }
        ttsManager.onUtteranceCancelled = { [weak self] in
            self?.onCurrentItemCancelled()
        }
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
        let languageCode = convertToBCP47(next.language)
        ttsManager.speak(text: textToSpeak, language: languageCode, utteranceIndex: currentIndex, totalUtterances: queueItems.count)
    }

    private func onCurrentItemCancelled() {
        isProcessing = false
        updatePublishedProperties()
    }

    private func onCurrentItemFinished() {
        guard isProcessing else { return }
        if !queue.isEmpty {
            queue.removeFirst()
        }
        isProcessing = false
        updatePublishedProperties()
        saveQueue()
        processQueue()
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
