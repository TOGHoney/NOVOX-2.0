import SwiftUI

/// Screen listing live debate and discussion rooms for spoken language acquisition.
public struct DebateRoomsListView: View {
    @StateObject private var debatesVM = DebatesViewModel()
    @State private var showCreateRoomSheet: Bool = false
    @State private var showSpeakingPracticeSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Speaking Practice Quick Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Speaking Practice")
                                .font(.headline)
                            Text("Test your microphone and record practice responses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showSpeakingPracticeSheet = true
                        }) {
                            Label("Mic Test", systemImage: "mic.fill")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Constants.Colors.brandBurgundy)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .cardStyle(backgroundColor: Constants.Colors.cardBackground)
                    .padding(.horizontal)
                    
                    // Live Discussion Rooms Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Live Debate Rooms")
                                .font(.title3.bold())
                            Text("Practice conversational fluency with structured speaking turns")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showCreateRoomSheet = true
                        }) {
                            Label("Host", systemImage: "plus")
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Constants.Colors.brandBurgundy.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Rooms List
                    if debatesVM.isLoading && debatesVM.rooms.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading active rooms...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if debatesVM.rooms.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary)
                            Text("No open debate rooms")
                                .font(.headline)
                            Text("Be the first to host a discussion room on a global news topic.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(debatesVM.rooms) { room in
                                DebateRoomCardView(room: room) {
                                    Task {
                                        _ = await debatesVM.joinRoom(id: room.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationTitle("Live Debates")
            .refreshable {
                await debatesVM.fetchRooms()
            }
            .sheet(isPresented: $showCreateRoomSheet) {
                CreateDebateRoomSheet(debatesVM: debatesVM)
            }
            .sheet(item: $debatesVM.activeRoom) { _ in
                DebateRoomLiveView(debatesVM: debatesVM)
            }
            .sheet(isPresented: $showSpeakingPracticeSheet) {
                SpeakingPracticeSheet()
            }
        }
    }
}

private struct DebateRoomCardView: View {
    let room: DebateRoom
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(room.topic)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                CEFRBadge(room.level ?? "A1")
            }
            
            if let prompt = room.prompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(room.language ?? "English")", systemImage: "globe")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(room.participantCount ?? 1)/\(room.maxParticipants ?? 6) speakers", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Join Room", action: onJoin)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Constants.Colors.brandBurgundy)
                    .cornerRadius(6)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

/// Standalone native microphone speaking recorder & playback testing sheet
private struct SpeakingPracticeSheet: View {
    @StateObject private var audioService = AudioRecordingService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var recordedURL: URL?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Native Speaking Practice")
                    .font(.title3.bold())
                
                Text("Record and evaluate your pronunciation of global news headlines.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Mic Meter Waveform Placeholder
                ZStack {
                    Circle()
                        .fill(audioService.isRecording ? Color.red.opacity(0.15) : Color(.systemGray6))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: audioService.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 48))
                        .foregroundColor(audioService.isRecording ? .red : Constants.Colors.brandBurgundy)
                }
                .padding(.vertical, 10)
                
                if audioService.isRecording {
                    Text("Recording: \(String(format: "%.1f", audioService.recordingDuration))s")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                
                // Controls
                VStack(spacing: 12) {
                    if !audioService.isRecording {
                        Button(action: {
                            do {
                                try audioService.startRecording()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }) {
                            Label("Start Recording", systemImage: "record.circle")
                                .burgundyButtonStyle()
                        }
                    } else {
                        Button(action: {
                            recordedURL = audioService.stopRecording()
                        }) {
                            Label("Stop Recording", systemImage: "stop.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                    
                    if let _ = recordedURL, !audioService.isRecording {
                        Button(action: {
                            do {
                                try audioService.startPlayback()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }) {
                            Label(audioService.isPlaying ? "Playing..." : "Listen to Recording", systemImage: "play.circle.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Constants.Colors.brandBurgundy.opacity(0.12))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding(.top, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        audioService.stopRecording()
                        audioService.stopPlayback()
                        dismiss()
                    }
                }
            }
        }
    }
}
