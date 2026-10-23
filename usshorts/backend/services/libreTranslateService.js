const BASE_URL = process.env.LIBRETRANSLATE_URL || 'http://localhost:5002';
const TIMEOUT_MS = 5000;

const cache = new Map();
const CACHE_TTL = 24 * 60 * 60 * 1000; // 24-hour cache

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

async function translateViaGoogle(text, target, source = 'auto') {
    if (!text || typeof text !== 'string' || !text.trim()) return '';
    try {
        const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${encodeURIComponent(source)}&tl=${encodeURIComponent(target)}&dt=t&q=${encodeURIComponent(text)}`;
        const res = await fetch(url);
        if (!res.ok) throw new Error(`Google translate HTTP ${res.status}`);
        const data = await res.json();
        if (Array.isArray(data) && Array.isArray(data[0])) {
            return data[0].map(part => part[0] || '').join('');
        }
    } catch (e) {
        console.error('[Translation Fallback Error]:', e.message);
    }
    return text;
}

let lastLibreFailure = 0;
const LIBRE_COOLDOWN_MS = 5 * 60 * 1000; // Wait 5 mins before retrying down LibreTranslate

async function translateTexts(texts, target, source = 'auto') {
    const results = new Array(texts.length);
    const missing = [];

    for (let i = 0; i < texts.length; i++) {
        const text = texts[i];
        const cacheKey = `${source}:${target}:${text}`;
        const cached = getCached(cacheKey);
        if (cached !== null) {
            results[i] = cached;
        } else {
            missing.push({ index: i, text, cacheKey });
        }
    }

    if (missing.length > 0) {
        let translatedList = null;

        // 1. Attempt local LibreTranslate if not in cooldown
        if (Date.now() - lastLibreFailure > LIBRE_COOLDOWN_MS) {
            try {
                const controller = new AbortController();
                const timeout = setTimeout(() => controller.abort(), 600);

                const response = await fetch(`${BASE_URL}/translate`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        q: missing.map((item) => item.text),
                        source,
                        target,
                        format: 'text',
                    }),
                    signal: controller.signal,
                });
                clearTimeout(timeout);

                if (response.ok) {
                    const data = await response.json();
                    const list = Array.isArray(data) ? data : data.translatedText ?? data.translatedTexts;
                    if (Array.isArray(list) && list.length === missing.length) {
                        translatedList = list;
                    }
                } else {
                    lastLibreFailure = Date.now();
                }
            } catch (err) {
                lastLibreFailure = Date.now();
            }
        }

        // 2. High-availability fallback via Google Translate API
        if (!translatedList) {
            translatedList = await Promise.all(
                missing.map(item => translateViaGoogle(item.text, target, source))
            );
        }

        for (let j = 0; j < missing.length; j++) {
            const translated = translatedList[j] ?? missing[j].text;
            setCache(missing[j].cacheKey, translated);
            results[missing[j].index] = translated;
        }
    }

    return results;
}

module.exports = { translateTexts, BASE_URL };

