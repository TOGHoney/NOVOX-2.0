import SwiftUI

/// Main Contests hub listing active, upcoming, and joined challenges,
/// with real-time filtering, admin contest creation, and activity integration.
public struct ContestListView: View {
    @StateObject private var contestVM = ContestViewModel()
    @EnvironmentObject private var authVM: AuthViewModel
    
    @State private var passcodeQuery: String = ""
    @State private var showPasscodeResultAlert: Bool = false
    @State private var passcodeAlertMessage: String = ""
    
    private let activityTypes = ["All", "Debate", "Vocabulary Quiz", "Language Challenge"]
    private let difficultyOptions = ["All", "A1", "A2", "B1", "B2", "C1", "C2"]
    
    public init() {}
    
    private var displayedContests: [Contest] {
        let baseList = contestVM.selectedTab == 1 ? contestVM.myContests : contestVM.contests
        return baseList.filter { contest in
            // Type filter
            if contestVM.selectedTypeFilter != "All" && contest.effectiveType != contestVM.selectedTypeFilter {
                return false
            }
            // Difficulty filter
            if contestVM.selectedDifficultyFilter != "All" && contest.effectiveDifficulty != contestVM.selectedDifficultyFilter {
                return false
            }
            // Search filter
            if !contestVM.searchQuery.isEmpty {
                let query = contestVM.searchQuery.lowercased()
                let titleMatch = contest.title.lowercased().contains(query)
                let descMatch = contest.description?.lowercased().contains(query) ?? false
                if !titleMatch && !descMatch { return false }
            }
            return true
        }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Segmented Control (All Contests vs My Contests)
                    Picker("Contest View", selection: $contestVM.selectedTab) {
                        Text("All Contests").tag(0)
                        Text("My Contests (\(contestVM.myContests.count))").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Filter Chips (Type & Difficulty)
                    filterChipsSection
                    
                    // Success Banner
                    if let success = contestVM.actionSuccessMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(success)
                                .font(.caption.bold())
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    // Passcode Entry Card (Collapsible)
                    passcodeEntryCard
                        .padding(.horizontal)
                    
                    // Contests List Content
                    if contestVM.isLoading && displayedContests.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading contests...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if displayedContests.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: 14) {
                            ForEach(displayedContests) { contest in
                                NavigationLink(destination: ContestDetailView(contestVM: contestVM, contest: contest)) {
                                    ContestCardRow(
                                        contest: contest,
                                        onViewLeaderboard: {
                                            Task {
                                                await contestVM.loadLeaderboard(for: contest.id)
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Contests")
            .searchable(text: $contestVM.searchQuery, prompt: "Search contests by title or topic")
            .refreshable {
                await contestVM.refreshAll()
            }
            .toolbar {
                // Admin Create Contest Button
                if authVM.isAdmin {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { contestVM.showCreateContestSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create")
                                    .bold()
                            }
                            .foregroundColor(Constants.Colors.brandBurgundy)
                        }
                    }
                }
            }
            .sheet(isPresented: $contestVM.showCreateContestSheet) {
                AdminCreateContestView(contestVM: contestVM)
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
            .alert("Passcode Entry Notice", isPresented: $showPasscodeResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(passcodeAlertMessage)
            }
        }
    }
    
    // MARK: - Filter Chips
    
    private var filterChipsSection: some View {
        VStack(spacing: 8) {
            // Activity Type Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(activityTypes, id: \.self) { type in
                        let isSelected = contestVM.selectedTypeFilter == type
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                contestVM.selectedTypeFilter = type
                            }
                        }) {
                            Text(type)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSelected ? Constants.Colors.brandBurgundy : Color(.systemGray6))
                                .foregroundColor(isSelected ? .white : .primary)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Difficulty Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("Level:")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                    
                    ForEach(difficultyOptions, id: \.self) { diff in
                        let isSelected = contestVM.selectedDifficultyFilter == diff
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                contestVM.selectedDifficultyFilter = diff
                            }
                        }) {
                            Text(diff)
                                .font(.caption2.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.blue : Color(.systemGray6))
                                .foregroundColor(isSelected ? .white : .secondary)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.trailing, 16)
            }
        }
    }
    
    // MARK: - Passcode Card
    
    private var passcodeEntryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "key.fill")
                    .font(.caption.bold())
                    .foregroundColor(Constants.Colors.brandBurgundy)
                Text("HAVE A PRIVATE INVITE CODE?")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                TextField("Enter passcode (e.g. SPANISH2026)", text: $passcodeQuery)
                    .font(.subheadline)
                    .autocapitalization(.allCharacters)
                    .padding(8)
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
                            passcodeAlertMessage = contestVM.errorMessage ?? "Contest not found with that passcode."
                            showPasscodeResultAlert = true
                        }
                    }
                }) {
                    Text("Enter")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Constants.Colors.brandBurgundy)
                        .cornerRadius(8)
                }
                .disabled(passcodeQuery.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(10)
        .cardStyle(backgroundColor: Color(.secondarySystemBackground))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: contestVM.selectedTab == 1 ? "flag.checkered" : "trophy")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(contestVM.selectedTab == 1 ? "No joined contests yet" : "No contests found")
                .font(.headline)
            Text(contestVM.selectedTab == 1
                 ? "Browse upcoming challenges in 'All Contests' and join one to participate!"
                 : "Try adjusting your filters or check back soon for new competitions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Contest Card Row

private struct ContestCardRow: View {
    let contest: Contest
    let onViewLeaderboard: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // Header Row: Type badge, Difficulty, Language, Status
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: iconForType(contest.effectiveType))
                    Text(contest.effectiveType)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Constants.Colors.brandBurgundy)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Constants.Colors.brandBurgundy.opacity(0.1))
                .cornerRadius(4)
                
                Text(contest.effectiveDifficulty)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Text(contest.effectiveLanguage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                statusBadge(contest.activeStatus)
            }
            
            // Title & Description
            Text(contest.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            if let desc = contest.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Divider().padding(.vertical, 2)
            
            // Footer Info: Participants, Schedule, Joined Badge
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(capacityString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if contest.isRegistered == true {
                    Label("Registered", systemImage: "checkmark.seal.fill")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(6)
                }
                
                Button(action: onViewLeaderboard) {
                    Image(systemName: "trophy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .cardStyle()
    }
    
    private func capacityString() -> String {
        let count = contest.participantCount ?? 0
        if let max = contest.maxParticipants, max > 0 {
            return "\(count)/\(max)"
        }
        return "\(count) participants"
    }
    
    private func statusBadge(_ status: String) -> some View {
        let color = colorForStatus(status)
        return Text(status.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }
    
    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "debate": return "bubble.left.and.bubble.right.fill"
        case "vocabulary quiz": return "character.book.closed.fill"
        default: return "flag.checkered.2.crossed"
        }
    }
    
    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "Live Now": return .green
        case "Upcoming": return .blue
        case "Registration Closed": return .orange
        case "Completed": return .secondary
        case "Cancelled": return .red
        default: return .gray
        }
    }
}
