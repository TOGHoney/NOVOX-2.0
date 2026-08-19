const mongoose = require('mongoose');

const FlashcardDeckSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true
  },
  deck: {
    type: Array,
    default: []
  },
  wordCount: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('FlashcardDeck', FlashcardDeckSchema);