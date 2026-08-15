const { summarizeArticle } = require('../services/geminiService');
const axios = require('axios');
const { JSDOM } = require('jsdom');
const { Readability } = require('@mozilla/readability');

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

// Helper: Calculate YYYY-MM-DD format for N days ago (Default 30 days)
function getPastDateISO(daysAgo = 30) {
    const date = new Date();
    date.setDate(date.getDate() - daysAgo);
    return date.toISOString().split('T')[0];
}

// Helper to scrape full text using Mozilla Readability
async function extractFullContent(url) {
    if (!url) return null;
    try {
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            },
            timeout: 7000
        });
        const dom = new JSDOM(response.data, { url });
        const reader = new Readability(dom.window.document);
        const parsed = reader.parse();
        return parsed?.textContent?.trim() || null;
    } catch {
        return null; // Fallback if site blocks scraping
    }
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
                // 1. Scrape full text from source URL
                const fullText = await extractFullContent(normalized.url);
                // 2. Fall back to normalized content if full scraping fails
                const contentToSummarize = fullText || normalized.content;

                // 3. Generate summary from full text
                const summary = await summarizeArticle(normalized.title, contentToSummarize);
                normalized.aiSummary = summary;
            } catch {
                normalized.aiSummary = normalized.description || null;
            }
            return normalized;
        })
    );

    return enriched.map((result) =>
        result.status === 'fulfilled' ? result.value : { ...normalizeArticle({}, 0), aiSummary: null }
    );
}

// FIXED: Fetching Past 30 Days of News on Main Feed
// Handles Past 30 Days News with Deep Pagination (pageSize=100)
async function getHeadlines(req, res) {
    try {
        const category = req.query.category || 'general';
        // Parse requested page (default to Page 1)
        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const cacheKey = `headlines:${category}:page:${page}`;

        const cached = getCached(cacheKey);
        if (cached) return res.json(cached);

        const fromDate = getPastDateISO(30);

        // Explicitly requesting 100 articles for the requested page number
        const url = `https://newsapi.org/v2/everything?q=${encodeURIComponent(category)}&from=${fromDate}&sortBy=publishedAt&pageSize=100&page=${page}&apiKey=${process.env.NEWS_API_KEY}`;
        
        const response = await fetch(url);
        const data = await response.json();

        if (data.status !== 'ok') {
            return res.status(500).json({ error: data.message || 'Failed to fetch news' });
        }

        // Fast processing: summarize top 3 on page load, use description for remainder 
        // to prevent API gateway timeouts when pulling 100 articles per batch
        const articles = await Promise.all(
            data.articles.map(async (article, index) => {
                const normalized = normalizeArticle(article, index);
                if (index < 3) {
                    try {
                        const fullText = await extractFullContent(normalized.url);
                        const contentToSummarize = fullText || normalized.content;
                        normalized.aiSummary = await summarizeArticle(normalized.title, contentToSummarize);
                    } catch {
                        normalized.aiSummary = normalized.description;
                    }
                } else {
                    normalized.aiSummary = normalized.description;
                }
                return normalized;
            })
        );

        setCache(cacheKey, articles);
        res.json(articles);
    } catch (err) {
        console.error('Headlines error:', err.message);
        res.status(500).json({ error: 'Failed to fetch news' });
    }
}

// Handles Past 30 Days News Search with Deep Pagination (pageSize=100)
async function searchNews(req, res) {
    try {
        const query = req.query.q;
        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const titleOnly = req.query.titleOnly === 'true';
        
        if (!query) return res.status(400).json({ error: 'Query parameter "q" is required' });

        const cacheKey = `search:${query}:titleOnly:${titleOnly}:page:${page}`;
        const cached = getCached(cacheKey);
        if (cached) return res.json(cached);

        const fromDate = getPastDateISO(30);
        const searchTarget = titleOnly ? `qInTitle=${encodeURIComponent(query)}` : `q=${encodeURIComponent(query)}`;

        const url = `https://newsapi.org/v2/everything?${searchTarget}&from=${fromDate}&sortBy=publishedAt&pageSize=100&page=${page}&apiKey=${process.env.NEWS_API_KEY}`;
        
        const response = await fetch(url);
        const data = await response.json();

        if (data.status !== 'ok') {
            return res.status(500).json({ error: data.message || 'Failed to fetch news' });
        }

        const articles = await Promise.all(
            data.articles.map(async (article, index) => {
                const normalized = normalizeArticle(article, index);
                if (index < 3) {
                    try {
                        const fullText = await extractFullContent(normalized.url);
                        const contentToSummarize = fullText || normalized.content;
                        normalized.aiSummary = await summarizeArticle(normalized.title, contentToSummarize);
                    } catch {
                        normalized.aiSummary = normalized.description;
                    }
                } else {
                    normalized.aiSummary = normalized.description;
                }
                return normalized;
            })
        );

        setCache(cacheKey, articles);
        res.json(articles);
    } catch (err) {
        console.error('Search error:', err.message);
        res.status(500).json({ error: 'Failed to fetch news' });
    }
}

module.exports = { getHeadlines, searchNews };