import Foundation

/// User model mirroring backend `models/user.js`
public struct User: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let username: String
    public let email: String
    public var targetLanguage: String?
    public var nativeLanguage: String?
    public var cefrLevel: String?
    public let role: String?
    public var profileCompleted: Bool?
    public var streak: Int?
    public let createdAt: Date?
    public let updatedAt: Date?

    public var isAdmin: Bool {
        role?.lowercased() == "admin"
    }

    public init(
        id: String,
        username: String,
        email: String,
        targetLanguage: String? = nil,
        nativeLanguage: String? = "English",
        cefrLevel: String? = nil,
        role: String? = "user",
        profileCompleted: Bool? = false,
        streak: Int? = 0,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.targetLanguage = targetLanguage
        self.nativeLanguage = nativeLanguage
        self.cefrLevel = cefrLevel
        self.role = role
        self.profileCompleted = profileCompleted
        self.streak = streak
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username, email, targetLanguage, nativeLanguage
        case cefrLevel, role, profileCompleted, streak
        case createdAt, updatedAt
    }

    private enum AltKeys: String, CodingKey {
        case id
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idVal = try? container.decode(String.self, forKey: .id) {
            self.id = idVal
        } else {
            let altContainer = try decoder.container(keyedBy: AltKeys.self)
            self.id = (try? altContainer.decode(String.self, forKey: .id)) ?? UUID().uuidString
        }

        self.username = (try? container.decode(String.self, forKey: .username)) ?? ""
        self.email = (try? container.decode(String.self, forKey: .email)) ?? ""
        self.targetLanguage = try? container.decodeIfPresent(String.self, forKey: .targetLanguage)
        self.nativeLanguage = try? container.decodeIfPresent(String.self, forKey: .nativeLanguage)
        self.cefrLevel = try? container.decodeIfPresent(String.self, forKey: .cefrLevel)
        self.role = try? container.decodeIfPresent(String.self, forKey: .role)
        self.profileCompleted = try? container.decodeIfPresent(Bool.self, forKey: .profileCompleted)
        self.streak = try? container.decodeIfPresent(Int.self, forKey: .streak)

        self.createdAt = Self.decodeDate(from: container, key: .createdAt)
        self.updatedAt = Self.decodeDate(from: container, key: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(targetLanguage, forKey: .targetLanguage)
        try container.encodeIfPresent(nativeLanguage, forKey: .nativeLanguage)
        try container.encodeIfPresent(cefrLevel, forKey: .cefrLevel)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(profileCompleted, forKey: .profileCompleted)
        try container.encodeIfPresent(streak, forKey: .streak)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Date? {
        if let dateObj = try? container.decodeIfPresent(Date.self, forKey: key) {
            return dateObj
        }
        if let dateStr = try? container.decodeIfPresent(String.self, forKey: key) {
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let isoStandard = ISO8601DateFormatter()
            isoStandard.formatOptions = [.withInternetDateTime]
            return isoFractional.date(from: dateStr) ?? isoStandard.date(from: dateStr)
        }
        if let timestamp = try? container.decodeIfPresent(Double.self, forKey: key) {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }
}

/// Authentication Response returned from `/api/auth/signup` and `/api/auth/login`
public struct AuthResponse: Codable, Sendable {
    public let id: String
    public let username: String
    public let email: String
    public let role: String?
    public let nativeLanguage: String?
    public let targetLanguage: String?
    public let cefrLevel: String?
    public let profileCompleted: Bool?
    public let streak: Int?
    public let token: String

    public init(
        id: String,
        username: String,
        email: String,
        role: String? = "user",
        nativeLanguage: String? = "English",
        targetLanguage: String? = nil,
        cefrLevel: String? = nil,
        profileCompleted: Bool? = false,
        streak: Int? = 0,
        token: String
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.role = role
        self.nativeLanguage = nativeLanguage
        self.targetLanguage = targetLanguage
        self.cefrLevel = cefrLevel
        self.profileCompleted = profileCompleted
        self.streak = streak
        self.token = token
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username, email, role, nativeLanguage, targetLanguage
        case cefrLevel, profileCompleted, streak, token
    }

    private enum AltKeys: String, CodingKey {
        case id
        case accessToken
        case authToken
        case jwt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let altContainer = try decoder.container(keyedBy: AltKeys.self)

        // Decode id from either _id or id
        if let idVal = try? container.decode(String.self, forKey: .id) {
            self.id = idVal
        } else if let idVal = try? altContainer.decode(String.self, forKey: .id) {
            self.id = idVal
        } else {
            self.id = UUID().uuidString
        }

        self.username = (try? container.decode(String.self, forKey: .username)) ?? ""
        self.email = (try? container.decode(String.self, forKey: .email)) ?? ""
        self.role = try? container.decodeIfPresent(String.self, forKey: .role)
        self.nativeLanguage = try? container.decodeIfPresent(String.self, forKey: .nativeLanguage)
        self.targetLanguage = try? container.decodeIfPresent(String.self, forKey: .targetLanguage)
        self.cefrLevel = try? container.decodeIfPresent(String.self, forKey: .cefrLevel)
        self.profileCompleted = try? container.decodeIfPresent(Bool.self, forKey: .profileCompleted)
        self.streak = try? container.decodeIfPresent(Int.self, forKey: .streak)

        // Decode token from 'token', 'accessToken', 'authToken', or 'jwt'
        if let tVal = try? container.decode(String.self, forKey: .token), !tVal.isEmpty {
            self.token = tVal
        } else if let tVal = try? altContainer.decode(String.self, forKey: .accessToken), !tVal.isEmpty {
            self.token = tVal
        } else if let tVal = try? altContainer.decode(String.self, forKey: .authToken), !tVal.isEmpty {
            self.token = tVal
        } else if let tVal = try? altContainer.decode(String.self, forKey: .jwt), !tVal.isEmpty {
            self.token = tVal
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.token,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No authentication token found in response payload")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(nativeLanguage, forKey: .nativeLanguage)
        try container.encodeIfPresent(targetLanguage, forKey: .targetLanguage)
        try container.encodeIfPresent(cefrLevel, forKey: .cefrLevel)
        try container.encodeIfPresent(profileCompleted, forKey: .profileCompleted)
        try container.encodeIfPresent(streak, forKey: .streak)
        try container.encode(token, forKey: .token)
    }
    
    public func toUser() -> User {
        User(
            id: id,
            username: username,
            email: email,
            targetLanguage: targetLanguage,
            nativeLanguage: nativeLanguage ?? "English",
            cefrLevel: cefrLevel,
            role: role ?? "user",
            profileCompleted: profileCompleted ?? false,
            streak: streak ?? 0
        )
    }
}

/// Request body for profile updates (`PUT /api/users/profile`)
/// Native language is fixed to English on the client side.
public struct ProfileUpdateRequest: Codable, Sendable {
    public let targetLanguage: String?
    public let cefrLevel: String?
    public let nativeLanguage: String?
    public let profileCompleted: Bool?

    public init(targetLanguage: String?, cefrLevel: String?, nativeLanguage: String? = "English", profileCompleted: Bool? = true) {
        self.targetLanguage = targetLanguage
        self.cefrLevel = cefrLevel
        self.nativeLanguage = nativeLanguage ?? "English"
        self.profileCompleted = profileCompleted
    }
}
