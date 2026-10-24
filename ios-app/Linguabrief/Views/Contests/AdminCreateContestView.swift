import SwiftUI

/// Admin screen for creating and publishing new contests, or editing eligible existing contests.
public struct AdminCreateContestView: View {
    @ObservedObject var contestVM: ContestViewModel
    @Environment(\.dismiss) private var dismiss
    
    public var editingContest: Contest?
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var rules: String = ""
    @State private var selectedType: String = "Debate"
    @State private var selectedLanguage: String = "Spanish"
    @State private var selectedDifficulty: String = "B1"
    
    @State private var startDate: Date = Date().addingTimeInterval(3600)
    @State private var regDeadlineDate: Date = Date().addingTimeInterval(1800)
    @State private var endDate: Date = Date().addingTimeInterval(7200)
    
    @State private var hasCapacityLimit: Bool = true
    @State private var maxParticipantsCount: Int = 12
    
    @State private var selectedVisibility: String = "public"
    @State private var passcode: String = ""
    
    @State private var scoringCriteria: String = "Accuracy, Reasoning & Fluency"
    @State private var prizes: String = "Gold Badge & 500 Learning XP"
    
    @State private var questions: [ContestQuestion] = []
    @State private var newQuestionText: String = ""
    @State private var newOption1: String = ""
    @State private var newOption2: String = ""
    @State private var newOption3: String = ""
    @State private var newOption4: String = ""
    @State private var newCorrectIndex: Int = 0
    @State private var showAddQuestionSection: Bool = false
    
    @State private var formErrorMessage: String?
    
    private let contestTypes = ["Debate", "Vocabulary Quiz", "Language Challenge"]
    private let difficulties = ["All Levels", "A1", "A2", "B1", "B2", "C1", "C2"]
    
    public init(contestVM: ContestViewModel, editingContest: Contest? = nil) {
        self.contestVM = contestVM
        self.editingContest = editingContest
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                
                // Header Banner
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                                .foregroundColor(Constants.Colors.brandBurgundy)
                            Text("ADMIN CONTEST MANAGER")
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                        }
                        Text(editingContest != nil ? "Edit Contest Details" : "Create & Schedule Contest")
                            .font(.title3.bold())
                        Text("Configure activity parameters, scheduling, participant capacity, and scoring criteria.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // Visible Error Banner
                if let error = formErrorMessage ?? contestVM.errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Basic Information
                Section("Contest Overview") {
                    TextField("Contest Title (e.g. Spanish Climate Debate)", text: $title)
                        .font(.headline)
                    
                    Picker("Contest Type", selection: $selectedType) {
                        ForEach(contestTypes, id: \.self) { type in
                            HStack {
                                Image(systemName: iconForType(type))
                                Text(type)
                            }.tag(type)
                        }
                    }
                    .disabled(editingContest != nil) // Cannot change activity type on live/existing contest
                    
                    TextField("Brief Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Rules & Instructions", text: $rules, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Language & Difficulty
                Section("Language & Difficulty Calibration") {
                    Picker("Target Language", selection: $selectedLanguage) {
                        ForEach(Constants.targetLanguages) { lang in
                            Text("\(lang.flag) \(lang.name)").tag(lang.name)
                        }
                    }
                    
                    Picker("CEFR Difficulty", selection: $selectedDifficulty) {
                        ForEach(difficulties, id: \.self) { diff in
                            Text(diff).tag(diff)
                        }
                    }
                }
                
                // Schedule & Deadlines
                Section(header: Text("Schedule & Deadlines"), footer: Text("Registration deadline must precede the start time. End time must be after start time.")) {
                    DatePicker("Start Time", selection: $startDate)
                    DatePicker("Registration Cutoff", selection: $regDeadlineDate, in: ...startDate)
                    DatePicker("End Time", selection: $endDate, in: startDate...)
                }
                
                // Capacity & Visibility
                Section("Capacity & Access Control") {
                    Toggle("Limit Participant Capacity", isOn: $hasCapacityLimit)
                    
                    if hasCapacityLimit {
                        Stepper("Max Participants: \(maxParticipantsCount)", value: $maxParticipantsCount, in: 2...100)
                    }
                    
                    Picker("Visibility", selection: $selectedVisibility) {
                        Text("Public (Open to All)").tag("public")
                        Text("Invite-Only (Passcode Required)").tag("invite-only")
                    }
                    
                    if selectedVisibility == "invite-only" {
                        TextField("Passcode (e.g. DEBATE2026)", text: $passcode)
                            .font(.subheadline.monospaced())
                            .autocapitalization(.allCharacters)
                    }
                }
                
                // Scoring Criteria & Prizes
                Section("Scoring Criteria & Rewards") {
                    TextField("Scoring Criteria", text: $scoringCriteria)
                    TextField("Prizes / Awards", text: $prizes)
                }
                
                // Questions Builder (for Vocabulary Quiz & Language Challenge)
                if selectedType != "Debate" {
                    Section("Challenge Questions (\(questions.count))") {
                        ForEach(Array(questions.enumerated()), id: \.offset) { idx, q in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(idx + 1). \(q.questionText)")
                                    .font(.subheadline.bold())
                                Text("Options: \(q.options.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { indexSet in
                            questions.remove(atOffsets: indexSet)
                        }
                        
                        if showAddQuestionSection {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New Question")
                                    .font(.caption.bold())
                                    .foregroundColor(Constants.Colors.brandBurgundy)
                                
                                TextField("Question prompt", text: $newQuestionText)
                                    .font(.subheadline)
                                
                                TextField("Option 1", text: $newOption1)
                                TextField("Option 2", text: $newOption2)
                                TextField("Option 3", text: $newOption3)
                                TextField("Option 4", text: $newOption4)
                                
                                Picker("Correct Answer", selection: $newCorrectIndex) {
                                    Text("Option 1").tag(0)
                                    Text("Option 2").tag(1)
                                    Text("Option 3").tag(2)
                                    Text("Option 4").tag(3)
                                }
                                
                                Button("Add Question to Challenge") {
                                    guard !newQuestionText.isEmpty && !newOption1.isEmpty && !newOption2.isEmpty else { return }
                                    let options = [newOption1, newOption2, newOption3, newOption4].filter { !$0.isEmpty }
                                    let q = ContestQuestion(questionText: newQuestionText, options: options, correctOptionIndex: newCorrectIndex, points: 1)
                                    questions.append(q)
                                    newQuestionText = ""
                                    newOption1 = ""
                                    newOption2 = ""
                                    newOption3 = ""
                                    newOption4 = ""
                                    showAddQuestionSection = false
                                }
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                            }
                            .padding(.vertical, 6)
                        } else {
                            Button("+ Add Question") {
                                showAddQuestionSection = true
                            }
                            .font(.subheadline)
                            .foregroundColor(Constants.Colors.brandBurgundy)
                        }
                    }
                }
            }
            .navigationTitle(editingContest != nil ? "Edit Contest" : "Create Contest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveContest) {
                        if contestVM.isActionLoading {
                            ProgressView().tint(Constants.Colors.brandBurgundy)
                        } else {
                            Text(editingContest != nil ? "Save Changes" : "Publish Contest")
                                .bold()
                                .foregroundColor(Constants.Colors.brandBurgundy)
                        }
                    }
                    .disabled(contestVM.isActionLoading)
                }
            }
            .onAppear {
                populateFormForEditing()
            }
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "debate": return "bubble.left.and.bubble.right.fill"
        case "vocabulary quiz": return "character.book.closed.fill"
        default: return "flag.checkered.2.crossed"
        }
    }
    
    private func populateFormForEditing() {
        guard let contest = editingContest else { return }
        title = contest.title
        description = contest.description ?? ""
        rules = contest.rules ?? ""
        selectedType = contest.effectiveType
        selectedLanguage = contest.effectiveLanguage
        selectedDifficulty = contest.effectiveDifficulty
        
        if let s = contest.startTime, let date = parseDate(s) { startDate = date }
        if let r = contest.registrationDeadline, let date = parseDate(r) { regDeadlineDate = date }
        if let e = contest.endTime, let date = parseDate(e) { endDate = date }
        
        if let max = contest.maxParticipants, max > 0 {
            hasCapacityLimit = true
            maxParticipantsCount = max
        } else {
            hasCapacityLimit = false
        }
        
        selectedVisibility = contest.visibility ?? "public"
        passcode = contest.passcode ?? ""
        scoringCriteria = contest.scoringCriteria ?? ""
        prizes = contest.prizes ?? ""
        questions = contest.questions ?? []
    }
    
    private func parseDate(_ dateStr: String) -> Date? {
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoStandard = ISO8601DateFormatter()
        isoStandard.formatOptions = [.withInternetDateTime]
        return isoFractional.date(from: dateStr) ?? isoStandard.date(from: dateStr)
    }
    
    private func saveContest() {
        formErrorMessage = nil
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            formErrorMessage = "Please enter a contest title."
            return
        }
        
        guard endDate > startDate else {
            formErrorMessage = "End time must be after the start time."
            return
        }
        
        guard regDeadlineDate <= startDate else {
            formErrorMessage = "Registration deadline cannot be after start time."
            return
        }
        
        if selectedVisibility == "invite-only" && passcode.trimmingCharacters(in: .whitespaces).isEmpty {
            formErrorMessage = "Please provide a passcode for invite-only contests."
            return
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let startISO = formatter.string(from: startDate)
        let regISO = formatter.string(from: regDeadlineDate)
        let endISO = formatter.string(from: endDate)
        
        let maxLimit: Int? = hasCapacityLimit ? maxParticipantsCount : nil
        
        Task {
            if let contest = editingContest {
                let payload = EditContestRequest(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces),
                    rules: rules.trimmingCharacters(in: .whitespaces),
                    language: selectedLanguage,
                    difficulty: selectedDifficulty,
                    startTime: startISO,
                    registrationDeadline: regISO,
                    endTime: endISO,
                    maxParticipants: maxLimit,
                    scoringCriteria: scoringCriteria.trimmingCharacters(in: .whitespaces),
                    prizes: prizes.trimmingCharacters(in: .whitespaces)
                )
                let success = await contestVM.editContest(id: contest.id, payload: payload)
                if success { dismiss() }
            } else {
                let payload = CreateContestRequest(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces),
                    rules: rules.trimmingCharacters(in: .whitespaces),
                    type: selectedType,
                    language: selectedLanguage,
                    difficulty: selectedDifficulty,
                    startTime: startISO,
                    registrationDeadline: regISO,
                    endTime: endISO,
                    maxParticipants: maxLimit,
                    visibility: selectedVisibility,
                    passcode: selectedVisibility == "invite-only" ? passcode.trimmingCharacters(in: .whitespaces) : nil,
                    scoringCriteria: scoringCriteria.trimmingCharacters(in: .whitespaces),
                    prizes: prizes.trimmingCharacters(in: .whitespaces),
                    questions: questions.isEmpty ? nil : questions
                )
                let success = await contestVM.createContest(payload: payload)
                if success { dismiss() }
            }
        }
    }
}
