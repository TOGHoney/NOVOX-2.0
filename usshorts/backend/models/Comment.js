const mongoose = require('mongoose');

const commentSchema = new mongoose.Schema({
    articleUrl: { type: String, required: true, index: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, required: true },
    isReply: { type: Boolean, default: false },
    parent: { type: mongoose.Schema.Types.ObjectId, ref: 'Comment', default: null }
}, { timestamps: true });

module.exports = mongoose.model('Comment', commentSchema);
