require('dotenv').config({ path: './.env' });
const http = require('http');
const app = require('./app');
const mongoose = require('mongoose');
const { Server } = require('socket.io');
const { initSocket } = require('./services/socketService');

// Libraries required for article extraction
const axios = require('axios');
const { JSDOM } = require('jsdom');
const { Readability } = require('@mozilla/readability');

const PORT = process.env.PORT || 5000;

// Article Extraction Endpoint
app.get('/api/extract-article', async (req, res) => {
    const { url } = req.query;
    if (!url) {
        return res.status(400).json({ error: 'URL query parameter is required' });
    }

    try {
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            },
            timeout: 10000
        });

        const dom = new JSDOM(response.data, { url });
        const reader = new Readability(dom.window.document);
        const article = reader.parse();

        if (!article || !article.textContent) {
            return res.status(404).json({ error: 'Unable to extract full text content from source.' });
        }

        res.json({
            title: article.title,
            content: article.textContent,
            byline: article.byline,
            siteName: article.siteName
        });
    } catch (error) {
        console.error('Extraction error:', error.message);
        res.status(500).json({ error: 'Failed to retrieve article content.' });
    }
});

// Create HTTP server and attach Socket.IO immediately so the API is available right away
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: process.env.CLIENT_ORIGIN || 'http://localhost:5173',
        methods: ['GET', 'POST']
    }
});
initSocket(io);

server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

// Connect to MongoDB in the background
mongoose.connect(process.env.MONGO_URI)
    .then(() => {
        console.log('Connected to MongoDB successfully');
    })
    .catch((err) => {
        console.error('Database connection error:', err.message);
        process.exit(1); // Exit process with failure
    });