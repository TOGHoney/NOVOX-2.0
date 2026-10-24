import SwiftUI

/// Bottom sheet presenting immediate AI proctor feedback after a speaking turn finishes.
/// Evaluates grammar, pronunciation with audio playback, argumentation relevance, factual claims, and immediate tips.
public struct DebateTurnFeedbackSheet: View {
    public let feedback: TurnProctorFeedback
    public let targetLanguage: String
    public let onDismiss: () -> Void
    
    @ObservedObject public var proctorVM: DebateProctorViewModel
    @State private var selectedTab: FeedbackTab = .summary
    
    public enum FeedbackTab: String, CaseIterable, Identifiable {
        case summary = "Overview"
        case grammar = "Grammar"
        case pronunciation = "Pronunciation"
        case argumentation = "Reasoning"
        case facts = "Fact Check"
        
        public var id: String { rawValue }
        
        public var iconName: String {
            switch self {
            case .summary: return "sparkles"
            case .grammar: return "text.badge.checkmark"
            case .pronunciation: return "waveform.badge.mic"
            case .argumentation: return "brain.head.profile"
            case .facts: return "checkmark.shield"
            }
        }
    }
    
    public init(
        feedback: TurnProctorFeedback,
        targetLanguage: String = "English",
        proctorVM: DebateProctorViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.feedback = feedback
        self.targetLanguage = targetLanguage
        self.proctorVM = proctorVM
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Selector Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FeedbackTab.allCases) { tab in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.iconName)
                                        .font(.caption2)
                                    Text(tab.rawValue)
                                        .font(.caption.bold())
                                    
                                    // Badges for issue counts
                                    if tab == .grammar && !feedback.grammar.isEmpty {
                                        Text("\(feedback.grammar.count)")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.2))
                                            .foregroundColor(.orange)
                                            .clipShape(Capsule())
                                    } else if tab == .pronunciation && !feedback.pronunciation.isEmpty {
                                        Text("\(feedback.pronunciation.count)")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.2))
                                            .foregroundColor(.purple)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedTab == tab ? Constants.Colors.brandBurgundy : Color(.systemGray6))
                                .foregroundColor(selectedTab == tab ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))
                
                Divider()
                
                // Tab Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .summary:
                            summarySection
                        case .grammar:
                            grammarSection
                        case .pronunciation:
                            pronunciationSection
                        case .argumentation:
                            argumentationSection
                        case .facts:
                            factsSection
                        }
                    }
                    .padding(16)
                }
                
                Divider()
                
                // Action Footer
                Button(action: onDismiss) {
                    Text("Ready for Next Turn")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Constants.Colors.brandBurgundy)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Turn \(feedback.turnIndex) Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Overview / Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // Immediate Next-Turn Improvement Tip
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Constants.Colors.goldAccent)
                    Text("IMMEDIATE IMPROVEMENT TIP")
                        .font(.caption.bold())
                        .foregroundColor(Constants.Colors.goldAccent)
                }
                
                Text(feedback.immediateTip)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(3)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Constants.Colors.goldAccent.opacity(0.12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Constants.Colors.goldAccent.opacity(0.3), lineWidth: 1)
            )
            
            // Turn Stats Grid
            HStack(spacing: 12) {
                statCard(title: "Relevance", value: "\(feedback.argumentation.relevanceScore)/100", icon: "target", color: .blue)
                statCard(title: "Grammar Notes", value: "\(feedback.grammar.count)", icon: "text.badge.checkmark", color: feedback.grammar.isEmpty ? .green : .orange)
                statCard(title: "Phoneme Notes", value: "\(feedback.pronunciation.count)", icon: "waveform", color: feedback.pronunciation.isEmpty ? .green : .purple)
            }
            
            // Spoken Transcript Card
            VStack(alignment: .leading, spacing: 8) {
                Text("SPOKEN TRANSCRIPT (\(feedback.durationSeconds)s)")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                
                Text("\"\(feedback.transcript)\"")
                    .font(.footnote)
                    .italic()
                    .foregroundColor(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Key Argumentation Assessment
            VStack(alignment: .leading, spacing: 8) {
                Text("ARGUMENT QUALITY")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                
                Text(feedback.argumentation.assessment)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(feedback.argumentation.actionableImprovement)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(14)
            .cardStyle()
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.primary)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Grammar Section
    
    private var grammarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if feedback.grammar.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                    Text("Excellent Grammar")
                        .font(.headline)
                    Text("No target-language grammar mistakes detected in this speaking turn.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .cardStyle()
            } else {
                ForEach(feedback.grammar) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            if item.isStylistic {
                                Label("Stylistic Suggestion", systemImage: "sparkles")
                                    .font(.caption2.bold())
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.purple.opacity(0.15))
                                    .clipShape(Capsule())
                            } else {
                                Label("Grammar Correction", systemImage: "exclamationmark.circle.fill")
                                    .font(.caption2.bold())
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.red.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        
                        // Original
                        VStack(alignment: .leading, spacing: 2) {
                            Text("YOU SAID:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(item.originalSentence)
                                .font(.footnote)
                                .strikethrough(color: .red)
                                .foregroundColor(.primary)
                        }
                        
                        // Correction
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CORRECTED:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                            Text(item.correctedSentence)
                                .font(.footnote.bold())
                                .foregroundColor(.green)
                        }
                        
                        // Natural Alternative
                        if let alt = item.naturalAlternative, !alt.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("NATURAL NATIVE ALTERNATIVE:")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.blue)
                                Text(alt)
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Explanation
                        Text(item.explanation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                            .padding(.top, 2)
                    }
                    .padding(14)
                    .cardStyle()
                }
            }
        }
    }
    
    // MARK: - Pronunciation Section
    
    private var pronunciationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if feedback.pronunciation.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.badge.mic")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                    Text("Clear Intelligibility")
                        .font(.headline)
                    Text("No significant phoneme or pronunciation ambiguities were detected.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .cardStyle()
            } else {
                ForEach(feedback.pronunciation) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.word)
                                    .font(.title3.bold())
                                    .foregroundColor(.primary)
                                Text(item.expectedPronunciation)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(Constants.Colors.brandBurgundy)
                            }
                            
                            Spacer()
                            
                            // Audio Playback Button
                            Button(action: {
                                proctorVM.playPronunciation(word: item.word, targetLanguage: targetLanguage)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "speaker.wave.2.fill")
                                    Text("Listen")
                                }
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Constants.Colors.brandBurgundy)
                                .clipShape(Capsule())
                            }
                        }
                        
                        Text(item.phonemeIssue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                        
                        HStack {
                            Text("Acoustic Status: \(item.confidence.capitalized)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(item.confidence == "uncertain" ? .orange : .secondary)
                            Spacer()
                            if item.audioTimestamp > 0 {
                                Text(String(format: "At %.1fs", item.audioTimestamp))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .cardStyle()
                }
            }
        }
    }
    
    // MARK: - Argumentation Section
    
    private var argumentationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Motion Relevance")
                        .font(.headline)
                    Spacer()
                    Text("\(feedback.argumentation.relevanceScore)%")
                        .font(.title3.bold())
                        .foregroundColor(feedback.argumentation.relevanceScore >= 70 ? .green : .orange)
                }
                
                ProgressView(value: Double(feedback.argumentation.relevanceScore), total: 100.0)
                    .tint(feedback.argumentation.relevanceScore >= 70 ? .green : .orange)
                
                Text(feedback.argumentation.assessment)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
            .padding(14)
            .cardStyle()
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Actionable Reasoning Improvement", systemImage: "arrow.up.forward.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                
                Text(feedback.argumentation.actionableImprovement)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
            .padding(14)
            .cardStyle()
        }
    }
    
    // MARK: - Facts Section
    
    private var factsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if feedback.factualClaims.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No Empirical Claims")
                        .font(.headline)
                    Text("No explicit factual claims or statistics were asserted in this turn.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .cardStyle()
            } else {
                ForEach(feedback.factualClaims) { claim in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            claimStatusBadge(claim.status)
                            Spacer()
                            if let citation = claim.citation {
                                Text(citation)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("\"\(claim.claim)\"")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        Text(claim.explanation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                    .padding(14)
                    .cardStyle()
                }
            }
        }
    }
    
    private func claimStatusBadge(_ status: String) -> some View {
        let lower = status.lowercased()
        let text: String
        let color: Color
        let icon: String
        
        switch lower {
        case "supported":
            text = "Supported Fact"
            color = .green
            icon = "checkmark.shield.fill"
        case "contradicted":
            text = "Contradicted"
            color = .red
            icon = "xmark.shield.fill"
        case "opinion":
            text = "Opinion / Perspective"
            color = .blue
            icon = "quote.bubble.fill"
        default:
            text = "Unverified Claim"
            color = .orange
            icon = "questionmark.circle.fill"
        }
        
        return Label(text, systemImage: icon)
            .font(.caption2.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
