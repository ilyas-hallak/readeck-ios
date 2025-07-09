import Foundation
import UIKit
import AVFoundation

class TTSManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSManager()
    private let synthesizer = AVSpeechSynthesizer()
    private var isSpeaking = false
    
    override private init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            
            // Background-Audio aktivieren
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers, .allowBluetooth, .allowBluetoothA2DP])
            
            // Notification für App-Lifecycle
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
    
    func speak(text: String, language: String = "de-DE") {
        guard !text.isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        
        // Versuche eine hochwertige Stimme zu finden
        if let enhancedVoice = findEnhancedVoice(for: language) {
            utterance.voice = enhancedVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }
                
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    private func findEnhancedVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Bevorzugte Stimmen für alle Sprachen
        let preferredVoiceNames = [
            "Anna",      // Deutsche Premium-Stimme
            "Helena",    // Deutsche Premium-Stimme
            "Siri",      // Siri-Stimme (falls verfügbar)
            "Enhanced",  // Enhanced-Stimmen
            "Karen",     // Englische Premium-Stimme
            "Daniel",    // Englische Premium-Stimme
            "Marie",     // Französische Premium-Stimme
            "Paolo",     // Italienische Premium-Stimme
            "Carmen",    // Spanische Premium-Stimme
            "Yuki"       // Japanische Premium-Stimme
        ]
        
        // Zuerst nach bevorzugten Stimmen für die spezifische Sprache suchen
        for voiceName in preferredVoiceNames {
            if let voice = availableVoices.first(where: { 
                $0.language == language && 
                $0.name.contains(voiceName) 
            }) {
                return voice
            }
        }
        
        // Fallback: Erste verfügbare Stimme für die Sprache
        return availableVoices.first(where: { $0.language == language })
    }
    
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }
    
    func resume() {
        synthesizer.continueSpeaking()
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func isCurrentlySpeaking() -> Bool {
        return synthesizer.isSpeaking
    }
    
    @objc private func handleAppDidEnterBackground() {
        // App geht in Hintergrund - Audio-Session beibehalten
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Fehler beim Aktivieren der Audio-Session im Hintergrund: \(error)")
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        // App kommt in Vordergrund - Audio-Session erneuern
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Fehler beim Aktivieren der Audio-Session im Vordergrund: \(error)")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Debug-Methode: Zeigt alle verfügbaren Stimmen für eine Sprache
    func printAvailableVoices(for language: String = "de-DE") {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let filteredVoices = voices.filter { $0.language.starts(with: language.prefix(2)) }
        
        print("Verfügbare Stimmen für \(language):")
        for voice in filteredVoices {
            print("- \(voice.name) (\(voice.language)) - Qualität: \(voice.quality.rawValue)")
        }
    }
    
    // Debug-Methode: Zeigt alle verfügbaren Sprachen
    func printAllAvailableLanguages() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let languages = Set(voices.map { $0.language })
        
        print("Verfügbare Sprachen:")
        for language in languages.sorted() {
            print("- \(language)")
        }
    }
} 
