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
    
    func speak(text: String, language: String = "de-DE") {
        guard !text.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.currentUtterance = text
        }
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        utterance.voice = voiceManager.getVoice(for: language)
                
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
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
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        currentUtterance = ""
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        currentUtterance = ""
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isSpeaking = true
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
