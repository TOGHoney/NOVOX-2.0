const express = require('express');
const router = express.Router();

const { auth } = require('../middleware/authMiddleware');
const { getComments, createComment, deleteComment } = require('../controllers/commentController');

router.get('/', getComments);
router.post('/', auth, createComment);
router.delete('/:id', auth, deleteComment);

module.exports = router;
