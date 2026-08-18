const mongoose = require('mongoose');



const SavedWordSchema = new mongoose.Schema(

  {

    userId: {

      type: mongoose.Schema.Types.ObjectId,

      ref: 'User',

      required: true

    },

    word: {

      type: String,

      required: true,

      trim: true

    },

    translation: {

      type: String,

      default: ''

    },

    contextSentence: {

      type: String,

      default: ''

    },

    definition: {

      type: String,

      default: ''

    },

    phonetic: {

      type: String,

      default: ''

    },

    cefr: {

      type: String,

      default: ''

    },

    masteryScore: {

      type: Number,

      default: 0 // Track user quiz performance per word

    }

  },

  { timestamps: true }

);



// Prevent duplicate word entries per user

SavedWordSchema.index({ userId: 1, word: 1 }, { unique: true });



module.exports = mongoose.model('SavedWord', SavedWordSchema);