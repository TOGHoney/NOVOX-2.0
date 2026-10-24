const express = require('express');

const cors = require('cors');

const app = express(); // 1. CREATE THE APP FIRST





// 2. MIDDLEWARE

app.use(cors());

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));



// 3. ROUTES

const authRoutes = require('./routes/authRoutes');

const newsRoutes = require('./routes/newsRoutes');

const userRoutes = require('./routes/userRoutes');

const commentRoutes = require('./routes/commentRoutes');

const bookmarkRoutes = require('./routes/bookmarkRoutes');

const debateProctorRoutes = require('./routes/debateProctorRoutes');
const debateRoutes = require('./routes/debateRoutes');

const feedRoutes = require('./routes/feedRoutes');

const translateRoutes = require('./routes/translateRoutes');
const wordRoutes = require('./routes/wordRoutes');
const contestRoutes = require('./routes/contestRoutes');
const deckRoutes = require('./routes/deckRoutes');

app.use('/api/auth', authRoutes);

app.use('/api/news', newsRoutes);

app.use('/api/users', userRoutes);

app.use('/api/comments', commentRoutes);

app.use('/api/bookmarks', bookmarkRoutes);

app.use('/api/debates/proctor', debateProctorRoutes);
app.use('/api/debates', debateRoutes);

app.use('/api/translate', translateRoutes);
app.use('/api/saved-words', wordRoutes);
app.use('/api/contests', contestRoutes);
app.use('/api/flashcard-decks', deckRoutes);


app.use('/api/feed', feedRoutes);




// Basic Route for testing

app.get('/', (req, res) => {

    res.send('LinguaBrief API is running...');

});

// 4. 404 HANDLER FOR UNMATCHED ROUTES
app.use((req, res) => {
    res.status(404).json({ error: '404 - Resource or API endpoint not found' });
});

// 5. GLOBAL ERROR HANDLER
app.use((err, req, res, next) => {
    console.error('[Express Error]', err.message);
    if (err.type === 'entity.too.large') {
        return res.status(413).json({ error: 'Payload too large. Audio file exceeds size limit.' });
    }
    res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
});

// 6. EXPORT THE APP
module.exports = app;