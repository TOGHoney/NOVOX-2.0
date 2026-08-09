const Bookmark = require('../models/Bookmark');

exports.getBookmarks = async (req, res) => {
    try {
        const bookmarks = await Bookmark.find({ user: req.user._id }).sort({ createdAt: -1 });
        res.status(200).json(bookmarks);
    } catch (error) {
        console.error('getBookmarks error:', error.message);
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.addBookmark = async (req, res) => {
    try {
        const { articleUrl, article } = req.body;
        if (!articleUrl) {
            return res.status(400).json({ message: 'articleUrl is required' });
        }

        const snapshot = article || {};
        const bookmark = await Bookmark.findOneAndUpdate(
            { user: req.user._id, articleUrl },
            {
                article: {
                    title: snapshot.title || '',
                    description: snapshot.description || '',
                    content: snapshot.content || '',
                    imageUrl: snapshot.imageUrl || '',
                    url: snapshot.url || articleUrl,
                    source: snapshot.source || '',
                    publishedAt: snapshot.publishedAt || '',
                    category: snapshot.category || '',
                    aiSummary: snapshot.aiSummary || null
                }
            },
            { new: true, upsert: true, setDefaultsOnInsert: true }
        );

        res.status(200).json(bookmark);
    } catch (error) {
        console.error('addBookmark error:', error.message);
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.removeBookmark = async (req, res) => {
    try {
        const { articleUrl } = req.query;
        if (!articleUrl) {
            return res.status(400).json({ message: 'articleUrl query parameter is required' });
        }

        await Bookmark.findOneAndDelete({ user: req.user._id, articleUrl });
        res.status(200).json({ message: 'Bookmark removed' });
    } catch (error) {
        console.error('removeBookmark error:', error.message);
        res.status(500).json({ message: 'Server Error' });
    }
};
