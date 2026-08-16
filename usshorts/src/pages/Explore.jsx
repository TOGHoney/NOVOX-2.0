import { useState } from 'react';
import { FiSearch } from 'react-icons/fi';
import NewsCard from '../components/NewsCard';
import NotFound from './NotFound';
import { searchNews } from '../api/newsService';
import useArticleTranslation from '../hooks/useArticleTranslation';
import { useLanguage } from '../context/LanguageContext';

const TOPICS = ['Technology', 'Business', 'Science', 'Health', 'Sports', 'Entertainment'];

export default function Explore() {
    const [searchQuery, setSearchQuery] = useState('');
    const [articles, setArticles] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(false);
    const [hasSearched, setHasSearched] = useState(false);
    const { translations, loading: translating, unavailable } = useArticleTranslation(articles);
    const { targetLanguage } = useLanguage();

    const handleSearch = async (query) => {
        if (!query.trim()) return;
        setLoading(true);
        setError(false);
        setHasSearched(true);
        try {
            const data = await searchNews(query);
            setArticles(data);
        } catch {
            setError(true);
        } finally {
            setLoading(false);
        }
    };

    const handleTopicClick = (topic) => {
        setSearchQuery(topic);
        handleSearch(topic);
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        handleSearch(searchQuery);
    };

    if (error) return <NotFound />;

    return (
        <div className="explore-page" style={{ padding: '2rem', maxWidth: '1200px', margin: '0 auto' }}>
            <div className="section-head" style={{ marginBottom: '2rem' }}>
                <div>
                    <p className="eyebrow">Explore Topics</p>
                    <h2>Search news and get AI summaries</h2>
                </div>
            </div>

            <form onSubmit={handleSubmit} className="search-container" style={{ marginBottom: '2rem', display: 'flex', gap: '1rem' }}>
                <div className="search-box" style={{ flex: 1, display: 'flex', alignItems: 'center', background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: '12px', padding: '0.75rem 1rem' }}>
                    <FiSearch style={{ marginRight: '0.75rem', color: 'var(--text-muted)' }} />
                    <input
                        type="text"
                        placeholder="Search topics, keywords, or news..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        style={{ background: 'none', border: 'none', color: 'var(--text)', width: '100%', outline: 'none', fontSize: '1rem' }}
                    />
                </div>
                <button type="submit" className="primary-btn">Search</button>
            </form>

            <div className="topics-section" style={{ marginBottom: '3rem' }}>
                <h3 style={{ marginBottom: '1rem', fontSize: '1.2rem' }}>Browse Topics</h3>
                <div className="topic-wrap" style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
                    {TOPICS.map((topic) => (
                        <button
                            key={topic}
                            onClick={() => handleTopicClick(topic)}
                            className="topic-chip"
                            style={{
                                padding: '0.5rem 1.25rem',
                                borderRadius: '20px',
                                border: '1px solid var(--border)',
                                background: searchQuery === topic ? 'var(--primary)' : 'var(--bg-card)',
                                color: searchQuery === topic ? 'white' : 'var(--text)',
                                cursor: 'pointer',
                                transition: 'all 0.2s ease',
                                fontWeight: 500,
                            }}
                        >
                            {topic}
                        </button>
                    ))}
                </div>
            </div>

            <div className="results-section">
                {loading ? (
                    <div style={{ textAlign: 'center', padding: '3rem' }}>
                        <p style={{ opacity: 0.5 }}>Searching news...</p>
                    </div>
                ) : hasSearched ? (
                    <>
                        <h3 style={{ marginBottom: '1.5rem', fontSize: '1.2rem' }}>
                            Results for "{searchQuery}" ({articles.length})
                        </h3>
                        {articles.length > 0 ? (
                            <div className="news-list" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.5rem' }}>
                                {(translating || unavailable) && targetLanguage !== 'en' && (
                                    <div style={{ fontSize: '0.85rem', opacity: 0.7, gridColumn: '1 / -1' }}>
                                        {unavailable
                                            ? 'Translation service unavailable — showing original text.'
                                            : `Translating results to ${targetLanguage.toUpperCase()}...`}
                                    </div>
                                )}
                                {articles.map((article) => (
                                    <NewsCard
                                        key={article.id}
                                        article={article}
                                        activeId={null}
                                        onSelect={() => { }}
                                        translation={translations[article.id] || null}
                                    />
                                ))}
                            </div>
                        ) : (
                            <div style={{ textAlign: 'center', padding: '3rem', background: 'var(--bg-card)', borderRadius: '16px', border: '1px solid var(--border)' }}>
                                <p style={{ color: 'var(--text-muted)', fontSize: '1.1rem' }}>No articles found for this search.</p>
                            </div>
                        )}
                    </>
                ) : (
                    <div style={{ textAlign: 'center', padding: '3rem', background: 'var(--bg-card)', borderRadius: '16px', border: '1px solid var(--border)' }}>
                        <p style={{ color: 'var(--text-muted)', fontSize: '1.1rem' }}>Use the search bar or pick a topic to explore news.</p>
                    </div>
                )}
            </div>
        </div>
    );
}
