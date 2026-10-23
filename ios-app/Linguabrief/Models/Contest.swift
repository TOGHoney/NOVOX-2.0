import Foundation

/// Contest Question entity
public struct ContestQuestion: Codable, Identifiable, Sendable, Hashable {
    public var id: String { questionText }
    public let questionText: String
    public let options: [String]
    public let points: Int?

    public init(questionText: String, options: [String], points: Int? = 1) {
        self.questionText = questionText
        self.options = options
        self.points = points
    }
}

/// Official Contest model mirroring backend `models/Contest.js`
public struct Contest: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let description: String?
    public let isPublic: Bool?
    public let passcode: String?
    public let startTime: String?
    public let endTime: String?
    public let questions: [ContestQuestion]?
    public var hasAttempted: Bool?

    public init(
        id: String,
        title: String,
        description: String? = nil,
        isPublic: Bool? = true,
        passcode: String? = nil,
        startTime: String? = nil,
        endTime: String? = nil,
        questions: [ContestQuestion]? = nil,
        hasAttempted: Bool? = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isPublic = isPublic
        self.passcode = passcode
        self.startTime = startTime
        self.endTime = endTime
        self.questions = questions
        self.hasAttempted = hasAttempted
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, isPublic, passcode, startTime, endTime, questions, hasAttempted
    }
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
    public let answers: [String: Int] // index string -> selected option index
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
