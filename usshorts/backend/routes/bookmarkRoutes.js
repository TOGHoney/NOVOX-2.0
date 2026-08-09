const express = require('express');
const router = express.Router();

const { auth } = require('../middleware/authMiddleware');
const { getBookmarks, addBookmark, removeBookmark } = require('../controllers/bookmarkController');

router.get('/', auth, getBookmarks);
router.post('/', auth, addBookmark);
router.delete('/', auth, removeBookmark);

module.exports = router;
