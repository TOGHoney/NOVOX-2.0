import SwiftUI

/// Screen listing public competitive contests and passcode-protected private challenges.
public struct ContestListView: View {
    @StateObject private var contestVM = ContestViewModel()
    @State private var passcodeQuery: String = ""
    @State private var passcodeContest: Contest?
    @State private var showPasscodeResultAlert: Bool = false
    @State private var passcodeAlertMessage: String = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Passcode Entry Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                            Text("ENTER PRIVATE CONTEST PASSCODE")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            TextField("Enter passcode (e.g. VOCAB2026)", text: $passcodeQuery)
                                .font(.subheadline)
                                .padding(10)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                            
                            Button(action: {
                                Task {
                                    if let contest = await contestVM.joinByPasscode(passcodeQuery) {
                                        if contest.hasAttempted == true {
                                            passcodeAlertMessage = "You have already completed this contest."
                                            showPasscodeResultAlert = true
                                        } else {
                                            contestVM.startContest(contest)
                                        }
                                    } else {
                                        passcodeAlertMessage = contestVM.errorMessage ?? "Contest not found."
                                        showPasscodeResultAlert = true
                                    }
                                }
                            }) {
                                Text("Join")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Constants.Colors.brandBurgundy)
                                    .cornerRadius(8)
                            }
                            .disabled(passcodeQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding()
                    .cardStyle(backgroundColor: Constants.Colors.cardBackground)
                    .padding(.horizontal)
                    
                    // Public Challenges Section Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Official Contests")
                                .font(.title3.bold())
                            Text("Weekly & monthly reading comprehension challenges")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Contests List
                    if contestVM.isLoading && contestVM.publicContests.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading contests...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if contestVM.publicContests.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No active public contests")
                                .font(.headline)
                            Text("Check back soon or join with a private passcode above.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(contestVM.publicContests) { contest in
                                ContestCardView(
                                    contest: contest,
                                    onStart: {
                                        contestVM.startContest(contest)
                                    },
                                    onViewLeaderboard: {
                                        Task {
                                            await contestVM.loadLeaderboard(for: contest.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationTitle("Contests")
            .refreshable {
                await contestVM.fetchPublicContests()
            }
            .sheet(item: $contestVM.activeContest) { contest in
                ContestRunnerView(contestVM: contestVM, contest: contest)
            }
            .sheet(isPresented: Binding(
                get: { contestVM.activeLeaderboardContestId != nil },
                set: { if !$0 { contestVM.activeLeaderboardContestId = nil } }
            )) {
                ContestLeaderboardView(contestVM: contestVM)
            }
            .alert("Contest Notice", isPresented: $showPasscodeResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(passcodeAlertMessage)
            }
        }
    }
}

private struct ContestCardView: View {
    let contest: Contest
    let onStart: () -> Void
    let onViewLeaderboard: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(contest.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if contest.hasAttempted == true {
                    Label("Completed", systemImage: "checkmark.seal.fill")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(6)
                }
            }
            
            if let desc = contest.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(contest.questions?.count ?? 0) Questions", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onViewLeaderboard) {
                        Label("Rankings", systemImage: "trophy")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                    }
                    
                    if contest.hasAttempted != true {
                        Button(action: onStart) {
                            Text("Start Challenge")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Constants.Colors.brandBurgundy)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(14)
        .cardStyle()
    }
}
