import SwiftUI

/// Timed quiz runner interface executing an official contest and submitting answers.
public struct ContestRunnerView: View {
    @ObservedObject public var contestVM: ContestViewModel
    public let contest: Contest
    @Environment(\.dismiss) private var dismiss
    
    public init(contestVM: ContestViewModel, contest: Contest) {
        self.contestVM = contestVM
        self.contest = contest
    }
    
    private var formattedTime: String {
        let m = contestVM.timeElapsedSeconds / 60
        let s = contestVM.timeElapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if contestVM.showResultModal {
                    // Result Card
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)
                        
                        Text("Contest Submitted! 🎉")
                            .font(.title2.bold())
                        
                        Text("Your final score: \(contestVM.lastScoreResult ?? 0) points")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Time taken: \(formattedTime)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Return to Contests") {
                            contestVM.exitContest()
                            dismiss()
                        }
                        .burgundyButtonStyle()
                        .frame(width: 200)
                        .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    // Questions ScrollView
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // Timer Banner
                            HStack {
                                Text(contest.title)
                                    .font(.headline)
                                Spacer()
                                Label(formattedTime, systemImage: "clock.fill")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Constants.Colors.brandBurgundy)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Constants.Colors.brandBurgundy.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.bottom, 6)
                            
                            if let questions = contest.questions, !questions.isEmpty {
                                ForEach(Array(questions.enumerated()), id: \.offset) { qIdx, question in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("\(qIdx + 1). \(question.questionText)")
                                            .font(.system(size: 16, weight: .bold))
                                        
                                        VStack(spacing: 8) {
                                            ForEach(Array(question.options.enumerated()), id: \.offset) { oIdx, option in
                                                let isSelected = contestVM.userAnswers[qIdx] == oIdx
                                                Button(action: {
                                                    contestVM.selectOption(questionIndex: qIdx, optionIndex: oIdx)
                                                }) {
                                                    HStack {
                                                        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                                                            .foregroundColor(isSelected ? Constants.Colors.brandBurgundy : .secondary)
                                                        Text(option)
                                                            .font(.subheadline)
                                                            .foregroundColor(.primary)
                                                            .multilineTextAlignment(.leading)
                                                        Spacer()
                                                    }
                                                    .padding(12)
                                                    .background(isSelected ? Constants.Colors.brandBurgundy.opacity(0.08) : Color(.secondarySystemBackground))
                                                    .cornerRadius(8)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                    .padding()
                                    .cardStyle()
                                }
                            } else {
                                Text("No questions found in this challenge.")
                                    .foregroundColor(.secondary)
                            }
                            
                            // Submit Button
                            Button(action: {
                                Task {
                                    _ = await contestVM.submitContest()
                                }
                            }) {
                                if contestVM.isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Submit Contest")
                                        .burgundyButtonStyle()
                                }
                            }
                            .disabled(contestVM.isSubmitting)
                            .padding(.top, 12)
                            .padding(.bottom, 24)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Timed Contest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Exit") {
                        contestVM.exitContest()
                        dismiss()
                    }
                }
            }
        }
    }
}
