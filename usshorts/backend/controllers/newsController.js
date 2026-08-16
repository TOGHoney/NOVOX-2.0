const { summarizeArticle } = require('../services/geminiService');

const cache = new Map();
const CACHE_TTL = 5 * 60 * 1000;

function getCached(key) {
    const entry = cache.get(key);
    if (entry && Date.now() - entry.timestamp < CACHE_TTL) {
        return entry.data;
    }
    cache.delete(key);
    return null;
}

function setCache(key, data) {
    cache.set(key, { data, timestamp: Date.now() });
}

function normalizeArticle(article, index) {
    return {
        id: index + 1,
        title: article.title || 'Untitled',
        description: article.description || '',
        content: article.content || article.description || '',
        source: article.source?.name || 'Unknown',
        url: article.url || '',
        imageUrl: article.urlToImage || '',
        publishedAt: article.publishedAt || '',
        category: 'General',
        aiSummary: null,
    };
}

async function enrichWithSummary(articles) {
    const enriched = await Promise.allSettled(
        articles.map(async (article, index) => {
            const normalized = normalizeArticle(article, index);
            try {
                const summary = await summarizeArticle(normalized.title, normalized.content);
                normalized.aiSummary = summary;
            } catch {
                normalized.aiSummary = null;
            }
            return normalized;
        })
    );

    return enriched.map((result) =>
        result.status === 'fulfilled' ? result.value : { ...normalizeArticle({}, 0), aiSummary: null }
    );
}

async function getHeadlines(req, res) {
    try {
        const category = req.query.category || 'general';
        const cacheKey = `headlines:${category}`;

        const cached = getCached(cacheKey);
        if (cached) return res.json(cached);

        const url = `https://newsapi.org/v2/top-headlines?country=us&category=${category}&pageSize=20&apiKey=${process.env.NEWS_API_KEY}`;
        const response = await fetch(url);
        const data = await response.json();

        if (data.status !== 'ok') {
            return res.status(500).json({ error: data.message || 'Failed to fetch news' });
        }

        const articles = await enrichWithSummary(data.articles);
        setCache(cacheKey, articles);
        res.json(articles);
    } catch (err) {
        console.error('Headlines error:', err.message);
        res.status(500).json({ error: 'Failed to fetch news' });
    }
}

async function searchNews(req, res) {
    try {
        const query = req.query.q;
        if (!query) return res.status(400).json({ error: 'Query parameter "q" is required' });

        const cacheKey = `search:${query}`;
        const cached = getCached(cacheKey);
        if (cached) return res.json(cached);

        const url = `https://newsapi.org/v2/everything?q=${encodeURIComponent(query)}&sortBy=relevancy&pageSize=20&apiKey=${process.env.NEWS_API_KEY}`;
        const response = await fetch(url);
        const data = await response.json();

        if (data.status !== 'ok') {
            return res.status(500).json({ error: data.message || 'Failed to fetch news' });
        }

        const articles = await enrichWithSummary(data.articles);
        setCache(cacheKey, articles);
        res.json(articles);
    } catch (err) {
        console.error('Search error:', err.message);
        res.status(500).json({ error: 'Failed to fetch news' });
    }
}

module.exports = { getHeadlines, searchNews };
