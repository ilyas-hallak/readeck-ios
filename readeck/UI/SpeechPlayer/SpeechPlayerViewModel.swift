import Foundation

@Observable
class SpeechPlayerViewModel {
    var isSpeaking: Bool {
        return TTSManager.shared.isCurrentlySpeaking()
    }
    
    var currentText: String {
        return SpeechQueue.shared.currentText
    }
    
    func pause() {
        TTSManager.shared.pause()
    }
    
    func resume() {
        TTSManager.shared.resume()
    }
    
    func stop() {
        SpeechQueue.shared.clear()
    }
} 
