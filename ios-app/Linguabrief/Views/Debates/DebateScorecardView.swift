import SwiftUI

/// Comprehensive end-of-debate scorecard view.
/// Evaluates speech on a 0-100 scale across 4 weighted categories:
/// - Relevance & Argument Quality (30%)
/// - Factual Accuracy & Evidence (25%)
/// - Grammar & Sentence Construction (25%)
/// - Pronunciation & Intelligibility (20%)
public struct DebateScorecardView: View {
    public let scorecard: DebateScorecard
    public let topic: String
    public let turnsCount: Int
    public let onDismiss: () -> Void
    
    public init(
        scorecard: DebateScorecard,
        topic: String,
        turnsCount: Int = 1,
        onDismiss: @escaping () -> Void
    ) {
        self.scorecard = scorecard
        self.topic = topic
        self.turnsCount = turnsCount
        self.onDismiss = onDismiss
    }
    
    private var scoreColor: Color {
        if scorecard.overallScore >= 80 { return .green }
        if scorecard.overallScore >= 60 { return Constants.Colors.goldAccent }
        return .orange
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header Overall Score Ring Card
                    VStack(spacing: 12) {
                        Text("DEBATE SCORECARD")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 10)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(scorecard.overallScore) / 100.0)
                                .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 0) {
                                Text("\(scorecard.overallScore)")
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("out of 100")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Text(scorecard.summary)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            Label("\(turnsCount) Speaking \(turnsCount == 1 ? "Turn" : "Turns")", systemImage: "mic.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Label("Topic: \(topic)", systemImage: "bubble.left.and.bubble.right.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // 4 Weighted Categories Breakdown
                    VStack(alignment: .leading, spacing: 14) {
                        Text("EVALUATION CATEGORIES")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .tracking(1)
                            .padding(.horizontal)
                        
                        categoryCard(
                            title: "Relevance & Argumentation",
                            weight: "30% Weight",
                            icon: "target",
                            color: .blue,
                            category: scorecard.relevance
                        )
                        
                        categoryCard(
                            title: "Factual Accuracy & Evidence",
                            weight: "25% Weight",
                            icon: "checkmark.shield",
                            color: .green,
                            category: scorecard.factualAccuracy
                        )
                        
                        categoryCard(
                            title: "Grammar & Construction",
                            weight: "25% Weight",
                            icon: "text.badge.checkmark",
                            color: .orange,
                            category: scorecard.grammar
                        )
                        
                        categoryCard(
                            title: "Pronunciation & Intelligibility",
                            weight: "20% Weight",
                            icon: "waveform",
                            color: .purple,
                            category: scorecard.pronunciation
                        )
                    }
                    .padding(.horizontal)
                    
                    // Action Footer
                    Button(action: onDismiss) {
                        Text("Done & Return to Debates")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Constants.Colors.brandBurgundy)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
                .padding(.vertical)
            }
            .navigationTitle("Performance Scorecard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDismiss)
                        .bold()
                        .foregroundColor(Constants.Colors.brandBurgundy)
                }
            }
        }
    }
    
    // MARK: - Category Card View
    
    private func categoryCard(
        title: String,
        weight: String,
        icon: String,
        color: Color,
        category: ScorecardCategory
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(weight)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(category.score)")
                    .font(.title2.bold())
                    .foregroundColor(color)
                Text("/ 100")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(category.score), total: 100.0)
                .tint(color)
            
            if category.insufficientEvidence ?? false {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Speech sample was brief for comprehensive analysis.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            Text(category.explanation)
                .font(.footnote)
                .foregroundColor(.primary)
                .lineSpacing(2)
            
            // Evidence Quotes
            if !category.evidence.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EVIDENCE FROM YOUR SPEECH:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    ForEach(category.evidence, id: \.self) { quote in
                        Text("\"\(quote)\"")
                            .font(.system(size: 12, weight: .regular))
                            .italic()
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                            .overlay(
                                Rectangle()
                                    .fill(color.opacity(0.5))
                                    .frame(width: 2),
                                alignment: .leading
                            )
                    }
                }
                .padding(.top, 2)
            }
            
            // Strengths & Areas to Improve
            if !category.strengths.isEmpty || !category.areasToImprove.isEmpty {
                Divider()
                
                if !category.strengths.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(category.strengths, id: \.self) { s in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text(s)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if !category.areasToImprove.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(category.areasToImprove, id: \.self) { a in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text(a)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Practical Next Step
            if !category.practicalNextStep.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "flag.checkered")
                        .font(.caption)
                        .foregroundColor(color)
                    Text("Next Step: \(category.practicalNextStep)")
                        .font(.caption.bold())
                        .foregroundColor(color)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.08))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .cardStyle()
    }
}
