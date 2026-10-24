import Foundation
import SwiftUI
import Combine

@MainActor
public final class DebateProctorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var liveTranscript: String = ""
    @Published public var isSpeaking: Bool = false
    @Published public var isOverlayExpanded: Bool = false
    @Published public var audioPower: Float = 0.0 // 0.0 to 1.0 for audio equalizer waveform
    
    @Published public var isEvaluatingTurn: Bool = false
    @Published public var latestTurnFeedback: TurnProctorFeedback? = nil
    @Published public var showTurnFeedbackSheet: Bool = false
    
    @Published public var turnsHistory: [TurnProctorFeedback] = []
    
    @Published public var isGeneratingScorecard: Bool = false
    @Published public var scorecard: DebateScorecard? = nil
    @Published public var showScorecardView: Bool = false
    
    @Published public var errorMessage: String? = nil
    @Published public var lastRecordedAudioURL: URL? = nil
    
    // Dependencies
    public let speechService = SpeechRecognitionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // User profile (set by parent view from AuthViewModel)
    public var targetLanguage: String = "English"
    public var nativeLanguage: String = "English"
    public var cefrLevel: String = "B1"
    
    public init() {
        // Forward live transcript updates
        speechService.$liveTranscript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.liveTranscript = text
            }
            .store(in: &cancellables)
            
        // Forward audio power for waveform visualization
        speechService.$audioPower
            .receive(on: DispatchQueue.main)
            .sink { [weak self] power in
                self?.audioPower = power
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Speaking Turn Lifecycle
    
    /// Called when the user is granted the speaking floor in the debate room.
    public func startSpeakingTurn(language: String = "English") {
        isSpeaking = true
        liveTranscript = ""
        isOverlayExpanded = false
        errorMessage = nil
        
        Task {
            _ = await speechService.requestAuthorization()
            
            do {
                try self.speechService.startRecognition(language: language)
            } catch {
                print("[DebateProctor] Speech recognizer notice: \(error.localizedDescription)")
            }
        }
    }
    
    /// Called when the user yields or runs out of speaking floor time.
    public func endSpeakingTurn(
        roomId: String,
        topic: String,
        prompt: String? = nil,
        fallbackTranscript: String? = nil
    ) {
        guard isSpeaking else { return }
        isSpeaking = false
        
        let result = speechService.stopRecognition()
        var transcript = result.transcript
        var segments = result.segments
        let duration = result.durationSeconds
        self.lastRecordedAudioURL = result.audioURL
        
        // Check if an explicit fallback transcript was provided (e.g. testing)
        if transcript.isEmpty, let fallback = fallbackTranscript, !fallback.isEmpty {
            transcript = fallback
            segments = fallback.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.enumerated().map { (idx, w) in
                TranscriptSegment(word: w, timestamp: Double(idx) * 0.5, duration: 0.4, confidence: 0.85)
            }
        }
        
        // If no transcript is available, show error (backend no longer transcribes audio)
        guard !transcript.isEmpty else {
            self.errorMessage = "No speech was transcribed. Please speak clearly or use the 'Dictate / Edit' button to enter your argument manually."
            return
        }
        
        submitTurnEvaluation(
            roomId: roomId,
            topic: topic,
            prompt: prompt,
            transcript: transcript,
            segments: segments,
            duration: duration
        )
    }
    
    /// Submits the completed speaking turn to the backend proctor API.
    public func submitTurnEvaluation(
        roomId: String,
        topic: String,
        prompt: String? = nil,
        transcript: String,
        segments: [TranscriptSegment],
        duration: Int
    ) {
        isEvaluatingTurn = true
        errorMessage = nil
        
        Task {
            // Use user's profile settings for proctor evaluation (not room language)
            let payload = ProctorTurnRequest(
                roomId: roomId,
                transcript: transcript,
                durationSeconds: duration,
                segments: segments,
                topic: topic,
                prompt: prompt,
                audioBase64: nil,  // Backend no longer transcribes audio; relies on local STT
                audioMime: nil
            )
            
            do {
                let response: ProctorTurnResponse = try await APIClient.shared.request(.proctorTurn(), body: payload)
                self.latestTurnFeedback = response.turn
                self.turnsHistory.append(response.turn)
                self.liveTranscript = response.turn.transcript
                self.showTurnFeedbackSheet = true
                self.isEvaluatingTurn = false
            } catch {
                print("[DebateProctor] Error submitting speaking turn: \(error.localizedDescription)")
                self.errorMessage = "Evaluation failed: \(error.localizedDescription)"
                self.isEvaluatingTurn = false
            }
        }
    }
    
    /// Allows immediate submission of spoken or typed text for proctor evaluation.
    public func submitManualSpeech(
        text: String,
        roomId: String,
        topic: String,
        prompt: String? = nil
    ) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        let segments = clean.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.enumerated().map { (idx, w) in
            TranscriptSegment(word: w, timestamp: Double(idx) * 0.4, duration: 0.35, confidence: 0.85)
        }
        
        submitTurnEvaluation(
            roomId: roomId,
            topic: topic,
            prompt: prompt,
            transcript: clean,
            segments: segments,
            duration: max(5, clean.split(separator: " ").count / 2)
        )
    }
    
    // MARK: - End-of-Debate Scorecard
    
    /// Requests the comprehensive end-of-debate scorecard from the proctor.
    public func finishDebateSession(roomId: String) async {
        isGeneratingScorecard = true
        errorMessage = nil
        
        do {
            let response: ProctorFinishResponse = try await APIClient.shared.request(.proctorFinish(roomId: roomId))
            self.scorecard = response.scorecard
            self.showScorecardView = true
            self.isGeneratingScorecard = false
        } catch {
            print("[DebateProctor] Error finishing debate session: \(error.localizedDescription)")
            self.errorMessage = "Failed to generate scorecard: \(error.localizedDescription)"
            self.isGeneratingScorecard = false
        }
    }
    
    // MARK: - Pronunciation Audio Playback
    
    /// Plays standard native target-language pronunciation for a given word using SpeechSynthesisService.
    public func playPronunciation(word: String, targetLanguage: String = "English") {
        let localeId = SpeechRecognitionService.localeIdentifier(for: targetLanguage)
        SpeechSynthesisService.shared.speak(word, languageCode: localeId)
    }
    
    public func reset() {
        speechService.cancelRecognition()
        isSpeaking = false
        liveTranscript = ""
        audioPower = 0.0
        latestTurnFeedback = nil
        showTurnFeedbackSheet = false
        scorecard = nil
        showScorecardView = false
        turnsHistory = []
        isEvaluatingTurn = false
        isGeneratingScorecard = false
        errorMessage = nil
    }
}
