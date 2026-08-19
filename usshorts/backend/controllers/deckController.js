const FlashcardDeck = require('../models/FlashcardDeck');

// Get all decks for logged-in user
exports.getDecks = async (req, res) => {
  try {
    const decks = await FlashcardDeck.find({ user: req.user.id }).sort({ createdAt: -1 });
    res.json(decks);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
};

// Create a new deck
exports.createDeck = async (req, res) => {
  try {
    const { title, deck, wordCount } = req.body;
    const newDeck = new FlashcardDeck({
      user: req.user.id,
      title,
      deck,
      wordCount
    });
    const saved = await newDeck.save();
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
};

// Delete a deck
exports.deleteDeck = async (req, res) => {
  try {
    await FlashcardDeck.findOneAndDelete({ _id: req.params.id, user: req.user.id });
    res.json({ message: 'Deck deleted' });
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
};