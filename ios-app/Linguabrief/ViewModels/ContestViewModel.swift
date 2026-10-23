import Foundation
import SwiftUI

/// View model for competitive contests, timed challenge runner, and global ranked leaderboards.
@MainActor
public final class ContestViewModel: ObservableObject {
    
    @Published public var publicContests: [Contest] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // Active runner state
    @Published public var activeContest: Contest?
    @Published public var userAnswers: [Int: Int] = [:] // Question index -> selected option index
    @Published public var timeElapsedSeconds: Int = 0
    @Published public var isSubmitting: Bool = false
    @Published public var lastScoreResult: Int?
    @Published public var showResultModal: Bool = false
    
    // Leaderboard state
    @Published public var leaderboardEntries: [LeaderboardEntry] = []
    @Published public var isLeaderboardLoading: Bool = false
    @Published public var activeLeaderboardContestId: String?
    
    private var timer: Timer?
    
    public init() {
        Task {
            await fetchPublicContests()
        }
    }
    
    // MARK: - Contest Retrieval
    
    public func fetchPublicContests() async {
        isLoading = true
        errorMessage = nil
        do {
            let list: [Contest] = try await APIClient.shared.request(.publicContests())
            self.publicContests = list
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    public func joinByPasscode(_ code: String) async -> Contest? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        do {
            let contest: Contest = try await APIClient.shared.request(
                .joinContestByPasscode(),
                body: JoinPasscodeRequest(passcode: trimmed)
            )
            return contest
        } catch {
            self.errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Contest Runner
    
    public func startContest(_ contest: Contest) {
        self.activeContest = contest
        self.userAnswers = [:]
        self.timeElapsedSeconds = 0
        self.lastScoreResult = nil
        self.showResultModal = false
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.timeElapsedSeconds += 1
            }
        }
    }
    
    public func selectOption(questionIndex: Int, optionIndex: Int) {
        userAnswers[questionIndex] = optionIndex
    }
    
    public func submitContest() async -> Bool {
        guard let contest = activeContest, !isSubmitting else { return false }
        isSubmitting = true
        timer?.invalidate()
        timer = nil
        
        let payload = ContestSubmissionRequest(
            contestId: contest.id,
            answers: userAnswers,
            timeTakenSeconds: timeElapsedSeconds
        )
        
        do {
            let result: ContestSubmissionResponse = try await APIClient.shared.request(.submitContest(), body: payload)
            self.lastScoreResult = result.score
            self.showResultModal = true
            self.isSubmitting = false
            
            // Mark as attempted in local list
            if let idx = publicContests.firstIndex(where: { $0.id == contest.id }) {
                publicContests[idx].hasAttempted = true
            }
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSubmitting = false
            return false
        }
    }
    
    public func exitContest() {
        timer?.invalidate()
        timer = nil
        activeContest = nil
        userAnswers = [:]
        timeElapsedSeconds = 0
    }
    
    // MARK: - Leaderboard
    
    public func loadLeaderboard(for contestId: String) async {
        activeLeaderboardContestId = contestId
        isLeaderboardLoading = true
        do {
            let entries: [LeaderboardEntry] = try await APIClient.shared.request(.contestLeaderboard(contestId: contestId))
            self.leaderboardEntries = entries
            self.isLeaderboardLoading = false
        } catch {
            self.isLeaderboardLoading = false
        }
    }
}
