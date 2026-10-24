const mongoose = require('mongoose');

const segmentSchema = new mongoose.Schema(
    {
        word: { type: String, required: true },
        timestamp: { type: Number, default: 0 }, // seconds from turn start
        duration: { type: Number, default: 0 },
        confidence: { type: Number, default: 1.0 } // 0.0 - 1.0 acoustic confidence from Apple Speech
    },
    { _id: false }
);

const grammarErrorSchema = new mongoose.Schema(
    {
        originalSentence: { type: String, required: true },
        correctedSentence: { type: String, required: true },
        explanation: { type: String, required: true }, // in user's base language
        naturalAlternative: { type: String, default: null },
        isStylistic: { type: Boolean, default: false }
    },
    { _id: false }
);

const pronunciationIssueSchema = new mongoose.Schema(
    {
        word: { type: String, required: true },
        expectedPronunciation: { type: String, required: true },
        phonemeIssue: { type: String, required: true }, // explanation of syllable, stress, or sound
        audioTimestamp: { type: Number, default: 0 },
        confidence: { type: String, enum: ['high', 'moderate', 'low', 'uncertain'], default: 'moderate' }
    },
    { _id: false }
);

const factualClaimSchema = new mongoose.Schema(
    {
        claim: { type: String, required: true },
        status: {
            type: String,
            enum: ['supported', 'contradicted', 'unverified', 'opinion'],
            default: 'unverified'
        },
        explanation: { type: String, required: true },
        citation: { type: String, default: null }
    },
    { _id: false }
);

const speakingTurnSchema = new mongoose.Schema(
    {
        turnId: { type: String, required: true },
        turnIndex: { type: Number, required: true },
        durationSeconds: { type: Number, default: 0 },
        transcript: { type: String, required: true },
        segments: { type: [segmentSchema], default: [] },
        grammar: { type: [grammarErrorSchema], default: [] },
        pronunciation: { type: [pronunciationIssueSchema], default: [] },
        argumentation: {
            relevanceScore: { type: Number, default: 0 },
            assessment: { type: String, default: '' },
            actionableImprovement: { type: String, default: '' }
        },
        factualClaims: { type: [factualClaimSchema], default: [] },
        immediateTip: { type: String, default: '' },
        createdAt: { type: Date, default: Date.now }
    },
    { _id: false }
);

const scorecardCategorySchema = new mongoose.Schema(
    {
        score: { type: Number, min: 0, max: 100, default: 0 },
        explanation: { type: String, default: '' },
        evidence: { type: [String], default: [] },
        strengths: { type: [String], default: [] },
        areasToImprove: { type: [String], default: [] },
        practicalNextStep: { type: String, default: '' },
        insufficientEvidence: { type: Boolean, default: false }
    },
    { _id: false }
);

const scorecardSchema = new mongoose.Schema(
    {
        overallScore: { type: Number, min: 0, max: 100, default: 0 },
        summary: { type: String, default: '' },
        relevance: { type: scorecardCategorySchema, default: () => ({}) },
        factualAccuracy: { type: scorecardCategorySchema, default: () => ({}) },
        grammar: { type: scorecardCategorySchema, default: () => ({}) },
        pronunciation: { type: scorecardCategorySchema, default: () => ({}) },
        generatedAt: { type: Date, default: Date.now }
    },
    { _id: false }
);

const debateProctorSessionSchema = new mongoose.Schema(
    {
        roomId: { type: String, required: true },
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
        topic: { type: String, required: true },
        prompt: { type: String, default: '' },
        targetLanguage: { type: String, default: 'English' },
        baseLanguage: { type: String, default: 'English' },
        cefrLevel: { type: String, default: 'B1' },
        status: { type: String, enum: ['in_progress', 'completed'], default: 'in_progress' },
        turns: { type: [speakingTurnSchema], default: [] },
        scorecard: { type: scorecardSchema, default: null }
    },
    { timestamps: true }
);

// Indexes for fast lookup by room and user
debateProctorSessionSchema.index({ roomId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('DebateProctorSession', debateProctorSessionSchema);
