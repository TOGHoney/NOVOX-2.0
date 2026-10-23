import Foundation

/// Participant in a debate room
public struct DebateParticipant: Codable, Identifiable, Sendable, Hashable {
    public var id: String { userId }
    public let userId: String
    public let username: String
    public var speakingMs: Int?
    public let isHost: Bool?

    public init(userId: String, username: String, speakingMs: Int? = 0, isHost: Bool? = false) {
        self.userId = userId
        self.username = username
        self.speakingMs = speakingMs
        self.isHost = isHost
    }
}

/// Active speaking floor state
public struct DebateFloor: Codable, Sendable, Hashable {
    public let userId: String?
    public let grantedAt: String?
}

/// Debate Room entity mirroring backend `models/DebateRoom.js`
public struct DebateRoom: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let topic: String
    public let prompt: String?
    public let language: String?
    public let level: String?
    public let maxParticipants: Int?
    public let status: String?
    public let host: String?
    public let hostId: String?
    public let isHost: Bool?
    public let participantCount: Int?
    public let isParticipant: Bool?
    public var participants: [DebateParticipant]?
    public var floor: DebateFloor?
    public let createdAt: String?

    public init(
        id: String,
        topic: String,
        prompt: String? = nil,
        language: String? = "English",
        level: String? = "A1",
        maxParticipants: Int? = 6,
        status: String? = "open",
        host: String? = "Host",
        hostId: String? = nil,
        isHost: Bool? = false,
        participantCount: Int? = 1,
        isParticipant: Bool? = false,
        participants: [DebateParticipant]? = nil,
        floor: DebateFloor? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.topic = topic
        self.prompt = prompt
        self.language = language
        self.level = level
        self.maxParticipants = maxParticipants
        self.status = status
        self.host = host
        self.hostId = hostId
        self.isHost = isHost
        self.participantCount = participantCount
        self.isParticipant = isParticipant
        self.participants = participants
        self.floor = floor
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case topic, prompt, language, level, maxParticipants
        case status, host, hostId, isHost, participantCount
        case isParticipant, participants, floor, createdAt
    }
}

/// Request body for `POST /api/debates`
public struct DebateRoomCreateRequest: Codable, Sendable {
    public let topic: String
    public let prompt: String?
    public let language: String
    public let level: String
    public let maxParticipants: Int

    public init(
        topic: String,
        prompt: String? = nil,
        language: String = "English",
        level: String = "A1",
        maxParticipants: Int = 6
    ) {
        self.topic = topic
        self.prompt = prompt
        self.language = language
        self.level = level
        self.maxParticipants = maxParticipants
    }
}
