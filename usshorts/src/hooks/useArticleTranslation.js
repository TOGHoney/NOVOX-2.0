import { useEffect, useState } from 'react';
import { translateTexts } from '../api/translateService';
import { useLanguage } from '../context/LanguageContext';

const FIELDS = ['title', 'description', 'aiSummary', 'content'];

export default function useArticleTranslation(articles) {
    const { targetLanguage } = useLanguage();
    const [translations, setTranslations] = useState({});
    const [loading, setLoading] = useState(false);
    const [unavailable, setUnavailable] = useState(false);

    useEffect(() => {
        setTranslations({});
        setUnavailable(false);

        if (targetLanguage === 'en' || !articles || articles.length === 0) {
            setLoading(false);
            return;
        }

        let cancelled = false;
        setLoading(true);

        const texts = [];
        const meta = [];
        articles.forEach((article) => {
            const articleId = article._id || article.id;
            FIELDS.forEach((field) => {
                const value = article[field];
                if (value && typeof value === 'string' && value.trim()) {
                    texts.push(value);
                    meta.push({ id: articleId, field });
                }
            });
        });

        if (texts.length === 0) {
            setLoading(false);
            return;
        }

        translateTexts(texts, targetLanguage)
            .then((translatedList) => {
                if (cancelled) return;
                const next = {};
                meta.forEach((item, i) => {
                    next[item.id] = {
                        ...(next[item.id] || {}),
                        [item.field]: translatedList[i] || '',
                    };
                });
                setTranslations(next);
            })
            .catch(() => {
                if (!cancelled) setUnavailable(true);
            })
            .finally(() => {
                if (!cancelled) setLoading(false);
            });

        return () => {
            cancelled = true;
        };
    }, [articles, targetLanguage]);

    return { translations, loading, unavailable };
}
