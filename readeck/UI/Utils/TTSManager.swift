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
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers, .allowBluetooth, .allowBluetoothA2DP])
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
    
    func speak(text: String, language: String = "de-DE", utteranceIndex: Int = 0, totalUtterances: Int = 1) {
        guard !text.isEmpty else { return }
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.currentUtterance = text
            self.currentUtteranceIndex = utteranceIndex
            self.totalUtterances = totalUtterances
            self.updateProgress()
            self.articleProgress = 0.0
        }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
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
    
    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
        isSpeaking = false
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
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        currentUtterance = ""
        currentUtteranceIndex += 1
        updateProgress()
        articleProgress = 1.0
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        currentUtterance = ""
        articleProgress = 0.0
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let total = utterance.speechString.count
        if total > 0 {
            let spoken = characterRange.location + characterRange.length
            let progress = min(Double(spoken) / Double(total), 1.0)
            DispatchQueue.main.async {
                self.articleProgress = progress
            }
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
