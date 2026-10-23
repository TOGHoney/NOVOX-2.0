const { translateTexts, BASE_URL } = require('../services/libreTranslateService');

const LANGUAGE_NAME_TO_CODE = {
    spanish: 'es',
    french: 'fr',
    german: 'de',
    japanese: 'ja',
    thai: 'th',
    english: 'en',
    hindi: 'hi',
    es: 'es',
    fr: 'fr',
    de: 'de',
    ja: 'ja',
    th: 'th',
    en: 'en',
    hi: 'hi'
};

const SUPPORTED_LANGUAGES = ['en', 'es', 'fr', 'de', 'ja', 'th', 'hi'];

function normalizeLanguage(lang) {
    if (!lang || typeof lang !== 'string') return null;
    const clean = lang.trim().toLowerCase().split(' ')[0].replace(/[^a-z]/g, '');
    return LANGUAGE_NAME_TO_CODE[clean] || (SUPPORTED_LANGUAGES.includes(clean) ? clean : null);
}

async function translate(req, res) {
    const { texts, target, source = 'auto' } = req.body || {};

    if (!Array.isArray(texts) || texts.length === 0) {
        return res.status(400).json({ error: 'An array of texts is required' });
    }

    const normTarget = normalizeLanguage(target);
    if (!normTarget || !SUPPORTED_LANGUAGES.includes(normTarget)) {
        return res.status(400).json({ error: `Unsupported target language: ${target}. Allowed: ${SUPPORTED_LANGUAGES.join(', ')}` });
    }

    const cleaned = texts.map((text) => (typeof text === 'string' ? text : '')).filter((text) => text.trim().length > 0);
    if (cleaned.length === 0) {
        return res.json({ translations: [] });
    }

    try {
        const translations = await translateTexts(cleaned, normTarget, source);
        return res.json({ translations, serviceUrl: BASE_URL });
    } catch (err) {
        console.error('Translate error:', err.message);
        return res.status(503).json({ error: 'Translation service unavailable' });
    }
}

module.exports = { translate, normalizeLanguage };

