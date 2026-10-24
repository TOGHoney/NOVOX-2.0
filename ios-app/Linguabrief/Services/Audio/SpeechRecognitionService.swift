import Foundation
import Speech
import AVFoundation

/// Hybrid Speech Recognition & Audio Capture Service.
/// Combines native Apple Speech.framework (`SFSpeechRecognizer`) with simultaneous
/// local audio capture (`AVAudioRecorder`) and real-time audio power metering.
///
/// If Apple's on-device speech recognizer is unavailable (e.g. missing Siri assets on Simulator,
/// unsupported locale, or offline network), the recorded audio file is preserved and
/// seamlessly submitted to the backend AI proctor for cloud audio transcription.
@MainActor
public final class SpeechRecognitionService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    
    public static let shared = SpeechRecognitionService()
    
    // MARK: - Published State
    
    @Published public var isRecognizing: Bool = false
    @Published public var liveTranscript: String = ""
    @Published public var recognizedSegments: [TranscriptSegment] = []
    @Published public var audioPower: Float = 0.0 // 0.0 (silent) to 1.0 (loud)
    @Published public var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published public var errorMessage: String? = nil
    @Published public var isRecognizerAvailable: Bool = true
    
    // Apple Speech Recognition
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Audio Recording Backup & Metering
    private var audioRecorder: AVAudioRecorder?
    private var recordedAudioURL: URL?
    private var meterTimer: Timer?
    private var turnStartTime: Date?
    
    private override init() {
        super.init()
        self.authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    // MARK: - Permissions
    
    public func requestAuthorization() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    continuation.resume(returning: (status == .authorized))
                }
            }
        }
        
        let micGranted = await AVAudioApplication.requestRecordPermission()
        return speechGranted || micGranted
    }
    
    // MARK: - Language Locale Resolver
    
    public static func localeIdentifier(for languageName: String) -> String {
        let lower = languageName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch lower {
        case "spanish", "español", "es": return "es-ES"
        case "french", "français", "fr": return "fr-FR"
        case "german", "deutsch", "de": return "de-DE"
        case "japanese", "日本語", "ja": return "ja-JP"
        case "thai", "ไทย", "th": return "th-TH"
        case "chinese", "mandarin", "zh": return "zh-CN"
        case "italian", "italiano", "it": return "it-IT"
        case "portuguese", "português", "pt": return "pt-BR"
        case "russian", "русский", "ru": return "ru-RU"
        default: return "en-US"
        }
    }
    
    // MARK: - Recognition & Audio Capture
    
    public func startRecognition(language: String = "English") throws {
        stopRecognition()
        
        errorMessage = nil
        liveTranscript = ""
        recognizedSegments = []
        audioPower = 0.0
        turnStartTime = Date()
        isRecognizing = true
        
        // 1. Configure audio session for simultaneous speech & recording
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 2. Start backup audio recorder for seamless AI transcription fallback
        startAudioRecorder()
        
        // 3. Attempt Apple Speech Recognition
        startAppleSpeechRecognizer(language: language)
    }
    
    private func startAudioRecorder() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("turn_audio_\(Date().timeIntervalSince1970).m4a")
        self.recordedAudioURL = fileURL
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            // Start meter timer for visual waveform feedback
            meterTimer?.invalidate()
            meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }
                    recorder.updateMeters()
                    let power = recorder.averagePower(forChannel: 0)
                    // Normalize -60dB...0dB to 0.0...1.0
                    let clamped = max(-60.0, min(0.0, power))
                    self.audioPower = (clamped + 60.0) / 60.0
                }
            }
        } catch {
            print("[SpeechRecognitionService] AudioRecorder fallback error: \(error.localizedDescription)")
        }
    }
    
    private func startAppleSpeechRecognizer(language: String) {
        let localeId = Self.localeIdentifier(for: language)
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId)) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("[SpeechRecognitionService] Speech recognizer not available for \(language), relying on AI audio fallback.")
            self.isRecognizerAvailable = false
            return
        }
        
        self.isRecognizerAvailable = true
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let bus = 0
        let recordingFormat = inputNode.outputFormat(forBus: bus)
        
        // Guard against sampleRate 0 on uninitialized simulator audio
        guard recordingFormat.sampleRate > 0 else {
            print("[SpeechRecognitionService] Input node format sampleRate is 0. Audio fallback active.")
            return
        }
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let result = result {
                    let formatted = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !formatted.isEmpty {
                        self.liveTranscript = formatted
                        self.recognizedSegments = result.bestTranscription.segments.map { seg in
                            TranscriptSegment(
                                word: seg.substring,
                                timestamp: seg.timestamp,
                                duration: seg.duration,
                                confidence: Double(seg.confidence)
                            )
                        }
                    }
                }
                
                if let error = error {
                    print("[SpeechRecognitionService] Recognition note: \(error.localizedDescription)")
                }
            }
        }
        
        inputNode.removeTap(onBus: bus)
        inputNode.installTap(onBus: bus, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("[SpeechRecognitionService] AudioEngine start failed: \(error.localizedDescription). Audio recorder will capture speech.")
        }
    }
    
    // MARK: - Stop & Finalize
    
    @discardableResult
    public func stopRecognition() -> (transcript: String, segments: [TranscriptSegment], durationSeconds: Int, audioURL: URL?) {
        meterTimer?.invalidate()
        meterTimer = nil
        
        // Stop audio engine & speech task
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Stop recorder
        audioRecorder?.stop()
        let audioURL = recordedAudioURL
        audioRecorder = nil
        
        let transcript = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let segments = recognizedSegments
        let duration = turnStartTime != nil ? Int(Date().timeIntervalSince(turnStartTime!)) : 0
        
        isRecognizing = false
        audioPower = 0.0
        recognitionRequest = nil
        recognitionTask = nil
        turnStartTime = nil
        
        return (transcript, segments, max(1, duration), audioURL)
    }
    
    public func cancelRecognition() {
        meterTimer?.invalidate()
        meterTimer = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioRecorder?.stop()
        if let url = recordedAudioURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordedAudioURL = nil
        audioRecorder = nil
        
        isRecognizing = false
        liveTranscript = ""
        recognizedSegments = []
        audioPower = 0.0
        recognitionRequest = nil
        recognitionTask = nil
        turnStartTime = nil
    }
}
