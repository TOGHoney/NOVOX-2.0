const { translateTexts, BASE_URL } = require('../services/libreTranslateService');
const { explainWordIntelligence } = require('../services/geminiService');

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
    const normSource = normalizeLanguage(source) || 'auto';
    if (!normTarget || !SUPPORTED_LANGUAGES.includes(normTarget)) {
        return res.status(400).json({ error: `Unsupported target language: ${target}. Allowed: ${SUPPORTED_LANGUAGES.join(', ')}` });
    }

    const cleaned = texts.map((text) => (typeof text === 'string' ? text : '')).filter((text) => text.trim().length > 0);
    if (cleaned.length === 0) {
        return res.json({ translations: [] });
    }

    try {
        const translations = await translateTexts(cleaned, normTarget, normSource);
        return res.json({ translations, serviceUrl: BASE_URL });
    } catch (err) {
        console.error('Translate error:', err.message);
        return res.status(503).json({ error: 'Translation service unavailable' });
    }
}

/**
 * Controller for Word Intelligence:
 * Provides context-aware translation, base-language contextual meaning,
 * target-language pronunciation guidance, and dictionary definitions.
 */
async function wordIntelligence(req, res) {
    const { expression, sentence, baseLanguage = 'en', targetLanguage = 'es', cefrLevel = 'B1' } = req.body || {};

    if (!expression || typeof expression !== 'string' || !expression.trim()) {
        return res.status(400).json({ error: 'Selected expression is required' });
    }

    const cleanExpression = expression.trim();
    const cleanSentence = typeof sentence === 'string' ? sentence.trim() : '';
    const normBase = normalizeLanguage(baseLanguage) || 'en';
    const normTarget = normalizeLanguage(targetLanguage) || 'es';
    const cleanCefr = (typeof cefrLevel === 'string' && cefrLevel.trim()) ? cefrLevel.trim().toUpperCase() : 'B1';
    const isBeginnerOrIntermediate = ['A1', 'A2', 'B1'].includes(cleanCefr);

    // 1. Try Gemini pedagogical AI service
    try {
        const aiResult = await explainWordIntelligence({
            expression: cleanExpression,
            sentence: cleanSentence,
            baseLanguage: normBase,
            targetLanguage: normTarget,
            cefrLevel: cleanCefr
        });

        return res.json({
            originalExpression: aiResult.originalExpression || cleanExpression,
            translation: aiResult.translation || '',
            targetExpression: aiResult.targetExpression || (isBeginnerOrIntermediate ? aiResult.translation : cleanExpression),
            pronunciationGuide: aiResult.pronunciationGuide || null,
            contextualMeaning: aiResult.contextualMeaning || null,
            dictionaryDefinition: aiResult.dictionaryDefinition || null,
            partOfSpeech: aiResult.partOfSpeech || 'term',
            detectedCefr: aiResult.detectedCefr || cleanCefr,
            isSentence: Boolean(aiResult.isSentence),
            targetLanguageCode: normTarget,
            baseLanguageCode: normBase
        });
    } catch (aiErr) {
        console.warn('Word intelligence Gemini AI fallback due to:', aiErr.message);

        // 2. Resilient fallback using LibreTranslate / Translation service
        try {
            const transSource = isBeginnerOrIntermediate ? normBase : normTarget;
            const transDest = isBeginnerOrIntermediate ? normTarget : normBase;
            const translatedArr = await translateTexts([cleanExpression], transDest, transSource);
            const fallbackTrans = (translatedArr && translatedArr[0]) ? translatedArr[0] : cleanExpression;

            const targetExpr = isBeginnerOrIntermediate ? fallbackTrans : cleanExpression;

            return res.json({
                originalExpression: cleanExpression,
                translation: fallbackTrans,
                targetExpression: targetExpr,
                pronunciationGuide: null,
                contextualMeaning: `In this sentence, '${cleanExpression}' translates to '${fallbackTrans}'.`,
                dictionaryDefinition: null,
                partOfSpeech: cleanExpression.includes(' ') ? 'phrase' : 'term',
                detectedCefr: cleanCefr,
                isSentence: cleanExpression.split(/\s+/).length > 3,
                targetLanguageCode: normTarget,
                baseLanguageCode: normBase
            });
        } catch (fallbackErr) {
            console.error('Word intelligence fallback translation failed:', fallbackErr.message);
            return res.status(500).json({ error: 'Word intelligence service temporarily unavailable' });
        }
    }
}

module.exports = { translate, wordIntelligence, normalizeLanguage };


