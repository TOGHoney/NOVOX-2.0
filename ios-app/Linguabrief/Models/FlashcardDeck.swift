import Foundation

/// Flashcard Deck entity mirroring backend `models/FlashcardDeck.js`
public struct FlashcardDeck: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let deck: [SavedWord]
    public let wordCount: Int
    public let createdAt: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        deck: [SavedWord] = [],
        wordCount: Int = 0,
        createdAt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.deck = deck
        self.wordCount = wordCount
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, deck, wordCount, createdAt
    }
}

/// Request body for `POST /api/flashcard-decks`
public struct FlashcardDeckCreateRequest: Codable, Sendable {
    public let title: String
    public let deck: [SavedWord]
    public let wordCount: Int

    public init(title: String, deck: [SavedWord]) {
        self.title = title
        self.deck = deck
        self.wordCount = deck.count
    }
}

/// Generated interactive multiple choice question
public struct QuizQuestion: Identifiable, Sendable, Hashable {
    public var id: String { word }
    public let word: String
    public let correctAnswer: String
    public let contextSentence: String
    public let options: [String]
    
    public init(word: String, correctAnswer: String, contextSentence: String, options: [String]) {
        self.word = word
        self.correctAnswer = correctAnswer
        self.contextSentence = contextSentence
        self.options = options
    }
}
