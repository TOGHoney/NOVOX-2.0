const express = require('express');
const router = express.Router();
const { getFeed, fetchSummaries, triggerFetch } = require('../controllers/feedController');

router.get('/', getFeed);
router.post('/summary', fetchSummaries);
router.post('/fetch', triggerFetch);

module.exports = router;

