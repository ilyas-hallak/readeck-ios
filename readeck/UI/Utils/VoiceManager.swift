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
    
    func getVoice(for language: String) -> AVSpeechSynthesisVoice {
        // Check cache first
        if let cachedVoice = cachedVoices[language] {
            return cachedVoice
        }

        // Only use selectedVoice if its language matches
        let langPrefix = String(language.prefix(2))
        if let selected = selectedVoice, selected.language.hasPrefix(langPrefix) {
            cachedVoices[language] = selected
            return selected
        }

        // Find best voice for this language
        let voice = findEnhancedVoice(for: language)
        cachedVoices[language] = voice
        return voice
    }
    
    func setSelectedVoice(_ voice: AVSpeechSynthesisVoice) {
        selectedVoice = voice
        cachedVoices.removeValue(forKey: voice.language)
        saveSelectedVoice(voice)
    }
    
    func getAvailableVoices(for language: String) -> [AVSpeechSynthesisVoice] {
        return availableVoices.filter { $0.language == language }
    }
    
    func refreshVoices() {
        cachedVoices.removeAll()
        loadAvailableVoices()
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
        let voicesForLanguage = availableVoices.filter { $0.language == language }

        // Prefer highest quality available: premium > enhanced > default
        if let premium = voicesForLanguage.first(where: { $0.quality == .premium }) {
            return premium
        }
        if let enhanced = voicesForLanguage.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        if let defaultVoice = voicesForLanguage.first {
            return defaultVoice
        }

        // Ultimate fallback
        return AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice()
    }
    
    // MARK: - Debug Methods
    
    func printAvailableVoices(for language: String) {
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