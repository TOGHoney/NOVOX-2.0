const mongoose = require('mongoose');
const DebateRoom = require('../models/DebateRoom');
const DebateProctorSession = require('../models/DebateProctorSession');
const User = require('../models/user');
const { evaluateSpeakingTurn, synthesizeScorecard } = require('../services/debateProctorService');

/**
 * Submits a completed speaking turn for proctor assessment.
 * POST /api/debates/proctor/turn
 */
exports.submitSpeakingTurn = async (req, res) => {
    try {
        const { roomId, transcript, durationSeconds = 0, segments = [], audioBase64, audioMime, topic: customTopic, prompt: customPrompt } = req.body || {};
        if (!roomId) {
            return res.status(400).json({ error: 'Room ID is required.' });
        }
        if ((!transcript || !transcript.trim()) && !audioBase64) {
            return res.status(400).json({ error: 'Transcript or audio recording is required.' });
        }

        const userId = req.user.id;
        let room = null;
        if (mongoose.isValidObjectId(roomId)) {
            room = await DebateRoom.findById(roomId);
        }

        const topic = room?.topic || customTopic || 'General Debate';
        const prompt = room?.prompt || customPrompt || '';

        const user = await User.findById(userId);
        const targetLanguage = user?.targetLanguage || room?.language || 'English';
        const baseLanguage = user?.nativeLanguage || 'English';
        const cefrLevel = user?.cefrLevel || room?.level || 'B1';

        // Find or create proctor session for this user in this room
        let session = await DebateProctorSession.findOne({ roomId, userId });
        if (!session) {
            session = new DebateProctorSession({
                roomId,
                userId,
                topic,
                prompt,
                targetLanguage,
                baseLanguage,
                cefrLevel,
                turns: []
            });
        }

        const turnIndex = session.turns.length + 1;
        const turnId = `turn_${Date.now()}_${turnIndex}`;

        // Perform AI evaluation
        const evaluation = await evaluateSpeakingTurn({
            topic,
            prompt,
            targetLanguage,
            baseLanguage,
            cefrLevel,
            transcript: transcript ? transcript.trim() : '',
            segments: Array.isArray(segments) ? segments : [],
            audioBase64,
            audioMime,
            turnIndex
        });

        const finalTranscript = evaluation.transcript || (transcript ? transcript.trim() : 'Spoken participation');

        const turnRecord = {
            turnId,
            turnIndex,
            durationSeconds: Math.max(1, Math.round(durationSeconds)),
            transcript: finalTranscript,
            segments: Array.isArray(segments) && segments.length > 0 ? segments : (finalTranscript.split(/\s+/).map((w, idx) => ({ word: w, timestamp: idx * 0.4, duration: 0.3, confidence: 0.85 }))),
            grammar: evaluation.grammar,
            pronunciation: evaluation.pronunciation,
            argumentation: evaluation.argumentation,
            factualClaims: evaluation.factualClaims,
            immediateTip: evaluation.immediateTip,
            createdAt: new Date()
        };

        session.turns.push(turnRecord);
        await session.save();

        res.json({
            success: true,
            turn: turnRecord,
            totalTurns: session.turns.length
        });
    } catch (err) {
        console.error('[debateProctorController] submitSpeakingTurn error:', err.message);
        res.status(500).json({ error: 'Failed to analyze speaking turn.' });
    }
};

/**
 * Retrieves the proctor session data, turns, and scorecard for a room.
 * GET /api/debates/proctor/session/:roomId
 */
exports.getDebateSession = async (req, res) => {
    try {
        const { roomId } = req.params;
        const userId = req.user.id;

        const session = await DebateProctorSession.findOne({ roomId, userId });
        if (!session) {
            return res.json({ session: null, turns: [], scorecard: null });
        }

        res.json({
            session: {
                id: session._id,
                roomId: session.roomId,
                topic: session.topic,
                prompt: session.prompt,
                targetLanguage: session.targetLanguage,
                baseLanguage: session.baseLanguage,
                cefrLevel: session.cefrLevel,
                status: session.status
            },
            turns: session.turns,
            scorecard: session.scorecard
        });
    } catch (err) {
        console.error('[debateProctorController] getDebateSession error:', err.message);
        res.status(500).json({ error: 'Failed to fetch proctor session.' });
    }
};

/**
 * Concludes the debate proctor session and generates the end-of-debate scorecard.
 * POST /api/debates/proctor/finish/:roomId
 */
exports.finishDebateSession = async (req, res) => {
    try {
        const { roomId } = req.params;
        const userId = req.user.id;

        let session = await DebateProctorSession.findOne({ roomId, userId });
        if (!session || session.turns.length === 0) {
            const room = mongoose.isValidObjectId(roomId) ? await DebateRoom.findById(roomId) : null;
            const user = await User.findById(userId);

            const emptyScorecard = await synthesizeScorecard({
                topic: room?.topic || 'Debate',
                prompt: room?.prompt || '',
                targetLanguage: user?.targetLanguage || 'English',
                baseLanguage: user?.nativeLanguage || 'English',
                cefrLevel: user?.cefrLevel || 'B1',
                turns: []
            });

            return res.json({
                success: true,
                scorecard: emptyScorecard,
                turns: []
            });
        }

        // Generate final comprehensive scorecard
        const scorecard = await synthesizeScorecard({
            topic: session.topic,
            prompt: session.prompt,
            targetLanguage: session.targetLanguage,
            baseLanguage: session.baseLanguage,
            cefrLevel: session.cefrLevel,
            turns: session.turns
        });

        session.scorecard = scorecard;
        session.status = 'completed';
        await session.save();

        res.json({
            success: true,
            scorecard,
            turns: session.turns
        });
    } catch (err) {
        console.error('[debateProctorController] finishDebateSession error:', err.message);
        res.status(500).json({ error: 'Failed to generate debate scorecard.' });
    }
};
