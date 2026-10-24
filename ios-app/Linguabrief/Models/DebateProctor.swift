import Foundation

// MARK: - Speech Transcript Models

public struct TranscriptSegment: Codable, Identifiable {
    public var id: String { "\(word)_\(timestamp)" }
    public let word: String
    public let timestamp: Double
    public let duration: Double
    public let confidence: Double

    public init(word: String, timestamp: Double, duration: Double = 0.0, confidence: Double = 1.0) {
        self.word = word
        self.timestamp = timestamp
        self.duration = duration
        self.confidence = confidence
    }
}

// MARK: - Turn Feedback Models

public struct GrammarError: Codable, Identifiable {
    public var id: String { "\(originalSentence)_\(correctedSentence)" }
    public let originalSentence: String
    public let correctedSentence: String
    public let explanation: String
    public let naturalAlternative: String?
    public let isStylistic: Bool

    public init(
        originalSentence: String,
        correctedSentence: String,
        explanation: String,
        naturalAlternative: String? = nil,
        isStylistic: Bool = false
    ) {
        self.originalSentence = originalSentence
        self.correctedSentence = correctedSentence
        self.explanation = explanation
        self.naturalAlternative = naturalAlternative
        self.isStylistic = isStylistic
    }
}

public struct PronunciationIssue: Codable, Identifiable {
    public var id: String { "\(word)_\(audioTimestamp)" }
    public let word: String
    public let expectedPronunciation: String
    public let phonemeIssue: String
    public let audioTimestamp: Double
    public let confidence: String

    public init(
        word: String,
        expectedPronunciation: String,
        phonemeIssue: String,
        audioTimestamp: Double = 0.0,
        confidence: String = "moderate"
    ) {
        self.word = word
        self.expectedPronunciation = expectedPronunciation
        self.phonemeIssue = phonemeIssue
        self.audioTimestamp = audioTimestamp
        self.confidence = confidence
    }
}

public struct ArgumentationFeedback: Codable {
    public let relevanceScore: Int
    public let assessment: String
    public let actionableImprovement: String

    public init(relevanceScore: Int = 75, assessment: String = "", actionableImprovement: String = "") {
        self.relevanceScore = relevanceScore
        self.assessment = assessment
        self.actionableImprovement = actionableImprovement
    }
}

public struct FactualClaimFeedback: Codable, Identifiable {
    public var id: String { claim }
    public let claim: String
    public let status: String // supported, contradicted, unverified, opinion
    public let explanation: String
    public let citation: String?

    public init(claim: String, status: String, explanation: String, citation: String? = nil) {
        self.claim = claim
        self.status = status
        self.explanation = explanation
        self.citation = citation
    }
}

public struct TurnProctorFeedback: Codable, Identifiable {
    public var id: String { turnId }
    public let turnId: String
    public let turnIndex: Int
    public let durationSeconds: Int
    public let transcript: String
    public let segments: [TranscriptSegment]
    public let grammar: [GrammarError]
    public let pronunciation: [PronunciationIssue]
    public let argumentation: ArgumentationFeedback
    public let factualClaims: [FactualClaimFeedback]
    public let immediateTip: String

    public init(
        turnId: String = UUID().uuidString,
        turnIndex: Int = 1,
        durationSeconds: Int = 0,
        transcript: String = "",
        segments: [TranscriptSegment] = [],
        grammar: [GrammarError] = [],
        pronunciation: [PronunciationIssue] = [],
        argumentation: ArgumentationFeedback = ArgumentationFeedback(),
        factualClaims: [FactualClaimFeedback] = [],
        immediateTip: String = ""
    ) {
        self.turnId = turnId
        self.turnIndex = turnIndex
        self.durationSeconds = durationSeconds
        self.transcript = transcript
        self.segments = segments
        self.grammar = grammar
        self.pronunciation = pronunciation
        self.argumentation = argumentation
        self.factualClaims = factualClaims
        self.immediateTip = immediateTip
    }
}

// MARK: - Scorecard Models

public struct ScorecardCategory: Codable {
    public let score: Int
    public let explanation: String
    public let evidence: [String]
    public let strengths: [String]
    public let areasToImprove: [String]
    public let practicalNextStep: String
    public let insufficientEvidence: Bool?

    public init(
        score: Int = 0,
        explanation: String = "",
        evidence: [String] = [],
        strengths: [String] = [],
        areasToImprove: [String] = [],
        practicalNextStep: String = "",
        insufficientEvidence: Bool? = false
    ) {
        self.score = score
        self.explanation = explanation
        self.evidence = evidence
        self.strengths = strengths
        self.areasToImprove = areasToImprove
        self.practicalNextStep = practicalNextStep
        self.insufficientEvidence = insufficientEvidence
    }
}

public struct DebateScorecard: Codable {
    public let overallScore: Int
    public let summary: String
    public let relevance: ScorecardCategory
    public let factualAccuracy: ScorecardCategory
    public let grammar: ScorecardCategory
    public let pronunciation: ScorecardCategory

    public init(
        overallScore: Int = 0,
        summary: String = "",
        relevance: ScorecardCategory = ScorecardCategory(),
        factualAccuracy: ScorecardCategory = ScorecardCategory(),
        grammar: ScorecardCategory = ScorecardCategory(),
        pronunciation: ScorecardCategory = ScorecardCategory()
    ) {
        self.overallScore = overallScore
        self.summary = summary
        self.relevance = relevance
        self.factualAccuracy = factualAccuracy
        self.grammar = grammar
        self.pronunciation = pronunciation
    }
}

// MARK: - API Request & Response DTOs

public struct ProctorTurnRequest: Codable {
    public let roomId: String
    public let transcript: String
    public let durationSeconds: Int
    public let segments: [TranscriptSegment]
    public let topic: String?
    public let prompt: String?
    public let audioBase64: String?
    public let audioMime: String?

    public init(
        roomId: String,
        transcript: String,
        durationSeconds: Int,
        segments: [TranscriptSegment],
        topic: String? = nil,
        prompt: String? = nil,
        audioBase64: String? = nil,
        audioMime: String? = nil
    ) {
        self.roomId = roomId
        self.transcript = transcript
        self.durationSeconds = durationSeconds
        self.segments = segments
        self.topic = topic
        self.prompt = prompt
        self.audioBase64 = audioBase64
        self.audioMime = audioMime
    }
}

public struct ProctorTurnResponse: Codable {
    public let success: Bool
    public let turn: TurnProctorFeedback
}

public struct ProctorFinishResponse: Codable {
    public let success: Bool
    public let scorecard: DebateScorecard
    public let turns: [TurnProctorFeedback]?
}

public struct ProctorSessionInfo: Codable {
    public let id: String?
    public let roomId: String
    public let topic: String
    public let prompt: String?
    public let targetLanguage: String
    public let baseLanguage: String
    public let cefrLevel: String
    public let status: String
}

public struct ProctorSessionResponse: Codable {
    public let session: ProctorSessionInfo?
    public let turns: [TurnProctorFeedback]?
    public let scorecard: DebateScorecard?
}
