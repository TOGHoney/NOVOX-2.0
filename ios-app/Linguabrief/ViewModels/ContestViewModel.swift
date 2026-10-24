import Foundation
import SwiftUI

/// View model for competitive contests, admin contest management, user participation,
/// timed challenge runner, and global ranked leaderboards.
@MainActor
public final class ContestViewModel: ObservableObject {
    
    // Contests Directory State
    @Published public var contests: [Contest] = []
    @Published public var myContests: [Contest] = []
    @Published public var publicContests: [Contest] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var actionSuccessMessage: String?
    @Published public var isActionLoading: Bool = false
    
    // Filtering State
    @Published public var selectedTab: Int = 0 // 0 = All Contests, 1 = My Contests
    @Published public var selectedTypeFilter: String = "All"
    @Published public var selectedDifficultyFilter: String = "All"
    @Published public var selectedStatusFilter: String = "All"
    @Published public var searchQuery: String = ""
    
    // Detail & Admin Modals State
    @Published public var selectedContestForDetail: Contest?
    @Published public var showCreateContestSheet: Bool = false
    @Published public var selectedContestForAdminEdit: Contest?
    @Published public var selectedContestForParticipants: Contest?
    @Published public var adminParticipantsResponse: ContestParticipantsResponse?
    @Published public var isParticipantsLoading: Bool = false
    
    // Active runner state (Vocabulary Quiz & Challenge)
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
            await refreshAll()
        }
    }
    
    // MARK: - Central Refresh
    
    public func refreshAll() async {
        await fetchContests()
        await fetchMyContests()
    }
    
    // MARK: - Contest Retrieval & Filtering
    
    public func fetchContests() async {
        isLoading = true
        errorMessage = nil
        do {
            let typeParam = selectedTypeFilter == "All" ? nil : selectedTypeFilter
            let diffParam = selectedDifficultyFilter == "All" ? nil : selectedDifficultyFilter
            let statusParam = selectedStatusFilter == "All" ? nil : selectedStatusFilter.lowercased()
            
            let list: [Contest] = try await APIClient.shared.request(
                .contests(
                    status: statusParam,
                    type: typeParam,
                    language: nil,
                    difficulty: diffParam,
                    filter: nil
                )
            )
            self.contests = list
            self.publicContests = list
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    public func fetchMyContests() async {
        do {
            let list: [Contest] = try await APIClient.shared.request(.myContests())
            self.myContests = list
        } catch {
            // Silently fail or log if user is guest
        }
    }
    
    public func fetchContestDetails(id: String) async -> Contest? {
        do {
            let contest: Contest = try await APIClient.shared.request(.contestDetails(id: id))
            self.selectedContestForDetail = contest
            return contest
        } catch {
            self.errorMessage = error.localizedDescription
            return nil
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
    
    // MARK: - User Participation (Join & Leave)
    
    public func joinContest(_ contest: Contest) async -> Bool {
        isActionLoading = true
        errorMessage = nil
        do {
            let response: JoinContestResponse = try await APIClient.shared.request(.joinContest(id: contest.id))
            self.actionSuccessMessage = response.message
            
            // Update local contest state immediately
            if let updated = response.contest {
                updateContestLocally(updated)
            } else {
                var modified = contest
                modified.isRegistered = true
                modified.participantCount = (modified.participantCount ?? 0) + 1
                updateContestLocally(modified)
            }
            
            await fetchMyContests()
            self.isActionLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isActionLoading = false
            return false
        }
    }
    
    public func leaveContest(_ contest: Contest) async -> Bool {
        isActionLoading = true
        errorMessage = nil
        do {
            let response: SimpleMessageResponse = try await APIClient.shared.request(.leaveContest(id: contest.id))
            self.actionSuccessMessage = response.message
            
            var modified = contest
            modified.isRegistered = false
            modified.participantCount = max((modified.participantCount ?? 1) - 1, 0)
            updateContestLocally(modified)
            
            await fetchMyContests()
            self.isActionLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isActionLoading = false
            return false
        }
    }
    
    private func updateContestLocally(_ updated: Contest) {
        if let idx = contests.firstIndex(where: { $0.id == updated.id }) {
            contests[idx] = updated
        }
        if let idx = publicContests.firstIndex(where: { $0.id == updated.id }) {
            publicContests[idx] = updated
        }
        if selectedContestForDetail?.id == updated.id {
            selectedContestForDetail = updated
        }
    }
    
    // MARK: - Admin Contest Management
    
    public func createContest(payload: CreateContestRequest) async -> Bool {
        isActionLoading = true
        errorMessage = nil
        do {
            let response: JoinContestResponse = try await APIClient.shared.request(
                .createContest(),
                body: payload
            )
            self.actionSuccessMessage = "Contest created and published successfully!"
            await refreshAll()
            self.isActionLoading = false
            self.showCreateContestSheet = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isActionLoading = false
            return false
        }
    }
    
    public func editContest(id: String, payload: EditContestRequest) async -> Bool {
        isActionLoading = true
        errorMessage = nil
        do {
            let response: JoinContestResponse = try await APIClient.shared.request(
                .editContest(id: id),
                body: payload
            )
            self.actionSuccessMessage = "Contest updated successfully!"
            if let updated = response.contest {
                updateContestLocally(updated)
            }
            await refreshAll()
            self.isActionLoading = false
            self.selectedContestForAdminEdit = nil
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isActionLoading = false
            return false
        }
    }
    
    public func cancelContest(id: String) async -> Bool {
        isActionLoading = true
        errorMessage = nil
        do {
            let response: JoinContestResponse = try await APIClient.shared.request(.cancelContest(id: id))
            self.actionSuccessMessage = "Contest has been cancelled."
            if let updated = response.contest {
                updateContestLocally(updated)
            }
            await refreshAll()
            self.isActionLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isActionLoading = false
            return false
        }
    }
    
    public func loadParticipants(contestId: String) async {
        isParticipantsLoading = true
        adminParticipantsResponse = nil
        do {
            let resp: ContestParticipantsResponse = try await APIClient.shared.request(.contestParticipants(id: contestId))
            self.adminParticipantsResponse = resp
            self.isParticipantsLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isParticipantsLoading = false
        }
    }
    
    // MARK: - Contest Runner (Quizzes & Challenges)
    
    public func startContest(_ contest: Contest) {
        // Fetch fresh contest details with questions before starting
        Task {
            if let freshContest = await fetchContestDetails(id: contest.id) {
                await MainActor.run {
                    self.activeContest = freshContest
                    self.userAnswers = [:]
                    self.timeElapsedSeconds = 0
                    self.lastScoreResult = nil
                    self.showResultModal = false
                    
                    self.timer?.invalidate()
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            self?.timeElapsedSeconds += 1
                        }
                    }
                }
            } else {
                // Fallback to passed contest if fetch fails
                await MainActor.run {
                    self.activeContest = contest
                    self.userAnswers = [:]
                    self.timeElapsedSeconds = 0
                    self.lastScoreResult = nil
                    self.showResultModal = false
                    
                    self.timer?.invalidate()
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            self?.timeElapsedSeconds += 1
                        }
                    }
                }
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
            var updated = contest
            updated.hasAttempted = true
            updateContestLocally(updated)
            await fetchMyContests()
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
