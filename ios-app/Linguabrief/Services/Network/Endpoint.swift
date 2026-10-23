import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Type-safe representation of Linguabrief backend endpoints
public struct Endpoint: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let queryItems: [URLQueryItem]?
    public let requiresAuth: Bool

    public init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.requiresAuth = requiresAuth
    }

    // MARK: - Auth Endpoints
    public static func signup() -> Endpoint {
        Endpoint(path: "/api/auth/signup", method: .post, requiresAuth: false)
    }

    public static func login() -> Endpoint {
        Endpoint(path: "/api/auth/login", method: .post, requiresAuth: false)
    }

    // MARK: - User Endpoints
    public static func getProfile() -> Endpoint {
        Endpoint(path: "/api/users/profile", method: .get, requiresAuth: true)
    }

    public static func updateProfile() -> Endpoint {
        Endpoint(path: "/api/users/profile", method: .put, requiresAuth: true)
    }

    // MARK: - Feed & Article Endpoints
    public static func feed(offset: Int = 0, limit: Int = 20, topic: String = "all", targetLang: String? = nil) -> Endpoint {
        var items = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "topic", value: topic)
        ]
        if let lang = targetLang, !lang.isEmpty {
            items.append(URLQueryItem(name: "targetLang", value: lang))
        }
        return Endpoint(path: "/api/feed", method: .get, queryItems: items, requiresAuth: false)
    }

    public static func batchSummary() -> Endpoint {
        Endpoint(path: "/api/feed/summary", method: .post, requiresAuth: false)
    }

    public static func extractArticle(url: String) -> Endpoint {
        let items = [URLQueryItem(name: "url", value: url)]
        return Endpoint(path: "/api/extract-article", method: .get, queryItems: items, requiresAuth: false)
    }

    public static func translate() -> Endpoint {
        Endpoint(path: "/api/translate", method: .post, requiresAuth: false)
    }

    public static func wordIntelligence() -> Endpoint {
        Endpoint(path: "/api/translate/word-intelligence", method: .post, requiresAuth: false)
    }


    // MARK: - Vocabulary & Decks Endpoints
    public static func savedWords() -> Endpoint {
        Endpoint(path: "/api/saved-words", method: .get, requiresAuth: true)
    }

    public static func saveWord() -> Endpoint {
        Endpoint(path: "/api/saved-words", method: .post, requiresAuth: true)
    }

    public static func deleteWord(id: String) -> Endpoint {
        Endpoint(path: "/api/saved-words/\(id)", method: .delete, requiresAuth: true)
    }

    public static func flashcardDecks() -> Endpoint {
        Endpoint(path: "/api/flashcard-decks", method: .get, requiresAuth: true)
    }

    public static func createFlashcardDeck() -> Endpoint {
        Endpoint(path: "/api/flashcard-decks", method: .post, requiresAuth: true)
    }

    public static func deleteFlashcardDeck(id: String) -> Endpoint {
        Endpoint(path: "/api/flashcard-decks/\(id)", method: .delete, requiresAuth: true)
    }

    // MARK: - Bookmarks Endpoints
    public static func bookmarks() -> Endpoint {
        Endpoint(path: "/api/bookmarks", method: .get, requiresAuth: true)
    }

    public static func addBookmark() -> Endpoint {
        Endpoint(path: "/api/bookmarks", method: .post, requiresAuth: true)
    }

    public static func removeBookmark(articleUrl: String) -> Endpoint {
        let items = [URLQueryItem(name: "articleUrl", value: articleUrl)]
        return Endpoint(path: "/api/bookmarks", method: .delete, queryItems: items, requiresAuth: true)
    }

    // MARK: - Comments Endpoints
    public static func comments(articleUrl: String) -> Endpoint {
        let items = [URLQueryItem(name: "articleUrl", value: articleUrl)]
        return Endpoint(path: "/api/comments", method: .get, queryItems: items, requiresAuth: false)
    }

    public static func postComment() -> Endpoint {
        Endpoint(path: "/api/comments", method: .post, requiresAuth: true)
    }

    public static func deleteComment(id: String) -> Endpoint {
        Endpoint(path: "/api/comments/\(id)", method: .delete, requiresAuth: true)
    }

    public static func userCommentsCount() -> Endpoint {
        Endpoint(path: "/api/comments/user-count", method: .get, requiresAuth: true)
    }

    // MARK: - Contests Endpoints
    public static func publicContests() -> Endpoint {
        Endpoint(path: "/api/contests/public", method: .get, requiresAuth: false)
    }

    public static func joinContestByPasscode() -> Endpoint {
        Endpoint(path: "/api/contests/join-passcode", method: .post, requiresAuth: true)
    }

    public static func submitContest() -> Endpoint {
        Endpoint(path: "/api/contests/submit", method: .post, requiresAuth: true)
    }

    public static func contestLeaderboard(contestId: String) -> Endpoint {
        Endpoint(path: "/api/contests/\(contestId)/leaderboard", method: .get, requiresAuth: false)
    }

    // MARK: - Debates Endpoints
    public static func debateRooms() -> Endpoint {
        Endpoint(path: "/api/debates", method: .get, requiresAuth: true)
    }

    public static func createDebateRoom() -> Endpoint {
        Endpoint(path: "/api/debates", method: .post, requiresAuth: true)
    }

    public static func getDebateRoom(id: String) -> Endpoint {
        Endpoint(path: "/api/debates/\(id)", method: .get, requiresAuth: true)
    }

    public static func joinDebateRoom(id: String) -> Endpoint {
        Endpoint(path: "/api/debates/\(id)/join", method: .post, requiresAuth: true)
    }

    public static func leaveDebateRoom(id: String) -> Endpoint {
        Endpoint(path: "/api/debates/\(id)/leave", method: .post, requiresAuth: true)
    }
}
