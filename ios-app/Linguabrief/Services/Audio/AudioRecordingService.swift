import Foundation
import AVFoundation

/// Native microphone permission and audio recording service.
/// Powers speaking exercises, voice verification, and debate room audio prerequisites.
@MainActor
public final class AudioRecordingService: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    public static let shared = AudioRecordingService()
    
    @Published public var hasPermission: Bool = false
    @Published public var isRecording: Bool = false
    @Published public var isPlaying: Bool = false
    @Published public var recordingDuration: TimeInterval = 0
    @Published public var averagePower: Float = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var recordingURL: URL?
    
    private override init() {
        super.init()
        checkPermission()
    }
    
    // MARK: - Permissions
    
    public func checkPermission() {
        let status = AVAudioApplication.shared.recordPermission
        self.hasPermission = (status == .granted)
    }
    
    public func requestMicrophonePermission() async -> Bool {
        let granted = await AVAudioApplication.requestRecordPermission()
        self.hasPermission = granted
        return granted
    }
    
    // MARK: - Recording
    
    public func startRecording() throws {
        guard hasPermission else {
            throw NSError(domain: "LinguabriefAudio", code: 403, userInfo: [NSLocalizedDescriptionKey: "Microphone access not granted."])
        }
        
        stopPlayback()
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("speaking_practice_\(Date().timeIntervalSince1970).m4a")
        self.recordingURL = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        isRecording = true
        recordingDuration = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }
                recorder.updateMeters()
                self.recordingDuration = recorder.currentTime
                self.averagePower = recorder.averagePower(forChannel: 0)
            }
        }
    }
    
    public func stopRecording() -> URL? {
        timer?.invalidate()
        timer = nil
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        return recordingURL
    }
    
    // MARK: - Playback
    
    public func startPlayback() throws {
        guard let url = recordingURL, FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(domain: "LinguabriefAudio", code: 404, userInfo: [NSLocalizedDescriptionKey: "No recorded audio found."])
        }
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.play()
        isPlaying = true
    }
    
    public func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
    
    // MARK: - Delegates
    
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}
