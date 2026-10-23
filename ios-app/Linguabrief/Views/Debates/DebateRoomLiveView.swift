import SwiftUI

/// Live speaking debate room stage interface with floor queueing, speaking timer, and microphone controls.
public struct DebateRoomLiveView: View {
    @ObservedObject public var debatesVM: DebatesViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(debatesVM: DebatesViewModel) {
        self.debatesVM = debatesVM
    }
    
    private var formattedTimer: String {
        let m = debatesVM.remainingSpeakingSeconds / 60
        let s = debatesVM.remainingSpeakingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
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
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(debatesVM.isFloorHeldByMe ? Color.green : Color(.systemGray4), lineWidth: 4)
                                .frame(width: 140, height: 140)
                            
                            VStack(spacing: 4) {
                                Image(systemName: debatesVM.isFloorHeldByMe ? "mic.fill" : "mic.slash.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(debatesVM.isFloorHeldByMe ? .green : .secondary)
                                
                                Text(formattedTimer)
                                    .font(.system(size: 26, weight: .bold, design: .monospaced))
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
                    .padding()
                    
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
                                                .frame(width: 48, height: 48)
                                                .overlay(
                                                    Text(String(p.username.prefix(1)).uppercased())
                                                        .font(.headline)
                                                        .foregroundColor(Constants.Colors.brandBurgundy)
                                                )
                                            Text(p.username)
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 60)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
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
                        Task {
                            await debatesVM.leaveRoom()
                            dismiss()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}
