import SwiftUI

/// Dedicated detail view for a contest, displaying full rules, schedule, capacity,
/// participant status, activity launchers (Debate or Quiz), and admin management controls.
public struct ContestDetailView: View {
    @ObservedObject var contestVM: ContestViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    let contest: Contest
    
    @StateObject private var debatesVM = DebatesViewModel()
    @State private var showLeaveConfirmation: Bool = false
    @State private var showCancelConfirmation: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var showParticipantsSheet: Bool = false
    @State private var showLeaderboardSheet: Bool = false
    
    public init(contestVM: ContestViewModel, contest: Contest) {
        self.contestVM = contestVM
        self.contest = contest
    }
    
    // Live reactive instance
    private var currentContest: Contest {
        contestVM.contests.first(where: { $0.id == contest.id })
            ?? contestVM.myContests.first(where: { $0.id == contest.id })
            ?? contest
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                typeBadge(currentContest.effectiveType)
                                difficultyBadge(currentContest.effectiveDifficulty)
                            }
                            
                            Text(currentContest.title)
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        statusBadge(currentContest.activeStatus)
                    }
                    
                    if let desc = currentContest.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    
                    Divider().padding(.vertical, 4)
                    
                    // Quick Metadata Grid
                    HStack(spacing: 20) {
                        metadataPill(
                            icon: "globe",
                            title: "Language",
                            value: currentContest.effectiveLanguage
                        )
                        
                        metadataPill(
                            icon: "person.2.fill",
                            title: "Participants",
                            value: capacityString()
                        )
                        
                        metadataPill(
                            icon: "clock.fill",
                            title: "Duration",
                            value: durationString()
                        )
                    }
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)
                
                // Action Banner / Participation State
                actionBanner
                    .padding(.horizontal)
                
                // Schedule Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Schedule & Deadlines")
                        .font(.headline)
                    
                    VStack(spacing: 10) {
                        scheduleRow(
                            icon: "calendar.badge.clock",
                            title: "Start Time",
                            dateStr: currentContest.startTime,
                            color: .blue
                        )
                        
                        scheduleRow(
                            icon: "hourglass",
                            title: "Registration Cutoff",
                            dateStr: currentContest.registrationDeadline ?? currentContest.startTime,
                            color: .orange
                        )
                        
                        scheduleRow(
                            icon: "flag.checkered",
                            title: "End Time",
                            dateStr: currentContest.endTime,
                            color: .purple
                        )
                    }
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)
                
                // Rules & Instructions
                if let rules = currentContest.rules, !rules.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Contest Rules & Conduct")
                            .font(.headline)
                        
                        Text(rules)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal)
                }
                
                // Scoring & Rewards
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scoring Criteria & Awards")
                        .font(.headline)
                    
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundColor(Constants.Colors.brandBurgundy)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Evaluation Standard")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Text(currentContest.scoringCriteria ?? "Accuracy & Speed")
                                .font(.subheadline)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Awards & Prizes")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Text(currentContest.prizes ?? "Ranked Leaderboard Recognition")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)
                
                // Admin Controls (Only if user has admin role)
                if authVM.isAdmin {
                    adminControlsSection
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 30)
            }
            .padding(.vertical)
        }
        .navigationTitle("Contest Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showLeaderboardSheet = true }) {
                    Label("Rankings", systemImage: "trophy")
                        .font(.subheadline)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AdminCreateContestView(contestVM: contestVM, editingContest: currentContest)
        }
        .sheet(isPresented: $showParticipantsSheet) {
            AdminContestParticipantsView(contestVM: contestVM, contest: currentContest)
        }
        .sheet(isPresented: $showLeaderboardSheet) {
            ContestLeaderboardView(contestVM: contestVM)
                .task {
                    await contestVM.loadLeaderboard(for: currentContest.id)
                }
        }
        .sheet(item: $contestVM.activeContest) { contest in
            ContestRunnerView(contestVM: contestVM, contest: contest)
        }
        .alert("Leave Contest?", isPresented: $showLeaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Leave Contest", role: .destructive) {
                Task {
                    _ = await contestVM.leaveContest(currentContest)
                }
            }
        } message: {
            Text("Are you sure you want to withdraw your registration for this contest?")
        }
        .alert("Cancel Contest?", isPresented: $showCancelConfirmation) {
            Button("No", role: .cancel) {}
            Button("Yes, Cancel Contest", role: .destructive) {
                Task {
                    _ = await contestVM.cancelContest(id: currentContest.id)
                }
            }
        } message: {
            Text("This action cannot be undone. All registered participants will be notified and the contest will be marked cancelled.")
        }
    }
    
    // MARK: - Action Banner
    
    @ViewBuilder
    private var actionBanner: some View {
        VStack(spacing: 12) {
            if currentContest.isRegistered == true {
                // User is already registered
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You are registered!")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text(currentContest.activeStatus == "Live Now" ? "Activity is open now." : "Get ready when the countdown finishes.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                HStack(spacing: 12) {
                    if currentContest.canEnterActivity {
                        Button(action: {
                            if currentContest.isDebateContest, let debateRoomId = currentContest.linkedDebateRoom?.id {
                                Task {
                                    _ = await debatesVM.joinRoom(id: debateRoomId)
                                    // For debate, we still use the sheet binding
                                    // For quiz, startContest sets activeContest which triggers sheet
                                }
                            } else {
                                Task {
                                    await contestVM.startContest(currentContest)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: currentContest.isDebateContest ? "bubble.left.and.bubble.right.fill" : "play.fill")
                                Text(currentContest.isDebateContest ? "Enter Debate Floor" : "Start Challenge")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Constants.Colors.brandBurgundy)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    if currentContest.canLeave {
                        Button(action: { showLeaveConfirmation = true }) {
                            Text("Leave")
                                .font(.subheadline.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
            } else {
                // User is NOT registered
                if currentContest.canJoin {
                    Button(action: {
                        Task {
                            _ = await contestVM.joinContest(currentContest)
                        }
                    }) {
                        if contestVM.isActionLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Constants.Colors.brandBurgundy)
                                .cornerRadius(10)
                        } else {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Join Contest")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Constants.Colors.brandBurgundy)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .disabled(contestVM.isActionLoading)
                } else {
                    // Registration unavailable
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        Text(unavailableReason())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Admin Controls Section
    
    private var adminControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape.2.fill")
                    .foregroundColor(Constants.Colors.brandBurgundy)
                Text("ADMIN CONTROLS")
                    .font(.caption.bold())
                    .foregroundColor(Constants.Colors.brandBurgundy)
            }
            
            HStack(spacing: 10) {
                Button(action: { showEditSheet = true }) {
                    Label("Edit Contest", systemImage: "pencil")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                
                Button(action: { showParticipantsSheet = true }) {
                    Label("Participants", systemImage: "person.2")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
            
            if currentContest.activeStatus != "Cancelled" && currentContest.activeStatus != "Completed" {
                Button(action: { showCancelConfirmation = true }) {
                    Label("Cancel This Contest", systemImage: "xmark.circle")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .cardStyle(backgroundColor: Constants.Colors.brandBurgundy.opacity(0.04))
    }
    
    // MARK: - Activity Views
    
    @ViewBuilder
    private func launchActivityView() -> some View {
        if currentContest.isDebateContest {
            DebateRoomLiveView(debatesVM: debatesVM)
        }
    }
    
    // MARK: - Helper UI Builders
    
    private func capacityString() -> String {
        let count = currentContest.participantCount ?? 0
        if let max = currentContest.maxParticipants, max > 0 {
            return "\(count)/\(max)"
        }
        return "\(count) joined"
    }
    
    private func durationString() -> String {
        if let d = currentContest.durationMinutes, d > 0 {
            return "\(d) min"
        }
        return "Standard"
    }
    
    private func unavailableReason() -> String {
        if currentContest.activeStatus == "Cancelled" { return "Contest has been cancelled" }
        if currentContest.activeStatus == "Completed" { return "Contest has concluded" }
        if currentContest.isFull == true { return "Contest capacity is full" }
        if currentContest.isRegistrationClosed == true { return "Registration closed" }
        return "Registration not available"
    }
    
    private func typeBadge(_ type: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconForType(type))
            Text(type)
        }
        .font(.caption2.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Constants.Colors.brandBurgundy.opacity(0.1))
        .foregroundColor(Constants.Colors.brandBurgundy)
        .cornerRadius(6)
    }
    
    private func difficultyBadge(_ diff: String) -> some View {
        Text(diff)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(6)
    }
    
    private func statusBadge(_ status: String) -> some View {
        let color = colorForStatus(status)
        return Text(status.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
    
    private func metadataPill(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
    }
    
    private func scheduleRow(icon: String, title: String, dateStr: String?, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: icon).foregroundColor(color).font(.subheadline))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(formatDate(dateStr))
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }
    
    private func formatDate(_ dateStr: String?) -> String {
        guard let s = dateStr else { return "TBD" }
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoStandard = ISO8601DateFormatter()
        isoStandard.formatOptions = [.withInternetDateTime]
        guard let date = isoFractional.date(from: s) ?? isoStandard.date(from: s) else {
            return s
        }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
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
