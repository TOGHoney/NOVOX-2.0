import SwiftUI

/// Admin-only view showing the roster of registered participants for a contest.
public struct AdminContestParticipantsView: View {
    @ObservedObject var contestVM: ContestViewModel
    let contest: Contest
    @Environment(\.dismiss) private var dismiss
    
    public init(contestVM: ContestViewModel, contest: Contest) {
        self.contestVM = contestVM
        self.contest = contest
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if contestVM.isParticipantsLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading participant roster...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let response = contestVM.adminParticipantsResponse {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(response.contestTitle)
                                    .font(.headline)
                                HStack {
                                    Label("\(response.totalCount) Registered", systemImage: "person.2.fill")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Constants.Colors.brandBurgundy)
                                    Spacer()
                                    if let max = contest.maxParticipants, max > 0 {
                                        Text("Capacity: \(response.totalCount)/\(max)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if response.participants.isEmpty {
                            Section {
                                Text("No participants have registered for this contest yet.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 12)
                            }
                        } else {
                            Section("Registered Participants (\(response.participants.count))") {
                                ForEach(response.participants) { participant in
                                    ParticipantRow(participant: participant)
                                }
                            }
                        }
                    }
                } else if let error = contestVM.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await contestVM.loadParticipants(contestId: contest.id)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Participant Roster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await contestVM.loadParticipants(contestId: contest.id)
            }
        }
    }
}

private struct ParticipantRow: View {
    let participant: ContestParticipantEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Constants.Colors.brandBurgundy)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(participant.user?.username.prefix(1) ?? "U").uppercased())
                        .font(.headline.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(participant.user?.username ?? "Anonymous Learner")
                    .font(.subheadline.bold())
                
                if let email = participant.user?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 6) {
                    if let lang = participant.user?.targetLanguage {
                        Text(lang)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }
                    if let cefr = participant.user?.cefrLevel {
                        Text(cefr)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Constants.Colors.brandBurgundy.opacity(0.1))
                            .foregroundColor(Constants.Colors.brandBurgundy)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge(participant.status)
                
                if let score = participant.score {
                    Text("Score: \(score)")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusBadge(_ status: String) -> some View {
        let (color, title) = colorAndTitle(for: status)
        return Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }
    
    private func colorAndTitle(for status: String) -> (Color, String) {
        switch status.lowercased() {
        case "participated": return (.green, "COMPLETED")
        case "withdrawn": return (.gray, "LEFT")
        case "cancelled": return (.red, "CANCELLED")
        default: return (.blue, "REGISTERED")
        }
    }
}
