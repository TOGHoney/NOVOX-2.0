import Foundation
import AVFoundation

/// Text-to-Speech audio service using native iOS AVSpeechSynthesizer.
/// Replaces the browser's `window.speechSynthesis` from `StudyTools.jsx`.
@MainActor
public final class SpeechSynthesisService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    public static let shared = SpeechSynthesisService()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published public var isSpeaking: Bool = false
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    /// Speaks the given text using the specified BCP-47 language code (e.g., "en-US", "es-ES", "ja-JP")
    public func speak(_ text: String, languageCode: String = "en-US") {
        stop()
        
        // Configure audio session for playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("[SpeechSynthesis] AudioSession error: \(error.localizedDescription)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode) ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95 // Slightly slower for language learners
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
