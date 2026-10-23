const Article = require('../models/Article');
const { summarizeArticle } = require('../services/geminiService');
const { fetchAllArticles } = require('../services/articleFetcher');
const { translateTexts } = require('../services/libreTranslateService');
const { normalizeLanguage } = require('./translateController');

async function translateArticleBatch(articles, targetLang) {
    if (!articles || articles.length === 0 || !targetLang || targetLang === 'en') {
        return articles;
    }

    const itemsToTranslate = [];
    const mapping = [];

    articles.forEach((art, artIndex) => {
        if (art.title && typeof art.title === 'string' && art.title.trim()) {
            itemsToTranslate.push(art.title);
            mapping.push({ artIndex, field: 'title' });
        }
        if (art.description && typeof art.description === 'string' && art.description.trim()) {
            itemsToTranslate.push(art.description);
            mapping.push({ artIndex, field: 'description' });
        }
        if (art.aiSummary && typeof art.aiSummary === 'string' && art.aiSummary.trim()) {
            itemsToTranslate.push(art.aiSummary);
            mapping.push({ artIndex, field: 'aiSummary' });
        }
    });

    if (itemsToTranslate.length === 0) return articles;

    try {
        const translatedList = await translateTexts(itemsToTranslate, targetLang);
        mapping.forEach((m, idx) => {
            const trans = translatedList[idx];
            if (trans) {
                if (!articles[m.artIndex].originalTitle && m.field === 'title') {
                    articles[m.artIndex].originalTitle = articles[m.artIndex].title;
                }
                if (!articles[m.artIndex].originalDescription && m.field === 'description') {
                    articles[m.artIndex].originalDescription = articles[m.artIndex].description;
                }
                articles[m.artIndex][m.field] = trans;
            }
        });
    } catch (err) {
        console.error('[Feed Translation Error]:', err.message);
    }

    return articles;
}

async function getFeed(req, res) {
    try {
        const offset = parseInt(req.query.offset) || 0;
        const limit = parseInt(req.query.limit) || 20;
        const topic = req.query.topic;
        const targetLang = normalizeLanguage(req.query.targetLang || req.query.lang);

        if (topic && topic !== 'all') {
            let articles = await Article.find({ topic })
                .sort({ fetchedAt: -1 })
                .skip(offset)
                .limit(limit)
                .lean();

            const total = await Article.countDocuments({ topic });
            articles = await translateArticleBatch(articles, targetLang);

            return res.json({
                articles,
                total,
                hasMore: offset + articles.length < total,
            });
        }

        const topicList = [
            'technology', 'movies', 'usa', 'india', 'japan', 'china',
            'russia', 'sports', 'education', 'politics', 'foreign-relations',
        ];

        const perTopic = 50;
        const topicBuckets = await Promise.all(
            topicList.map(t =>
                Article.find({ topic: t })
                    .sort({ fetchedAt: -1 })
                    .limit(perTopic)
                    .lean()
            )
        );

        const interleaved = [];
        const maxLen = Math.max(...topicBuckets.map(b => b.length));

        for (let i = 0; i < maxLen; i++) {
            for (const bucket of topicBuckets) {
                if (bucket[i]) {
                    interleaved.push(bucket[i]);
                }
            }
        }

        const total = interleaved.length;
        let page = interleaved.slice(offset, offset + limit);
        page = await translateArticleBatch(page, targetLang);

        res.json({
            articles: page,
            total,
            hasMore: offset + page.length < total,
        });
    } catch (err) {
        console.error('[Feed] Error:', err.message);
        res.status(500).json({ error: 'Failed to fetch feed' });
    }
}

async function fetchSummaries(req, res) {
    try {
        const { articleIds } = req.body;
        if (!Array.isArray(articleIds) || articleIds.length === 0) {
            return res.status(400).json({ error: 'articleIds array is required' });
        }

        const articles = await Article.find({ _id: { $in: articleIds } }).lean();

        const needsSummary = articles.filter(a => !a.aiSummary);
        if (needsSummary.length > 0) {
            await Promise.allSettled(
                needsSummary.map(async (article) => {
                    try {
                        const summary = await summarizeArticle(article.title, article.content || article.description);
                        await Article.updateOne(
                            { _id: article._id },
                            { $set: { aiSummary: summary } }
                        );
                        article.aiSummary = summary;
                    } catch {
                        article.aiSummary = null;
                    }
                })
            );
        }

        const updated = await Article.find({ _id: { $in: articleIds } }).lean();
        res.json({ articles: updated });
    } catch (err) {
        console.error('[Feed] Summary error:', err.message);
        res.status(500).json({ error: 'Failed to generate summaries' });
    }
}

async function triggerFetch(req, res) {
    try {
        fetchAllArticles().catch(err => console.error('[Manual Fetch] Error:', err.message));
        res.json({ message: 'Article fetcher started successfully.' });
    } catch (err) {
        console.error('[Manual Fetch] Error:', err.message);
        res.status(500).json({ error: 'Failed to trigger article fetcher' });
    }
}

module.exports = { getFeed, fetchSummaries, triggerFetch };

