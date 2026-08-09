const Comment = require('../models/Comment');

function toCommentResponse(comment) {
    const user = comment.user || {};
    return {
        id: comment._id,
        articleUrl: comment.articleUrl,
        author: user.username || 'Unknown',
        userId: user._id ? user._id.toString() : null,
        text: comment.text,
        isReply: comment.isReply,
        parent: comment.parent ? comment.parent.toString() : null,
        createdAt: comment.createdAt,
        updatedAt: comment.updatedAt
    };
}

exports.getComments = async (req, res) => {
    try {
        const { articleUrl } = req.query;
        if (!articleUrl) {
            return res.status(400).json({ message: 'articleUrl query parameter is required' });
        }

        const comments = await Comment.find({ articleUrl })
            .populate('user', 'username')
            .sort({ createdAt: 1 });

        res.status(200).json(comments.map(toCommentResponse));
    } catch (error) {
        console.error('getComments error:', error.message);
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.createComment = async (req, res) => {
    try {
        const { articleUrl, text, parentId } = req.body;

        if (!articleUrl || !text || !text.trim()) {
            return res.status(400).json({ message: 'articleUrl and text are required' });
        }

        const isReply = Boolean(parentId);
        if (isReply) {
            const parent = await Comment.findById(parentId);
            if (!parent) {
                return res.status(404).json({ message: 'Parent comment not found' });
            }
        }

        const comment = await Comment.create({
            articleUrl,
            user: req.user._id,
            text: text.trim(),
            isReply,
            parent: parentId || null
        });

        const populated = await Comment.findById(comment._id).populate('user', 'username');
        res.status(201).json(toCommentResponse(populated));
    } catch (error) {
        console.error('createComment error:', error.message);
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.deleteComment = async (req, res) => {
    try {
        const { id } = req.params;
        const comment = await Comment.findById(id);

        if (!comment) {
            return res.status(404).json({ message: 'Comment not found' });
        }

        const isOwner = comment.user.toString() === req.user._id.toString();
        const isAdmin = req.user.role === 'admin';

        if (!isOwner && !isAdmin) {
            return res.status(403).json({ message: 'Not authorized to delete this comment' });
        }

        await Comment.deleteMany({ parent: comment._id });
        await comment.deleteOne();

        res.status(200).json({ message: 'Comment deleted' });
    } catch (error) {
        console.error('deleteComment error:', error.message);
        res.status(500).json({ message: 'Server Error' });
    }
};
