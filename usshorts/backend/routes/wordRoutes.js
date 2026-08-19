const express = require('express');
const router = express.Router();
const { saveWord, getSavedWords, deleteWord } = require('../controllers/wordController');

// Destructure 'auth' from authMiddleware and alias/use it as 'protect'
const { auth: protect } = require('../middleware/authMiddleware');

router.use(protect);

router.post('/', saveWord);
router.get('/', getSavedWords);
router.delete('/:id', deleteWord);


const router = express.Router();

const { saveWord, getSavedWords, deleteWord } = require('../controllers/wordController');



// Destructure 'auth' from authMiddleware and alias/use it as 'protect'

const { auth: protect } = require('../middleware/authMiddleware');



router.use(protect);



router.post('/', saveWord);

router.get('/', getSavedWords);

router.delete('/:id', deleteWord);



module.exports = router;