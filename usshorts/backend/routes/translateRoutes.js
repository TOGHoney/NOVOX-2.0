const express = require('express');
const router = express.Router();
const { translate, wordIntelligence } = require('../controllers/translateController');

router.post('/', translate);
router.post('/word-intelligence', wordIntelligence);

module.exports = router;

