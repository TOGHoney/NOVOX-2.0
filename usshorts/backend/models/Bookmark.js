const mongoose = require('mongoose');

const bookmarkSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    articleUrl: { type: String, required: true },
    article: {
        title: { type: String, default: '' },
        description: { type: String, default: '' },
        content: { type: String, default: '' },
        imageUrl: { type: String, default: '' },
        url: { type: String, default: '' },
        source: { type: String, default: '' },
        publishedAt: { type: String, default: '' },
        category: { type: String, default: '' },
        aiSummary: { type: String, default: null }
    }
}, { timestamps: true });

bookmarkSchema.index({ user: 1, articleUrl: 1 }, { unique: true });

module.exports = mongoose.model('Bookmark', bookmarkSchema);
