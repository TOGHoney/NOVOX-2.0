import SwiftUI

/// Multiple-choice vocabulary self-quiz runner generated dynamically from saved words pool.
public struct QuizModalView: View {
    public let questions: [QuizQuestion]
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex: Int = 0
    @State private var selectedOption: String?
    @State private var score: Int = 0
    @State private var isAnswerSubmitted: Bool = false
    @State private var isFinished: Bool = false
    
    public init(questions: [QuizQuestion]) {
        self.questions = questions
    }
    
    private var currentQuestion: QuizQuestion? {
        guard !questions.isEmpty, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isFinished {
                    // Quiz Result Celebration View
                    VStack(spacing: 18) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Constants.Colors.goldAccent)
                        
                        Text("Quiz Completed! 🎉")
                            .font(.title.bold())
                        
                        let percentage = questions.isEmpty ? 0 : Int((Double(score) / Double(questions.count)) * 100)
                        Text("You scored \(score) out of \(questions.count) (\(percentage)%)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("Finish") {
                            dismiss()
                        }
                        .burgundyButtonStyle()
                        .frame(width: 160)
                        .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if let q = currentQuestion {
                    
                    // Question Header
                    HStack {
                        Text("Question \(currentIndex + 1) of \(questions.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Score: \(score)")
                            .font(.subheadline.bold())
                            .foregroundColor(Constants.Colors.brandBurgundy)
                    }
                    .padding(.horizontal)
                    
                    // Target Word Card
                    VStack(spacing: 8) {
                        Text("WHAT IS THE MEANING OF:")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        
                        Text(q.word)
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                        
                        if !q.contextSentence.isEmpty {
                            Text("\"\(q.contextSentence)\"")
                                .font(.caption.italic())
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                    .padding(.horizontal)
                    
                    // 4 Options Grid
                    VStack(spacing: 10) {
                        ForEach(q.options, id: \.self) { opt in
                            let isCorrect = opt == q.correctAnswer
                            let isSelected = opt == selectedOption
                            
                            Button(action: {
                                guard !isAnswerSubmitted else { return }
                                selectedOption = opt
                                isAnswerSubmitted = true
                                if isCorrect {
                                    score += 1
                                }
                            }) {
                                HStack {
                                    Text(opt)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(optionTextColor(isCorrect: isCorrect, isSelected: isSelected))
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    if isAnswerSubmitted {
                                        if isCorrect {
                                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                        } else if isSelected {
                                            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding()
                                .background(optionBackgroundColor(isCorrect: isCorrect, isSelected: isSelected))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(optionBorderColor(isCorrect: isCorrect, isSelected: isSelected), lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Next Button
                    if isAnswerSubmitted {
                        Button(action: {
                            if currentIndex < questions.count - 1 {
                                currentIndex += 1
                                selectedOption = nil
                                isAnswerSubmitted = false
                            } else {
                                isFinished = true
                            }
                        }) {
                            Text(currentIndex < questions.count - 1 ? "Next Question →" : "View Results")
                                .burgundyButtonStyle()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                } else {
                    Text("No quiz questions available.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Vocabulary Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Exit") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func optionBackgroundColor(isCorrect: Bool, isSelected: Bool) -> Color {
        if !isAnswerSubmitted {
            return isSelected ? Color(.systemGray5) : Color(.secondarySystemBackground)
        }
        if isCorrect { return Color.green.opacity(0.12) }
        if isSelected { return Color.red.opacity(0.12) }
        return Color(.secondarySystemBackground)
    }
    
    private func optionBorderColor(isCorrect: Bool, isSelected: Bool) -> Color {
        if !isAnswerSubmitted {
            return isSelected ? Constants.Colors.brandBurgundy : Color(.separator).opacity(0.3)
        }
        if isCorrect { return .green }
        if isSelected { return .red }
        return Color(.separator).opacity(0.3)
    }
    
    private func optionTextColor(isCorrect: Bool, isSelected: Bool) -> Color {
        if !isAnswerSubmitted { return .primary }
        if isCorrect { return .green }
        if isSelected { return .red }
        return .primary
    }
}
