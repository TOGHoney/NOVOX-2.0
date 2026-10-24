import Foundation
import AVFoundation

/// Text-to-Speech audio service using native iOS AVSpeechSynthesizer.
/// Replaces the browser's `window.speechSynthesis` from `StudyTools.jsx`.
@MainActor
public final class SpeechSynthesisService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    public static let shared = SpeechSynthesisService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published public var isSpeaking: Bool = false
    @Published public var lastError: String?
    @Published public var lastWarning: String?
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        // By setting usesApplicationAudioSession = false, AVSpeechSynthesizer manages its
        // own dedicated system audio pipeline without contending for the app's shared AVAudioSession.
        // This completely eliminates AudioQueue buffer starvation, underflow #8/#9, and race conditions.
        synthesizer.usesApplicationAudioSession = false
    }
    
    /// Cleans text for speech synthesis by removing explanatory parentheticals (e.g., "(neko)" or "[noun]")
    public static func cleanTextForSpeech(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "\\s*\\([^)]*\\)", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\s*\\[[^]]*\\]", with: "", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? text : cleaned
    }
    
    /// Finds the best available AVSpeechSynthesisVoice for a given language code (supports "ja-JP", "ja", "Japanese", etc.)
    private func resolveVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let code = languageCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Direct match with provided code (e.g. "ja-JP")
        if let voice = AVSpeechSynthesisVoice(language: code) {
            return voice
        }
        
        // 2. Try short prefix (e.g. "ja" if "ja-JP" had no exact regional match)
        if let prefix = code.components(separatedBy: "-").first, !prefix.isEmpty {
            if let voice = AVSpeechSynthesisVoice(language: prefix) {
                return voice
            }
        }
        
        // 3. Match from Constants lookup table
        let bcp47 = Constants.bcp47(for: code)
        if let voice = AVSpeechSynthesisVoice(language: bcp47) {
            return voice
        }
        
        // 4. Match any installed voice whose language starts with the prefix
        let prefix = code.components(separatedBy: "-").first?.lowercased() ?? ""
        if !prefix.isEmpty {
            let available = AVSpeechSynthesisVoice.speechVoices()
            if let voice = available.first(where: { $0.language.lowercased().starts(with: prefix) }) {
                return voice
            }
        }
        
        // 5. Default fallback to English voice
        return AVSpeechSynthesisVoice(language: "en-US")
    }
    
    /// Speaks the given text using the specified BCP-47 language code (e.g., "en-US", "es-ES", "ja-JP")
    public func speak(_ text: String, languageCode: String = "en-US") {
        lastError = nil
        lastWarning = nil
        
        let cleaned = Self.cleanTextForSpeech(text)
        guard !cleaned.isEmpty else {
            lastError = "No text to speak"
            print("[SpeechSynthesis] \(lastError!)")
            return
        }
        
        print("[SpeechSynthesis] Speaking text: '\(cleaned.prefix(50))' [lang: \(languageCode)]")
        
        // Halt any active speech cleanly before enqueuing next utterance
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        guard let voice = resolveVoice(for: languageCode) else {
            lastError = "No speech voice available for language: \(languageCode)"
            print("[SpeechSynthesis] \(lastError!)")
            return
        }
        
        print("[SpeechSynthesis] Using voice: \(voice.name) for language: \(voice.language)")
        
        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        self.isSpeaking = true
        self.synthesizer.speak(utterance)
    }
    
    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        lastError = nil
        lastWarning = nil
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.lastError = nil
            self.lastWarning = nil
        }
    }
    
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.lastError = nil
            self.lastWarning = nil
        }
    }
}
