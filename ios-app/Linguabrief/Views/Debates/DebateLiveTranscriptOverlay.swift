import SwiftUI

/// Floating live transcript and voice activity HUD during active speaking turns.
/// Displays an animated audio waveform responding to the user's voice power,
/// live speech transcription, and a dictation/speech entry assistant.
public struct DebateLiveTranscriptOverlay: View {
    @ObservedObject public var proctorVM: DebateProctorViewModel
    @State private var showManualInputSheet: Bool = false
    @State private var manualText: String = ""
    
    public init(proctorVM: DebateProctorViewModel) {
        self.proctorVM = proctorVM
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            if proctorVM.isSpeaking {
                if !proctorVM.isOverlayExpanded {
                    // Collapsed Compact Pill with Live Waveform
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            proctorVM.isOverlayExpanded = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            // Pulsating / Dynamic Waveform
                            waveformBarView(height: 14)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(proctorVM.liveTranscript.isEmpty ? "AI Proctor Listening..." : "Transcribing...")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                if !proctorVM.liveTranscript.isEmpty {
                                    Text(proctorVM.liveTranscript)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.up")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Expanded Transcript & Mic HUD
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: 6) {
                                waveformBarView(height: 16)
                                Text("LIVE PROCTOR HUD")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    proctorVM.isOverlayExpanded = false
                                }
                            }) {
                                Image(systemName: "chevron.down")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                    .padding(4)
                            }
                        }
                        
                        // Live Transcript Area
                        ScrollView {
                            if proctorVM.liveTranscript.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "mic.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        Text(proctorVM.audioPower > 0.15 ? "Voice audio detected! Speak clearly for live transcription." : "Speak into your microphone in the debate language.")
                                            .font(.footnote)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Text("Tip: On Mac Simulator, use the 'Dictate / Edit' button below to type or dictate your argument manually.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(proctorVM.liveTranscript)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineSpacing(3)
                            }
                        }
                        .frame(maxHeight: 85)
                        
                        Divider()
                        
                        // Action Bar: Audio Status & Manual Dictation Option
                        HStack {
                            Label(
                                proctorVM.audioPower > 0.1 ? "Mic Active" : "Waiting for voice...",
                                systemImage: proctorVM.audioPower > 0.1 ? "waveform.path" : "waveform"
                            )
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(proctorVM.audioPower > 0.1 ? .green : .secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                manualText = proctorVM.liveTranscript
                                showManualInputSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil.and.outline")
                                    Text("Dictate / Edit")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Constants.Colors.brandBurgundy)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Constants.Colors.brandBurgundy.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showManualInputSheet) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dictate or type your speaking turn:")
                        .font(.headline)
                    
                    TextEditor(text: $manualText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .frame(height: 160)
                    
                    Text("You can tap the iOS microphone on the keyboard to dictate in your target language.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        let trimmed = manualText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            proctorVM.liveTranscript = trimmed
                        }
                        showManualInputSheet = false
                    }) {
                        Text("Save Spoken Argument")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Constants.Colors.brandBurgundy)
                            .cornerRadius(12)
                    }
                }
                .padding(20)
                .navigationTitle("Dictate / Edit Speech")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") {
                            showManualInputSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Animated Waveform View
    
    private func waveformBarView(height: CGFloat) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                let scale: CGFloat = {
                    let base = CGFloat(proctorVM.audioPower)
                    if base < 0.05 {
                        return 0.25
                    }
                    let variation = sin(Double(index) * 1.2 + Double(proctorVM.audioPower) * 4.0)
                    return max(0.2, min(1.0, base + CGFloat(abs(variation)) * 0.4))
                }()
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(proctorVM.audioPower > 0.1 ? Color.green : Color.secondary)
                    .frame(width: 3, height: max(4, height * scale))
                    .animation(.easeInOut(duration: 0.1), value: proctorVM.audioPower)
            }
        }
        .frame(height: height)
    }
}
