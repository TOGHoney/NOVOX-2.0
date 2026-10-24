import Foundation

/// Contest Question entity
public struct ContestQuestion: Codable, Identifiable, Sendable, Hashable {
    public var id: String { questionText }
    public let questionText: String
    public let options: [String]
    public let correctOptionIndex: Int?
    public let points: Int?

    public init(questionText: String, options: [String], correctOptionIndex: Int? = nil, points: Int? = 1) {
        self.questionText = questionText
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.points = points
    }
}

/// Reference to linked debate room
public struct LinkedDebateRoomRef: Codable, Sendable, Hashable {
    public let id: String
    public let status: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case status
    }
}

/// Official Contest model mirroring backend `models/Contest.js`
public struct Contest: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let description: String?
    public let rules: String?
    public let type: String?
    public let language: String?
    public let difficulty: String?
    
    public let startTime: String?
    public let endTime: String?
    public let registrationDeadline: String?
    public let durationMinutes: Int?
    
    public let maxParticipants: Int?
    public var participantCount: Int?
    public let isPublic: Bool?
    public let visibility: String?
    public let passcode: String?
    
    public let scoringCriteria: String?
    public let prizes: String?
    public let status: String?
    public let computedStatus: String?
    public let isRegistrationClosed: Bool?
    public let isFull: Bool?
    
    public var isRegistered: Bool?
    public var participationStatus: String?
    
    public let linkedDebateRoom: LinkedDebateRoomRef?
    public let questions: [ContestQuestion]?
    public var hasAttempted: Bool?

    public init(
        id: String,
        title: String,
        description: String? = nil,
        rules: String? = nil,
        type: String? = "Vocabulary Quiz",
        language: String? = "Spanish",
        difficulty: String? = "All Levels",
        startTime: String? = nil,
        endTime: String? = nil,
        registrationDeadline: String? = nil,
        durationMinutes: Int? = nil,
        maxParticipants: Int? = nil,
        participantCount: Int? = 0,
        isPublic: Bool? = true,
        visibility: String? = "public",
        passcode: String? = nil,
        scoringCriteria: String? = nil,
        prizes: String? = nil,
        status: String? = "upcoming",
        computedStatus: String? = "upcoming",
        isRegistrationClosed: Bool? = false,
        isFull: Bool? = false,
        isRegistered: Bool? = false,
        participationStatus: String? = nil,
        linkedDebateRoom: LinkedDebateRoomRef? = nil,
        questions: [ContestQuestion]? = nil,
        hasAttempted: Bool? = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.rules = rules
        self.type = type
        self.language = language
        self.difficulty = difficulty
        self.startTime = startTime
        self.endTime = endTime
        self.registrationDeadline = registrationDeadline
        self.durationMinutes = durationMinutes
        self.maxParticipants = maxParticipants
        self.participantCount = participantCount
        self.isPublic = isPublic
        self.visibility = visibility
        self.passcode = passcode
        self.scoringCriteria = scoringCriteria
        self.prizes = prizes
        self.status = status
        self.computedStatus = computedStatus
        self.isRegistrationClosed = isRegistrationClosed
        self.isFull = isFull
        self.isRegistered = isRegistered
        self.participationStatus = participationStatus
        self.linkedDebateRoom = linkedDebateRoom
        self.questions = questions
        self.hasAttempted = hasAttempted
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, rules, type, language, difficulty
        case startTime, endTime, registrationDeadline, durationMinutes
        case maxParticipants, participantCount, isPublic, visibility, passcode
        case scoringCriteria, prizes, status, computedStatus
        case isRegistrationClosed, isFull, isRegistered, participationStatus
        case linkedDebateRoom, questions, hasAttempted
    }
    
    // UI Helpers
    public var activeStatus: String {
        if status == "cancelled" || computedStatus == "cancelled" { return "Cancelled" }
        if computedStatus == "completed" { return "Completed" }
        if computedStatus == "live" { return "Live Now" }
        if isRegistrationClosed == true { return "Registration Closed" }
        return "Upcoming"
    }
    
    public var effectiveType: String {
        type ?? "Vocabulary Quiz"
    }
    
    public var effectiveLanguage: String {
        language ?? "Spanish"
    }
    
    public var effectiveDifficulty: String {
        difficulty ?? "All Levels"
    }
    
    public var isDebateContest: Bool {
        effectiveType.lowercased() == "debate"
    }
    
    public var isQuizContest: Bool {
        effectiveType.lowercased() == "vocabulary quiz" || effectiveType.lowercased() == "language challenge"
    }
    
    public var canJoin: Bool {
        isRegistered != true &&
        isFull != true &&
        isRegistrationClosed != true &&
        activeStatus != "Cancelled" &&
        activeStatus != "Completed"
    }
    
    public var canLeave: Bool {
        isRegistered == true && activeStatus == "Upcoming"
    }
    
    public var canEnterActivity: Bool {
        isRegistered == true && (activeStatus == "Live Now" || activeStatus == "Upcoming")
    }
}

/// Request body for creating contests (Admin)
public struct CreateContestRequest: Codable, Sendable {
    public let title: String
    public let description: String?
    public let rules: String?
    public let type: String
    public let language: String
    public let difficulty: String
    public let startTime: String
    public let registrationDeadline: String
    public let endTime: String
    public let maxParticipants: Int?
    public let visibility: String
    public let passcode: String?
    public let scoringCriteria: String?
    public let prizes: String?
    public let questions: [ContestQuestion]?

    public init(
        title: String,
        description: String? = nil,
        rules: String? = nil,
        type: String,
        language: String,
        difficulty: String,
        startTime: String,
        registrationDeadline: String,
        endTime: String,
        maxParticipants: Int? = nil,
        visibility: String = "public",
        passcode: String? = nil,
        scoringCriteria: String? = nil,
        prizes: String? = nil,
        questions: [ContestQuestion]? = nil
    ) {
        self.title = title
        self.description = description
        self.rules = rules
        self.type = type
        self.language = language
        self.difficulty = difficulty
        self.startTime = startTime
        self.registrationDeadline = registrationDeadline
        self.endTime = endTime
        self.maxParticipants = maxParticipants
        self.visibility = visibility
        self.passcode = passcode
        self.scoringCriteria = scoringCriteria
        self.prizes = prizes
        self.questions = questions
    }
}

/// Request body for updating contests (Admin)
public struct EditContestRequest: Codable, Sendable {
    public let title: String?
    public let description: String?
    public let rules: String?
    public let language: String?
    public let difficulty: String?
    public let startTime: String?
    public let registrationDeadline: String?
    public let endTime: String?
    public let maxParticipants: Int?
    public let scoringCriteria: String?
    public let prizes: String?

    public init(
        title: String? = nil,
        description: String? = nil,
        rules: String? = nil,
        language: String? = nil,
        difficulty: String? = nil,
        startTime: String? = nil,
        registrationDeadline: String? = nil,
        endTime: String? = nil,
        maxParticipants: Int? = nil,
        scoringCriteria: String? = nil,
        prizes: String? = nil
    ) {
        self.title = title
        self.description = description
        self.rules = rules
        self.language = language
        self.difficulty = difficulty
        self.startTime = startTime
        self.registrationDeadline = registrationDeadline
        self.endTime = endTime
        self.maxParticipants = maxParticipants
        self.scoringCriteria = scoringCriteria
        self.prizes = prizes
    }
}

/// Participant user entity
public struct ParticipantUserInfo: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let username: String
    public let email: String?
    public let targetLanguage: String?
    public let cefrLevel: String?
    public let streak: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username, email, targetLanguage, cefrLevel, streak
    }
}

/// Participant entry in admin roster
public struct ContestParticipantEntry: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let user: ParticipantUserInfo?
    public let status: String
    public let joinedAt: String?
    public let score: Int?
    public let timeTakenSeconds: Int?
}

/// Admin participants response
public struct ContestParticipantsResponse: Codable, Sendable {
    public let contestId: String
    public let contestTitle: String
    public let totalCount: Int
    public let participants: [ContestParticipantEntry]
}

/// Response returned from joining a contest
public struct JoinContestResponse: Codable, Sendable {
    public let message: String
    public let contest: Contest?
}

/// Generic simple response with message
public struct SimpleMessageResponse: Codable, Sendable {
    public let message: String
}

/// Request body for `POST /api/contests/join-passcode`
public struct JoinPasscodeRequest: Codable, Sendable {
    public let passcode: String

    public init(passcode: String) {
        self.passcode = passcode
    }
}

/// Request body for `POST /api/contests/submit`
public struct ContestSubmissionRequest: Codable, Sendable {
    public let contestId: String
    public let answers: [String: Int]
    public let timeTakenSeconds: Int

    public init(contestId: String, answers: [Int: Int], timeTakenSeconds: Int) {
        self.contestId = contestId
        var mapped: [String: Int] = [:]
        for (k, v) in answers {
            mapped[String(k)] = v
        }
        self.answers = mapped
        self.timeTakenSeconds = timeTakenSeconds
    }
}

/// Response returned from `POST /api/contests/submit`
public struct ContestSubmissionResponse: Codable, Sendable {
    public let message: String
    public let score: Int
}

/// Contest Leaderboard participant user
public struct LeaderboardUser: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let username: String
    public let email: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username, email
    }
}

/// Ranked submission entry returned by `GET /api/contests/:id/leaderboard`
public struct LeaderboardEntry: Codable, Identifiable, Sendable, Hashable {
    public var id: String { "\(user.id)_\(timeTakenSeconds)_\(score)" }
    public let user: LeaderboardUser
    public let score: Int
    public let timeTakenSeconds: Int
    public let submittedAt: String?

    enum CodingKeys: String, CodingKey {
        case user, score, timeTakenSeconds, submittedAt
    }
}
