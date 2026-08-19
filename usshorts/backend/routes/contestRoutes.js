const express = require('express');
const router = express.Router();
const contestController = require('../controllers/contestController');

// Destructure 'auth' from authMiddleware exports
const { auth } = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');

// Public and User Endpoints
router.get('/public', contestController.getPublicContests);
router.post('/join-passcode', auth, contestController.getContestByPasscode);
router.post('/submit', auth, contestController.submitContest);
router.get('/:id/leaderboard', contestController.getLeaderboard);

// Protected Admin Endpoint
router.get('/', auth, adminMiddleware, contestController.getAllContests);
router.post('/create', auth, adminMiddleware, contestController.createContest);
router.delete('/:id', auth, adminMiddleware, contestController.deleteContest);
module.exports = router;