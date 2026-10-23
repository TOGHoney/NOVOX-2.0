import Foundation

/// Bookmark snapshot of an article mirroring backend `models/Bookmark.js`
public struct BookmarkArticleSnapshot: Codable, Sendable, Hashable {
    public let title: String?
    public let description: String?
    public let content: String?
    public let imageUrl: String?
    public let url: String?
    public let source: String?
    public let publishedAt: String?
    public let category: String?
    public let aiSummary: String?

    public init(
        title: String? = "",
        description: String? = "",
        content: String? = "",
        imageUrl: String? = "",
        url: String? = "",
        source: String? = "",
        publishedAt: String? = "",
        category: String? = "",
        aiSummary: String? = nil
    ) {
        self.title = title
        self.description = description
        self.content = content
        self.imageUrl = imageUrl
        self.url = url
        self.source = source
        self.publishedAt = publishedAt
        self.category = category
        self.aiSummary = aiSummary
    }
}

/// Bookmark document
public struct Bookmark: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let user: String?
    public let articleUrl: String
    public let article: BookmarkArticleSnapshot?
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, articleUrl, article, createdAt
    }
}

/// Request payload for `POST /api/bookmarks`
public struct BookmarkCreateRequest: Codable, Sendable {
    public let articleUrl: String
    public let article: BookmarkArticleSnapshot

    public init(articleUrl: String, article: BookmarkArticleSnapshot) {
        self.articleUrl = articleUrl
        self.article = article
    }
}
