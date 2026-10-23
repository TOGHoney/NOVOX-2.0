import Foundation

/// Saved Vocabulary Word entity mirroring backend `models/SavedWord.js`
public struct SavedWord: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let userId: String?
    public let word: String
    public let translation: String?
    public let contextSentence: String?
    public let definition: String?
    public let phonetic: String?
    public let cefr: String?
    public var masteryScore: Int?
    public let createdAt: String?
    public let updatedAt: String?

    public init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        word: String,
        translation: String? = nil,
        contextSentence: String? = nil,
        definition: String? = nil,
        phonetic: String? = nil,
        cefr: String? = "B1",
        masteryScore: Int? = 0,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.word = word
        self.translation = translation
        self.contextSentence = contextSentence
        self.definition = definition
        self.phonetic = phonetic
        self.cefr = cefr
        self.masteryScore = masteryScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, word, translation, contextSentence
        case definition, phonetic, cefr, masteryScore
        case createdAt, updatedAt
    }
}

/// Request payload for `POST /api/saved-words`
public struct SavedWordCreateRequest: Codable, Sendable {
    public let word: String
    public let translation: String?
    public let contextSentence: String?
    public let definition: String?
    public let phonetic: String?
    public let cefr: String?

    public init(
        word: String,
        translation: String? = nil,
        contextSentence: String? = nil,
        definition: String? = nil,
        phonetic: String? = nil,
        cefr: String? = "B1"
    ) {
        self.word = word
        self.translation = translation
        self.contextSentence = contextSentence
        self.definition = definition
        self.phonetic = phonetic
        self.cefr = cefr
    }
}

/// Response payload from `POST /api/saved-words` or `GET /api/saved-words`
public struct SavedWordDataResponse: Codable, Sendable {
    public let success: Bool?
    public let data: [SavedWord]?
    public let message: String?
}

public struct SingleSavedWordResponse: Codable, Sendable {
    public let success: Bool?
    public let data: SavedWord?
    public let message: String?
}

/// Client-side Word Intelligence result combining Apple NaturalLanguage with DictionaryAPI
public struct WordIntelligenceResult: Identifiable, Sendable {
    public var id: String { word }
    public let word: String
    public let lemma: String
    public let partOfSpeech: String
    public let cefr: String
    public var phonetic: String
    public var audioUrl: String?
    public var translation: String
    public var definitions: [String]
    public var confidenceScore: Int
    
    public init(
        word: String,
        lemma: String,
        partOfSpeech: String,
        cefr: String,
        phonetic: String = "",
        audioUrl: String? = nil,
        translation: String = "",
        definitions: [String] = [],
        confidenceScore: Int = 85
    ) {
        self.word = word
        self.lemma = lemma
        self.partOfSpeech = partOfSpeech
        self.cefr = cefr
        self.phonetic = phonetic
        self.audioUrl = audioUrl
        self.translation = translation
        self.definitions = definitions
        self.confidenceScore = confidenceScore
    }
}
