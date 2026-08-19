const SavedWord = require('../models/SavedWord');

// Save a word
exports.saveWord = async (req, res) => {
  try {
    const { word, translation, contextSentence, definition, phonetic, cefr } = req.body;
    const userId = req.user.id; // Assumes your auth middleware attaches user info

    const savedWord = await SavedWord.create({
      userId,
      word,
      translation,
      contextSentence,
      definition,
      phonetic,
      cefr
    });

    res.status(201).json({ success: true, data: savedWord });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'Word already saved' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get all saved words for user
exports.getSavedWords = async (req, res) => {
  try {
    const words = await SavedWord.find({ userId: req.user.id }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: words });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Delete a saved word
exports.deleteWord = async (req, res) => {
  try {
    await SavedWord.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
    res.status(200).json({ success: true, message: 'Word removed' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }

const SavedWord = require('../models/SavedWord');



// Save a word

exports.saveWord = async (req, res) => {

  try {

    const { word, translation, contextSentence, definition, phonetic, cefr } = req.body;

    const userId = req.user.id; // Assumes your auth middleware attaches user info



    const savedWord = await SavedWord.create({

      userId,

      word,

      translation,

      contextSentence,

      definition,

      phonetic,

      cefr

    });



    res.status(201).json({ success: true, data: savedWord });

  } catch (error) {

    if (error.code === 11000) {

      return res.status(400).json({ success: false, message: 'Word already saved' });

    }

    res.status(500).json({ success: false, message: error.message });

  }

};



// Get all saved words for user

exports.getSavedWords = async (req, res) => {

  try {

    const words = await SavedWord.find({ userId: req.user.id }).sort({ createdAt: -1 });

    res.status(200).json({ success: true, data: words });

  } catch (error) {

    res.status(500).json({ success: false, message: error.message });

  }

};



// Delete a saved word

exports.deleteWord = async (req, res) => {

  try {

    await SavedWord.findOneAndDelete({ _id: req.params.id, userId: req.user.id });

    res.status(200).json({ success: true, message: 'Word removed' });

  } catch (error) {

    res.status(500).json({ success: false, message: error.message });

  }

};