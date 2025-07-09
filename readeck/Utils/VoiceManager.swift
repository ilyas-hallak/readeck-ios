import Foundation
import AVFoundation

class VoiceManager: ObservableObject {
    static let shared = VoiceManager()
    
    private let userDefaults = UserDefaults.standard
    private let selectedVoiceKey = "selectedVoice"
    private var cachedVoices: [String: AVSpeechSynthesisVoice] = [:]
    
    @Published var selectedVoice: AVSpeechSynthesisVoice?
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    
    private init() {
        loadAvailableVoices()
        loadSelectedVoice()
    }
    
    // MARK: - Public Methods
    
    func getVoice(for language: String = "de-DE") -> AVSpeechSynthesisVoice {
        // Verwende ausgewählte Stimme falls verfügbar
        if let selected = selectedVoice, selected.language == language {
            return selected
        }
        
        // Verwende gecachte Stimme
        if let cachedVoice = cachedVoices[language] {
            return cachedVoice
        }
        
        // Finde und cache eine neue Stimme
        let voice = findEnhancedVoice(for: language)
        cachedVoices[language] = voice
        return voice
    }
    
    func setSelectedVoice(_ voice: AVSpeechSynthesisVoice) {
        selectedVoice = voice
        saveSelectedVoice(voice)
    }
    
    func getAvailableVoices(for language: String = "de-DE") -> [AVSpeechSynthesisVoice] {
        return availableVoices.filter { $0.language == language }
    }
    
    func getPreferredVoices(for language: String = "de-DE") -> [AVSpeechSynthesisVoice] {
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
        
        var preferredVoices: [AVSpeechSynthesisVoice] = []
        
        for voiceName in preferredVoiceNames {
            if let voice = availableVoices.first(where: { 
                $0.language == language && 
                $0.name.contains(voiceName) 
            }) {
                preferredVoices.append(voice)
            }
        }
        
        return preferredVoices
    }
    
    // MARK: - Private Methods
    
    private func loadAvailableVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
    }
    
    private func loadSelectedVoice() {
        if let voiceIdentifier = userDefaults.string(forKey: selectedVoiceKey),
           let voice = availableVoices.first(where: { $0.identifier == voiceIdentifier }) {
            selectedVoice = voice
        }
    }
    
    private func saveSelectedVoice(_ voice: AVSpeechSynthesisVoice) {
        userDefaults.set(voice.identifier, forKey: selectedVoiceKey)
    }
    
    private func findEnhancedVoice(for language: String) -> AVSpeechSynthesisVoice {
        // Zuerst nach bevorzugten Stimmen für die spezifische Sprache suchen
        let preferredVoices = getPreferredVoices(for: language)
        if let preferredVoice = preferredVoices.first {
            return preferredVoice
        }
        
        // Fallback: Erste verfügbare Stimme für die Sprache
        return availableVoices.first(where: { $0.language == language }) ?? 
               AVSpeechSynthesisVoice(language: language) ??
               AVSpeechSynthesisVoice()
    }
    
    // MARK: - Debug Methods
    
    func printAvailableVoices(for language: String = "de-DE") {
        let filteredVoices = availableVoices.filter { $0.language.starts(with: language.prefix(2)) }
        
        print("Verfügbare Stimmen für \(language):")
        for voice in filteredVoices {
            print("- \(voice.name) (\(voice.language)) - Qualität: \(voice.quality.rawValue)")
        }
    }
    
    func printAllAvailableLanguages() {
        let languages = Set(availableVoices.map { $0.language })
        
        print("Verfügbare Sprachen:")
        for language in languages.sorted() {
            print("- \(language)")
        }
    }
} 