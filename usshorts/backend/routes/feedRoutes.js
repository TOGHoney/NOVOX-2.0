const express = require('express');
const router = express.Router();
const { getFeed, fetchSummaries } = require('../controllers/feedController');

router.get('/', getFeed);
router.post('/summary', fetchSummaries);

module.exports = router;
