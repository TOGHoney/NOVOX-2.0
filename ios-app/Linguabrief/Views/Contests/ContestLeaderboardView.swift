import SwiftUI

/// Ranked leaderboard scoreboard displaying top participants sorted by score and time.
public struct ContestLeaderboardView: View {
    @ObservedObject public var contestVM: ContestViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(contestVM: ContestViewModel) {
        self.contestVM = contestVM
    }
    
    public var body: some View {
        NavigationStack {
            VStack {
                if contestVM.isLeaderboardLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading leaderboard rankings...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contestVM.leaderboardEntries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No submissions yet")
                            .font(.headline)
                        Text("Be the first to complete this contest and claim the top rank!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(contestVM.leaderboardEntries.enumerated()), id: \.element.id) { rank, entry in
                            HStack(spacing: 14) {
                                // Rank Medal / Number
                                Text(medalOrRank(rank: rank + 1))
                                    .font(.system(size: 18, weight: .bold))
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.user.username)
                                        .font(.headline)
                                    Text("Time: \(formatSeconds(entry.timeTakenSeconds))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(entry.score) pts")
                                    .font(.headline)
                                    .foregroundColor(Constants.Colors.brandBurgundy)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func medalOrRank(rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
    
    private func formatSeconds(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}
