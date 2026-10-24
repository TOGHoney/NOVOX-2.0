const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/authMiddleware');
const {
    submitSpeakingTurn,
    getDebateSession,
    finishDebateSession
} = require('../controllers/debateProctorController');

// All proctoring routes are protected by JWT auth
router.post('/turn', auth, submitSpeakingTurn);
router.get('/session/:roomId', auth, getDebateSession);
router.post('/finish/:roomId', auth, finishDebateSession);

module.exports = router;
