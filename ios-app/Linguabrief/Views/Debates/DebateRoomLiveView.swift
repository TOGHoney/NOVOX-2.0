import SwiftUI

/// Live speaking debate room stage interface with floor queueing, speaking timer, and microphone controls.
public struct DebateRoomLiveView: View {
    @ObservedObject public var debatesVM: DebatesViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var proctorVM = DebateProctorViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init(debatesVM: DebatesViewModel) {
        self.debatesVM = debatesVM
    }
    
    private var formattedTimer: String {
        let m = debatesVM.remainingSpeakingSeconds / 60
        let s = debatesVM.remainingSpeakingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func syncProctorProfile() {
        // Use user's profile settings for proctor evaluation
        proctorVM.targetLanguage = authVM.currentUser?.targetLanguage ?? authVM.targetLanguage ?? debatesVM.activeRoom?.language ?? "English"
        proctorVM.nativeLanguage = authVM.currentUser?.nativeLanguage ?? authVM.nativeLanguage ?? "English"
        proctorVM.cefrLevel = authVM.currentUser?.cefrLevel ?? authVM.cefrLevel ?? debatesVM.activeRoom?.level ?? "B1"
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let room = debatesVM.activeRoom {
                    
                    // Header Card: Topic + Prompt
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            CEFRBadge(room.level ?? "A1")
                            Spacer()
                            Label("\(room.language ?? "English") Room", systemImage: "globe")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                        
                        Text(room.topic)
                            .font(.system(size: 20, weight: .bold))
                        
                        if let prompt = room.prompt, !prompt.isEmpty {
                            Text(prompt)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal)
                    
                    // Stage: Floor Status & Speaking Timer
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .stroke(debatesVM.isFloorHeldByMe ? Color.green : Color(.systemGray4), lineWidth: 4)
                                .frame(width: 130, height: 130)
                            
                            VStack(spacing: 4) {
                                Image(systemName: debatesVM.isFloorHeldByMe ? "mic.fill" : "mic.slash.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(debatesVM.isFloorHeldByMe ? .green : .secondary)
                                
                                Text(formattedTimer)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(debatesVM.isFloorHeldByMe ? .green : .primary)
                            }
                        }
                        
                        Text(debatesVM.isFloorHeldByMe ? "You hold the speaking floor" : "Listening to room discussion")
                            .font(.headline)
                            .foregroundColor(debatesVM.isFloorHeldByMe ? .green : .secondary)
                        
                        Text("3-minute speaking limit per participant.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // Participants Row
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PARTICIPANTS (\(room.participants?.count ?? 1)/\(room.maxParticipants ?? 6))")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                if let participants = room.participants {
                                    ForEach(participants) { p in
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(Color(.systemGray5))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Text(String(p.username.prefix(1)).uppercased())
                                                        .font(.headline)
                                                        .foregroundColor(Constants.Colors.brandBurgundy)
                                                )
                                            Text(p.username)
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 56)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // Live AI Proctor Analyzing Banner
                    if proctorVM.isEvaluatingTurn {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(Constants.Colors.brandBurgundy)
                            Text("AI Debate Proctor is analyzing your turn...")
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Constants.Colors.brandBurgundy.opacity(0.1))
                        .clipShape(Capsule())
                        .transition(.opacity)
                    }
                    
                    // Proctor Notice Banner
                    if let error = proctorVM.errorMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Constants.Colors.goldAccent)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                            Button(action: { proctorVM.errorMessage = nil }) {
                                Image(systemName: "xmark")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Constants.Colors.goldAccent.opacity(0.12))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Live Proctor Transcript Overlay (Active when speaking)
                    DebateLiveTranscriptOverlay(proctorVM: proctorVM)
                    
                    // Floor Action Controls
                    VStack(spacing: 10) {
                        if !debatesVM.isFloorHeldByMe {
                            Button(action: {
                                debatesVM.requestSpeakingFloor()
                            }) {
                                Label("Request Speaking Floor", systemImage: "hand.raised.fill")
                                    .burgundyButtonStyle()
                            }
                        } else {
                            VStack(spacing: 8) {
                                Button(action: {
                                    debatesVM.releaseSpeakingFloor()
                                }) {
                                    Label("Yield Speaking Floor", systemImage: "mic.slash.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.orange)
                                        .cornerRadius(10)
                                }
                                
                                // Simulator / Quick speech demo trigger
                                Button(action: {
                                    proctorVM.endSpeakingTurn(
                                        roomId: room.id,
                                        topic: room.topic,
                                        prompt: room.prompt,
                                        fallbackTranscript: "Yo considero que la energía solar es muy importante porque reducen la polución del aire en las ciudades."
                                    )
                                    debatesVM.releaseSpeakingFloor()
                                }) {
                                    Label("Submit Practice Turn Speech", systemImage: "sparkles")
                                        .font(.caption.bold())
                                        .foregroundColor(Constants.Colors.brandBurgundy)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                } else {
                    ProgressView("Connecting to debate room...")
                }
            }
            .navigationTitle("Live Discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Leave Room") {
                        if !proctorVM.turnsHistory.isEmpty, let room = debatesVM.activeRoom {
                            Task {
                                await proctorVM.finishDebateSession(roomId: room.id)
                            }
                        } else {
                            Task {
                                await debatesVM.leaveRoom()
                                dismiss()
                            }
                        }
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !proctorVM.turnsHistory.isEmpty, let room = debatesVM.activeRoom {
                        Button(action: {
                            Task {
                                await proctorVM.finishDebateSession(roomId: room.id)
                            }
                        }) {
                            Label("Scorecard", systemImage: "rosette")
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                        }
                    }
                }
            }
            .onChange(of: debatesVM.isFloorHeldByMe) { _, isHeld in
                guard let room = debatesVM.activeRoom else { return }
                if isHeld {
                    syncProctorProfile()
                    proctorVM.startSpeakingTurn(language: room.language ?? "English")
                } else {
                    proctorVM.endSpeakingTurn(roomId: room.id, topic: room.topic, prompt: room.prompt)
                }
            }
            .sheet(isPresented: $proctorVM.showTurnFeedbackSheet) {
                if let feedback = proctorVM.latestTurnFeedback, let room = debatesVM.activeRoom {
                    DebateTurnFeedbackSheet(
                        feedback: feedback,
                        targetLanguage: room.language ?? "English",
                        proctorVM: proctorVM,
                        onDismiss: {
                            proctorVM.showTurnFeedbackSheet = false
                        }
                    )
                }
            }
            .sheet(isPresented: $proctorVM.showScorecardView) {
                if let scorecard = proctorVM.scorecard, let room = debatesVM.activeRoom {
                    DebateScorecardView(
                        scorecard: scorecard,
                        topic: room.topic,
                        turnsCount: max(1, proctorVM.turnsHistory.count),
                        onDismiss: {
                            proctorVM.showScorecardView = false
                            Task {
                                await debatesVM.leaveRoom()
                                dismiss()
                            }
                        }
                    )
                }
            }
            .onAppear {
                syncProctorProfile()
            }
        }
    }
}
