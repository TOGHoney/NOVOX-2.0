const express = require('express');
const router = express.Router();


const { auth } = require('../middleware/authMiddleware');
const { getDecks, createDeck, deleteDeck } = require('../controllers/deckController');


router.get('/', auth, getDecks);
router.post('/', auth, createDeck);
router.delete('/:id', auth, deleteDeck);

module.exports = router;