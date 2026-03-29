import Foundation
import UIKit
import AVFoundation
import Combine

class TTSManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSManager()
    private let synthesizer = AVSpeechSynthesizer()
    private let voiceManager = VoiceManager.shared
    
    @Published var isSpeaking = false
    @Published var currentUtterance = ""
    @Published var progress: Double = 0.0
    @Published var totalUtterances: Int = 0
    @Published var currentUtteranceIndex: Int = 0
    @Published var articleProgress: Double = 0.0
    @Published var volume: Float = 1.0
    @Published var rate: Float = 0.5

    @Published var currentCharacterIndex: Int = 0
    @Published var totalCharacterCount: Int = 0
    var onPositionUpdate: ((Int) -> Void)?

    private var currentFullText: String = ""
    private var currentLanguage: String = "en-US"
    private var currentStartOffset: Int = 0

    var onUtteranceFinished: (() -> Void)?
    var onUtteranceCancelled: (() -> Void)?
    
    override private init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        loadSettings()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        } catch {
            print("Fehler beim Konfigurieren der Audio-Session: \(error)")
        }
    }
    
    func speak(text: String, language: String, utteranceIndex: Int = 0, totalUtterances: Int = 1, startFromCharacter: Int = 0) {
        guard !text.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        self.currentFullText = text
        self.currentLanguage = language
        self.currentStartOffset = startFromCharacter
        self.totalCharacterCount = text.count
        self.currentCharacterIndex = startFromCharacter
        self.isSpeaking = true
        self.currentUtterance = text
        self.currentUtteranceIndex = utteranceIndex
        self.totalUtterances = totalUtterances
        self.updateProgress()
        self.articleProgress = text.isEmpty ? 0 : Double(startFromCharacter) / Double(text.count)

        let textToSpeak: String
        if startFromCharacter > 0 && startFromCharacter < text.count {
            let startIndex = text.index(text.startIndex, offsetBy: startFromCharacter)
            textToSpeak = String(text[startIndex...])
        } else {
            textToSpeak = text
        }

        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.voice = voiceManager.getVoice(for: language)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = volume
        synthesizer.speak(utterance)
    }
    
    private func updateProgress() {
        if totalUtterances > 0 {
            progress = Double(currentUtteranceIndex) / Double(totalUtterances)
        } else {
            progress = 0.0
        }
    }
    
    func setVolume(_ newVolume: Float) {
        volume = newVolume
        saveSettings()
    }
    
    func setRate(_ newRate: Float) {
        rate = newRate
        saveSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        if let savedVolume = defaults.value(forKey: "tts_volume") as? Float {
            volume = savedVolume
        }
        if let savedRate = defaults.value(forKey: "tts_rate") as? Float {
            rate = savedRate
        }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(volume, forKey: "tts_volume")
        defaults.set(rate, forKey: "tts_rate")
    }
    
    // MARK: - Seek

    func seek(toCharacter index: Int) {
        guard !currentFullText.isEmpty else { return }
        let clampedIndex = max(0, min(index, currentFullText.count))
        speak(
            text: currentFullText,
            language: currentLanguage,
            utteranceIndex: currentUtteranceIndex,
            totalUtterances: totalUtterances,
            startFromCharacter: clampedIndex
        )
    }

    func seekBack(seconds: Double = 30) {
        let charsPerSecond = estimatedCharactersPerSecond()
        let charsToSkip = Int(seconds * charsPerSecond)
        let targetIndex = max(0, currentCharacterIndex - charsToSkip)
        seek(toCharacter: targetIndex)
    }

    func seekForward(seconds: Double = 30) {
        let charsPerSecond = estimatedCharactersPerSecond()
        let charsToSkip = Int(seconds * charsPerSecond)
        let targetIndex = min(currentFullText.count, currentCharacterIndex + charsToSkip)
        seek(toCharacter: targetIndex)
    }

    func estimatedCharactersPerSecond() -> Double {
        // AVSpeechUtterance rate 0.5 ≈ natural speaking ≈ 15 chars/sec
        // Scale linearly: rate 0.25 ≈ 7.5, rate 1.0 ≈ 30
        return Double(rate) * 30.0
    }

    func estimatedDuration(for totalChars: Int) -> TimeInterval {
        let cps = estimatedCharactersPerSecond()
        return cps > 0 ? Double(totalChars) / cps : 0
    }

    func estimatedCurrentTime() -> TimeInterval {
        let cps = estimatedCharactersPerSecond()
        return cps > 0 ? Double(currentCharacterIndex) / cps : 0
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
        isSpeaking = false
        onPositionUpdate?(currentCharacterIndex)
    }
    
    func resume() {
        synthesizer.continueSpeaking()
        isSpeaking = true
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentUtterance = ""
        articleProgress = 0.0
        updateProgress()
        onPositionUpdate?(currentCharacterIndex)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentUtterance = ""
            self.currentUtteranceIndex += 1
            self.updateProgress()
            self.articleProgress = 1.0
            self.onUtteranceFinished?()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentUtterance = ""
            self.articleProgress = 0.0
            self.onUtteranceCancelled?()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let spoken = characterRange.location + characterRange.length
        let absolutePosition = currentStartOffset + spoken
        let total = currentFullText.count

        DispatchQueue.main.async {
            self.currentCharacterIndex = absolutePosition
            if total > 0 {
                self.articleProgress = min(Double(absolutePosition) / Double(total), 1.0)
            }
            self.onPositionUpdate?(absolutePosition)
        }
    }
    
    func isCurrentlySpeaking() -> Bool {
        return synthesizer.isSpeaking
    }
    
    @objc private func handleAppDidEnterBackground() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Fehler beim Aktivieren der Audio-Session im Hintergrund: \(error)")
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Fehler beim Aktivieren der Audio-Session im Vordergrund: \(error)")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
