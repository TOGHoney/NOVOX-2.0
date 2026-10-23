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

/// Client-side Word Intelligence result combining Apple NaturalLanguage with Backend Word Intelligence
public struct WordIntelligenceResult: Identifiable, Sendable {
    public var id: String { word }
    public let word: String
    public let lemma: String
    public let partOfSpeech: String
    public let cefr: String
    public var phonetic: String
    public var pronunciationGuide: String?
    public var audioUrl: String?
    public var translation: String
    public var contextualMeaning: String?
    public var targetExpression: String?
    public var sourceLanguage: String?
    public var destinationLanguage: String?
    public var targetLanguageCode: String?
    public var baseLanguageCode: String?
    public var contextSentence: String?
    public var definitions: [String]
    public var confidenceScore: Int
    public var isSentence: Bool
    public var isBeginnerOrIntermediate: Bool
    
    public init(
        word: String,
        lemma: String = "",
        partOfSpeech: String = "word",
        cefr: String = "B1",
        phonetic: String = "",
        pronunciationGuide: String? = nil,
        audioUrl: String? = nil,
        translation: String = "",
        contextualMeaning: String? = nil,
        targetExpression: String? = nil,
        sourceLanguage: String? = nil,
        destinationLanguage: String? = nil,
        targetLanguageCode: String? = nil,
        baseLanguageCode: String? = nil,
        contextSentence: String? = nil,
        definitions: [String] = [],
        confidenceScore: Int = 85,
        isSentence: Bool = false,
        isBeginnerOrIntermediate: Bool = true
    ) {
        self.word = word
        self.lemma = lemma
        self.partOfSpeech = partOfSpeech
        self.cefr = cefr
        self.phonetic = phonetic
        self.pronunciationGuide = pronunciationGuide
        self.audioUrl = audioUrl
        self.translation = translation
        self.contextualMeaning = contextualMeaning
        self.targetExpression = targetExpression
        self.sourceLanguage = sourceLanguage
        self.destinationLanguage = destinationLanguage
        self.targetLanguageCode = targetLanguageCode
        self.baseLanguageCode = baseLanguageCode
        self.contextSentence = contextSentence
        self.definitions = definitions
        self.confidenceScore = confidenceScore
        self.isSentence = isSentence
        self.isBeginnerOrIntermediate = isBeginnerOrIntermediate
    }
}

