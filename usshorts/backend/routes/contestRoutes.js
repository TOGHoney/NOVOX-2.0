const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const contestController = require('../controllers/contestController');
const { auth } = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');

// Optional auth middleware: sets req.user if valid token provided, but doesn't block if missing
const optionalAuth = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('-password');
    if (user) req.user = user;
  } catch (err) {
    // Ignore invalid/expired token for optional endpoints
  }
  next();
};

// ==========================================
// Specific Routes (MUST PRECEDE /:id)
// ==========================================

// User discovery and my contests
router.get('/', optionalAuth, contestController.getContests);
router.get('/my', auth, contestController.getMyContests);
router.get('/public', optionalAuth, contestController.getPublicContests);

// Admin contest management
router.post('/create', auth, adminMiddleware, contestController.createContest);

// Participant activities & legacy routes
router.post('/join-passcode', auth, contestController.getContestByPasscode);
router.post('/submit', auth, contestController.submitContest);

// ==========================================
// Parameterized Routes (/:id)
// ==========================================

// Single contest details
router.get('/:id', optionalAuth, contestController.getContestById);

// Admin-only management
router.put('/:id', auth, adminMiddleware, contestController.updateContest);
router.patch('/:id/cancel', auth, adminMiddleware, contestController.cancelContest);
router.post('/:id/cancel', auth, adminMiddleware, contestController.cancelContest);
router.get('/:id/participants', auth, adminMiddleware, contestController.getContestParticipants);
router.delete('/:id', auth, adminMiddleware, contestController.deleteContest);

// User contest participation
router.post('/:id/join', auth, contestController.joinContest);
router.post('/:id/leave', auth, contestController.leaveContest);

// Leaderboard
router.get('/:id/leaderboard', contestController.getLeaderboard);

module.exports = router;