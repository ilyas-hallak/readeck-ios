import Foundation
import UIKit
import AVFoundation
import Combine

final class TTSManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let logger = Logger.general
    static let shared = TTSManager()
    private var synthesizer = AVSpeechSynthesizer()
    private let voiceManager = VoiceManager.shared

    @Published var isSpeaking = false
    @Published var currentUtterance = ""
    @Published var progress = 0.0
    @Published var totalUtterances = 0
    @Published var currentUtteranceIndex = 0
    @Published var articleProgress = 0.0
    @Published var volume: Float = 1.0
    @Published var rate: Float = 0.5

    @Published var currentCharacterIndex: Int = 0
    @Published var totalCharacterCount: Int = 0
    var onPositionUpdate: ((Int) -> Void)?

    private var currentFullText: String = ""
    private var currentLanguage: String = "en-US"
    private var currentStartOffset: Int = 0

    private lazy var nowPlayingManager = NowPlayingManager.shared

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
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    private func ensureSynthesizerReady() {
        // Re-activate audio session (may have been interrupted by iOS Settings)
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Audio session reactivation failed: \(error.localizedDescription)")
        }
    }

    private func resetSynthesizer() {
        let old = synthesizer
        old.delegate = nil
        old.stopSpeaking(at: .immediate)
        synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
    }

    func speak(text: String, language: String, utteranceIndex: Int = 0, totalUtterances: Int = 1, startFromCharacter: Int = 0) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !text.isEmpty else { return }

        ensureSynthesizerReady()

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

    func updateNowPlaying(title: String, source: String?, imageUrl: String?) {
        nowPlayingManager.updateNowPlayingInfo(
            title: title,
            source: source,
            imageUrl: imageUrl,
            duration: estimatedDuration(for: currentFullText.count),
            currentTime: estimatedCurrentTime()
        )
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
        restartIfSpeaking()
    }

    func setRate(_ newRate: Float) {
        rate = newRate
        saveSettings()
        restartIfSpeaking()
    }

    private func restartIfSpeaking() {
        guard synthesizer.isSpeaking || synthesizer.isPaused else { return }
        speak(
            text: currentFullText,
            language: currentLanguage,
            utteranceIndex: currentUtteranceIndex,
            totalUtterances: totalUtterances,
            startFromCharacter: currentCharacterIndex
        )
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
        dispatchPrecondition(condition: .onQueue(.main))
        synthesizer.pauseSpeaking(at: .immediate)
        isSpeaking = false
        onPositionUpdate?(currentCharacterIndex)
        nowPlayingManager.updateNowPlayingPlaybackState(isPlaying: false)
    }

    func resume() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        isSpeaking = true
        nowPlayingManager.updateNowPlayingPlaybackState(isPlaying: true)
    }

    func stop() {
        dispatchPrecondition(condition: .onQueue(.main))
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentUtterance = ""
        articleProgress = 0.0
        updateProgress()
        onPositionUpdate?(currentCharacterIndex)
        nowPlayingManager.clearNowPlaying()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Only update state if the synthesizer isn't already speaking a new utterance
            if !self.synthesizer.isSpeaking {
                self.isSpeaking = false
                self.currentUtterance = ""
                self.articleProgress = 1.0
            }
            self.currentUtteranceIndex += 1
            self.updateProgress()
            self.onUtteranceFinished?()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Only update state if the synthesizer isn't already speaking a new utterance
            if !self.synthesizer.isSpeaking {
                self.isSpeaking = false
                self.currentUtterance = ""
                self.articleProgress = 0.0
            }
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
            self.nowPlayingManager.updateNowPlayingPosition()
        }
    }

    func isCurrentlySpeaking() -> Bool {
        synthesizer.isSpeaking
    }

    func isCurrentlyPaused() -> Bool {
        synthesizer.isPaused
    }

    @objc private func handleAppDidEnterBackground() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Failed to activate audio session in background: \(error.localizedDescription)")
        }
    }

    @objc private func handleAppWillEnterForeground() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Audio session reactivation on foreground failed: \(error.localizedDescription)")
        }
        // Refresh voices in case user downloaded new ones in iOS Settings
        voiceManager.refreshVoices()
        // Recreate synthesizer to pick up new voices
        resetSynthesizer()
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                logger.error("Audio session reactivation after interruption failed: \(error.localizedDescription)")
            }
            resetSynthesizer()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
