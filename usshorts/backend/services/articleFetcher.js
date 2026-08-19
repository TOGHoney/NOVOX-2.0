const Article = require('../models/Article');

const TOPICS = [
    { name: 'technology',       endpoint: 'everything',  params: 'q=technology' },
    { name: 'movies',           endpoint: 'everything',  params: 'q=movies' },
    { name: 'usa',              endpoint: 'everything',  params: 'q=USA' },
    { name: 'india',            endpoint: 'everything',  params: 'q=India' },
    { name: 'japan',            endpoint: 'everything',  params: 'q=Japan' },
    { name: 'china',            endpoint: 'everything',  params: 'q=China' },
    { name: 'russia',           endpoint: 'everything',  params: 'q=Russia' },
    { name: 'sports',           endpoint: 'top-headlines', params: 'category=sports&country=us' },
    { name: 'education',        endpoint: 'everything',  params: 'q=education' },
    { name: 'politics',         endpoint: 'everything',  params: 'q=politics' },
    { name: 'foreign-relations', endpoint: 'everything', params: 'q=foreign+relations' },
];

function normalizeArticle(raw, topic) {
    return {
        title: raw.title || 'Untitled',
        description: raw.description || '',
        content: raw.content || raw.description || '',
        source: raw.source?.name || 'Unknown',
        url: raw.url || '',
        imageUrl: raw.urlToImage || '',
        publishedAt: raw.publishedAt ? new Date(raw.publishedAt) : null,
        topic,
        aiSummary: null,
    };
}

async function fetchTopic(topicConfig) {
    const { name, endpoint, params } = topicConfig;
    const url = `https://newsapi.org/v2/${endpoint}?${params}&pageSize=100&sortBy=publishedAt&apiKey=${process.env.NEWS_API_KEY}`;

    try {
        const response = await fetch(url);
        const data = await response.json();

        if (data.status !== 'ok') {
            console.error(`[Fetcher] ${name}: API error — ${data.message}`);
            return [];
        }

        const articles = data.articles
            .map(raw => normalizeArticle(raw, name))
            .filter(a => a.url && a.title !== 'Untitled');

        let newCount = 0;
        let updatedCount = 0;

        for (const article of articles) {
            try {
                const result = await Article.updateOne(
                    { url: article.url },
                    { $set: article },
                    { upsert: true }
                );
                if (result.upsertedCount > 0) newCount++;
                else if (result.modifiedCount > 0) updatedCount++;
            } catch (err) {
                if (err.code !== 11000) {
                    console.error(`[Fetcher] ${name}: DB error — ${err.message}`);
                }
            }
        }

        console.log(`[Fetcher] ${name}: ${articles.length} fetched, ${newCount} new, ${updatedCount} updated`);
        return articles;
    } catch (err) {
        console.error(`[Fetcher] ${name}: fetch error — ${err.message}`);
        return [];
    }
}

async function fetchAllArticles() {
    console.log('[Fetcher] Starting full article fetch...');
    const startTime = Date.now();

    const results = await Promise.allSettled(
        TOPICS.map(topic => fetchTopic(topic))
    );

    const total = results.reduce((sum, r) => sum + (r.status === 'fulfilled' ? r.value.length : 0), 0);
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log(`[Fetcher] Complete. ${total} articles across ${TOPICS.length} topics in ${elapsed}s`);
}

module.exports = { fetchAllArticles, TOPICS };
