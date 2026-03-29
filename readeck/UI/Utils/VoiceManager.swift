import Foundation
import AVFoundation

class VoiceManager: ObservableObject {
    static let shared = VoiceManager()
    
    private let userDefaults = UserDefaults.standard
    private let selectedVoiceKey = "selectedVoice"
    private let perLanguageVoiceKey = "tts_per_language_voices"
    private var cachedVoices: [String: AVSpeechSynthesisVoice] = [:]
    private(set) var perLanguageVoices: [String: String] = [:] // languageCode -> voiceIdentifier
    private var previewSynthesizer = AVSpeechSynthesizer()
    
    @Published var selectedVoice: AVSpeechSynthesisVoice?
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    
    private init() {
        loadAvailableVoices()
        loadSelectedVoice()
        loadPerLanguageVoices()
    }
    
    // MARK: - Public Methods
    
    func getVoice(for language: String) -> AVSpeechSynthesisVoice {
        // Check cache first
        if let cachedVoice = cachedVoices[language] {
            return cachedVoice
        }

        // Check per-language selection
        if let voiceId = perLanguageVoices[language],
           let voice = availableVoices.first(where: { $0.identifier == voiceId }) {
            cachedVoices[language] = voice
            return voice
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
    
    // MARK: - Per-Language Voice

    private func loadPerLanguageVoices() {
        if let data = userDefaults.data(forKey: perLanguageVoiceKey),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            perLanguageVoices = dict
        }
    }

    func setVoice(_ voice: AVSpeechSynthesisVoice, for language: String) {
        perLanguageVoices[language] = voice.identifier
        cachedVoices.removeValue(forKey: language)
        if let data = try? JSONEncoder().encode(perLanguageVoices) {
            userDefaults.set(data, forKey: perLanguageVoiceKey)
        }
    }

    func getSelectedVoiceIdentifier(for language: String) -> String? {
        return perLanguageVoices[language]
    }

    func clearPerLanguageVoice(for language: String) {
        perLanguageVoices.removeValue(forKey: language)
        cachedVoices.removeValue(forKey: language)
        if let data = try? JSONEncoder().encode(perLanguageVoices) {
            userDefaults.set(data, forKey: perLanguageVoiceKey)
        }
    }

    // MARK: - Preview

    func previewVoice(_ voice: AVSpeechSynthesisVoice, sampleText: String) {
        previewSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: sampleText)
        utterance.voice = voice
        utterance.rate = 0.5
        previewSynthesizer.speak(utterance)
    }

    func stopPreview() {
        previewSynthesizer.stopSpeaking(at: .immediate)
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