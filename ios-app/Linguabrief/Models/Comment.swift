import Foundation

/// Threaded Comment entity returned by backend `controllers/commentController.js`
public struct Comment: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let articleUrl: String
    public let author: String
    public let userId: String?
    public let text: String
    public let isReply: Bool?
    public let parent: String?
    public let createdAt: String?
    public let updatedAt: String?

    public init(
        id: String,
        articleUrl: String,
        author: String,
        userId: String? = nil,
        text: String,
        isReply: Bool? = false,
        parent: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.articleUrl = articleUrl
        self.author = author
        self.userId = userId
        self.text = text
        self.isReply = isReply
        self.parent = parent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Request body for `POST /api/comments`
public struct CommentCreateRequest: Codable, Sendable {
    public let articleUrl: String
    public let text: String
    public let parentId: String?

    public init(articleUrl: String, text: String, parentId: String? = nil) {
        self.articleUrl = articleUrl
        self.text = text
        self.parentId = parentId
    }
}

/// Response from `GET /api/comments/user-count`
public struct CommentUserCountResponse: Codable, Sendable {
    public let count: Int
}
