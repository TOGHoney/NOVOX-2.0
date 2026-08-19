const Article = require('../models/Article');
const { summarizeArticle } = require('../services/geminiService');
const { fetchAllArticles } = require('../services/articleFetcher');

async function getFeed(req, res) {
    try {
        const offset = parseInt(req.query.offset) || 0;
        const limit = parseInt(req.query.limit) || 20;
        const topic = req.query.topic;

        if (topic && topic !== 'all') {
            const articles = await Article.find({ topic })
                .sort({ fetchedAt: -1 })
                .skip(offset)
                .limit(limit)
                .lean();

            const total = await Article.countDocuments({ topic });

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
        const page = interleaved.slice(offset, offset + limit);

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

