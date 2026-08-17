import { useState } from 'react';
import { FiSearch, FiX, FiExternalLink } from 'react-icons/fi';
import NotFound from './NotFound';
import { searchNews } from '../api/newsService';
import useArticleTranslation from '../hooks/useArticleTranslation';
import { useLanguage } from '../context/LanguageContext';

export default function Explore({ isOpen, onClose, onSelectArticle }) {
  const [searchQuery, setSearchQuery] = useState('');
  const [articles, setArticles] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);
  
  // Custom hook for translation lookup
  const { translations, loading: translating, unavailable } = useArticleTranslation(articles);
  const { targetLanguage } = useLanguage();

  const handleSearch = async (query) => {
    if (!query.trim()) return;
    setLoading(true);
    setError(false);
    setHasSearched(true);
    try {
      const data = await searchNews(query);
      setArticles(data || []);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    handleSearch(searchQuery);
  };

  const handleArticleClick = (article) => {
    // Merge translated title & summary if available before selecting
    const translation = translations[article.id];
    const translatedArticle = translation
      ? {
          ...article,
          title: translation.title || article.title,
          summary: translation.summary || article.summary,
          translated: true,
        }
      : article;

    if (onSelectArticle) {
      onSelectArticle(translatedArticle);
    }
    if (onClose) {
      onClose();
    }
  };

  if (error) return <NotFound />;

  return (
    <>
      {/* Styles to make scrollbars completely invisible */}
      <style>{`
        .explore-scroll-area::-webkit-scrollbar {
          display: none;
          width: 0px;
          background: transparent;
        }
        .explore-scroll-area {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>

      <aside
        style={{
          position: 'fixed',
          top: 0,
          left: isOpen ? '72px' : '-360px',
          width: '360px',
          height: '100vh',
          backgroundColor: 'var(--bg-card, #ffffff)',
          borderRight: isOpen ? '1px solid var(--border, #e2e8f0)' : 'none',
          display: 'flex',
          flexDirection: 'column',
          boxSizing: 'border-box',
          overflow: 'hidden',
          transition: 'left 0.3s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.3s ease',
          opacity: isOpen ? 1 : 0,
          zIndex: 100,
          pointerEvents: isOpen ? 'auto' : 'none'
        }}
      >
        <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
          {/* Header */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '1.25rem 1.25rem 0.75rem 1.25rem',
              flexShrink: 0
            }}
          >
            <h2 style={{ margin: 0, fontSize: '1.35rem', fontWeight: 800, color: 'var(--text, #0f172a)' }}>
              Explore
            </h2>
            <button
              onClick={onClose}
              style={{
                border: 'none',
                background: 'var(--bg, #f1f5f9)',
                borderRadius: '50%',
                width: '34px',
                height: '34px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                color: 'var(--text-muted, #475569)'
              }}
            >
              <FiX size={18} />
            </button>
          </div>

          {/* Search Input */}
          <form onSubmit={handleSubmit} style={{ padding: '0 1.25rem 1rem 1.25rem', flexShrink: 0 }}>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                background: 'var(--bg, #f1f5f9)',
                borderRadius: '24px',
                padding: '0.65rem 1rem',
                border: '1px solid var(--border, #cbd5e1)'
              }}
            >
              <FiSearch size={18} style={{ color: 'var(--text-muted, #64748b)', marginRight: '0.6rem' }} />
              <input
                type="text"
                placeholder="Search topics, keywords, or news..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  background: 'transparent',
                  border: 'none',
                  color: 'var(--text, #0f172a)',
                  width: '100%',
                  outline: 'none',
                  fontSize: '0.9rem'
                }}
              />
            </div>
          </form>

          {/* Scrollable Content Area */}
          <div 
            className="explore-scroll-area"
            style={{ 
              flex: 1, 
              overflowY: 'auto', 
              padding: '0 1.25rem 1.25rem 1.25rem',
              boxSizing: 'border-box',
              display: 'flex',
              flexDirection: 'column'
            }}
          >
            <div className="results-section" style={{ marginTop: '0.5rem', flex: 1, display: 'flex', flexDirection: 'column' }}>
              {loading ? (
                <div style={{ textAlign: 'center', padding: '2rem' }}>
                  <p style={{ color: 'var(--text-muted, #64748b)', fontSize: '0.85rem' }}>Searching news...</p>
                </div>
              ) : hasSearched ? (
                <>
                  <h3 style={{ marginBottom: '0.75rem', fontSize: '0.9rem', fontWeight: 700, color: 'var(--text, #0f172a)' }}>
                    Top 5 Results for "{searchQuery}"
                  </h3>

                  {/* Translation Loader/Fallback Status */}
                  {targetLanguage !== 'en' && (
                    <div style={{ fontSize: '0.78rem', opacity: 0.7, marginBottom: '0.75rem', color: 'var(--text-muted)' }}>
                      {translating
                        ? `Translating results to ${targetLanguage.toUpperCase()}...`
                        : unavailable
                        ? 'Translation service unavailable — showing original text.'
                        : null}
                    </div>
                  )}

                  {articles.length > 0 ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                      {articles.slice(0, 5).map((article) => {
                        const translatedObj = translations[article.id];
                        const displayTitle = translatedObj?.title || article.title;
                        const displaySummary = translatedObj?.summary || article.summary;

                        return (
                          <div
                            key={article.id || article.url}
                            style={{
                              padding: '0.85rem 1rem',
                              borderRadius: '12px',
                              background: 'var(--bg, #f8fafc)',
                              border: '1px solid var(--border, #e2e8f0)',
                              display: 'flex',
                              flexDirection: 'column',
                              gap: '0.5rem'
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: '0.75rem' }}>
                              <h4
                                style={{
                                  margin: 0,
                                  fontSize: '0.88rem',
                                  fontWeight: 600,
                                  lineHeight: '1.35',
                                  color: 'var(--text, #0f172a)'
                                }}
                              >
                                {displayTitle}
                              </h4>
                              <button
                                onClick={() => handleArticleClick(article)}
                                title="Open full article"
                                style={{
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  padding: '0.35rem',
                                  borderRadius: '6px',
                                  background: 'var(--bg-card, #ffffff)',
                                  border: '1px solid var(--border, #cbd5e1)',
                                  color: 'var(--primary, #800020)',
                                  cursor: 'pointer',
                                  flexShrink: 0
                                }}
                              >
                                <FiExternalLink size={14} />
                              </button>
                            </div>

                            {/* Optional short preview of translated summary */}
                            {displaySummary && (
                              <p
                                style={{
                                  margin: 0,
                                  fontSize: '0.78rem',
                                  color: 'var(--text-muted, #64748b)',
                                  display: '-webkit-box',
                                  WebkitLineClamp: 2,
                                  WebkitBoxOrient: 'vertical',
                                  overflow: 'hidden'
                                }}
                              >
                                {displaySummary}
                              </p>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  ) : (
                    <div style={{ textAlign: 'center', padding: '2rem', background: 'var(--bg, #f8fafc)', borderRadius: '12px' }}>
                      <p style={{ color: 'var(--text-muted, #64748b)', fontSize: '0.85rem', margin: 0 }}>
                        No articles found for this search.
                      </p>
                    </div>
                  )}
                </>
              ) : (
                <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', paddingBottom: '12rem' }}>
                  <p
                    style={{
                      color: '#800020',
                      fontWeight: 400,
                      fontSize: '0.85rem',
                      textAlign: 'center',
                      margin: 0
                    }}
                  >
                    search news you heard about
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </aside>
    </>
  );
}