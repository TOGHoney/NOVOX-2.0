import Foundation

/// News Article entity mirroring backend `models/Article.js`
public struct Article: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let description: String?
    public let content: String?
    public let source: String?
    public let url: String
    public let imageUrl: String?
    public let publishedAt: String?
    public let topic: String?
    public var aiSummary: String?
    public let fetchedAt: String?
    public let originalTitle: String?
    public let originalDescription: String?

    public init(
        id: String,
        title: String,
        description: String? = nil,
        content: String? = nil,
        source: String? = nil,
        url: String,
        imageUrl: String? = nil,
        publishedAt: String? = nil,
        topic: String? = nil,
        aiSummary: String? = nil,
        fetchedAt: String? = nil,
        originalTitle: String? = nil,
        originalDescription: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.content = content
        self.source = source
        self.url = url
        self.imageUrl = imageUrl
        self.publishedAt = publishedAt
        self.topic = topic
        self.aiSummary = aiSummary
        self.fetchedAt = fetchedAt
        self.originalTitle = originalTitle
        self.originalDescription = originalDescription
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, content, source, url
        case imageUrl, publishedAt, topic, aiSummary, fetchedAt
        case originalTitle, originalDescription
    }
}

/// Paginated Feed Response returned from `GET /api/feed`
public struct FeedResponse: Codable, Sendable {
    public let articles: [Article]
    public let total: Int
    public let hasMore: Bool
}

/// Full scraped text returned from `GET /api/extract-article?url=...`
public struct ExtractedArticle: Codable, Sendable {
    public let title: String
    public let content: String
    public let byline: String?
    public let siteName: String?
}

/// Request payload for `POST /api/feed/summary`
public struct BatchSummaryRequest: Codable, Sendable {
    public let articleIds: [String]
    
    public init(articleIds: [String]) {
        self.articleIds = articleIds
    }
}

/// Response payload for `POST /api/feed/summary`
public struct BatchSummaryResponse: Codable, Sendable {
    public let articles: [Article]
}

/// Request payload for `POST /api/translate`
public struct TranslationRequest: Codable, Sendable {
    public let texts: [String]
    public let target: String
    public let source: String
    
    public init(texts: [String], target: String, source: String = "auto") {
        self.texts = texts
        self.target = target
        self.source = source
    }
}

/// Response payload for `POST /api/translate`
public struct TranslationResponse: Codable, Sendable {
    public let translations: [String]
    public let serviceUrl: String?
}
