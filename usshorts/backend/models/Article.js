const mongoose = require('mongoose');

const articleSchema = new mongoose.Schema({
    title: { type: String, required: true },
    description: { type: String, default: '' },
    content: { type: String, default: '' },
    source: { type: String, default: 'Unknown' },
    url: { type: String, required: true, unique: true },
    imageUrl: { type: String, default: '' },
    publishedAt: { type: Date, default: null },
    topic: { type: String, required: true },
    aiSummary: { type: String, default: null },
    fetchedAt: { type: Date, default: Date.now }
});

articleSchema.index({ url: 1 }, { unique: true });
articleSchema.index({ topic: 1, fetchedAt: -1 });
articleSchema.index({ fetchedAt: 1 }, { expireAfterSeconds: 604800 });

module.exports = mongoose.model('Article', articleSchema);
