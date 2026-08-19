import { useState, useEffect, useRef, useCallback } from 'react';
import { useOutletContext } from 'react-router-dom';
import NotFound from './NotFound';
import { fetchFeed, fetchSummaries } from '../api/feedService';
import {
  FiExternalLink,
  FiChevronDown,
  FiChevronUp,
  FiZap,
  FiArrowLeft,
  FiX,
  FiMessageSquare
} from 'react-icons/fi';
import {
  CATEGORIES,
  analyzeWordContext,
  fetchDatamuseConcepts,
  evaluateContextConfidence,
  deriveWordForms,
  estimateCEFR
} from '../utils/articleUtils';
import useArticleTranslation from '../hooks/useArticleTranslation';
import { useLanguage } from '../context/LanguageContext';
import { InteractiveText, WordIntelligencePanel } from '../components/WordIntelligence';
import CommentSidebar from '../components/CommentSidebar';
import BookmarkButton from '../components/BookmarkButton';

export default function Articles() {
  const [viewMode, setViewMode] = useState('feed');
  const [articles, setArticles] = useState([]);
  const [offset, setOffset] = useState(0);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [error, setError] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [activeArticle, setActiveArticle] = useState(null);
  const [expandedSummaries, setExpandedSummaries] = useState({});
  const [summaryLoading, setSummaryLoading] = useState({});
  
  // Extracted Full Text State
  const [extractedArticle, setExtractedArticle] = useState(null);
  const [fetchingFullText, setFetchingFullText] = useState(false);
  const [fetchError, setFetchError] = useState(false);

  // Word Intelligence State
  const [targetLang, setTargetLang] = useState('hi');
  const [selectedWord, setSelectedWord] = useState('');
  const [contextSentence, setContextSentence] = useState('');
  const [translation, setTranslation] = useState('');
  const [wordDetails, setWordDetails] = useState(null);
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [showOverlay, setShowOverlay] = useState(false);

  // Floating Comments State
  const [showComments, setShowComments] = useState(false);

  // Article Translation
  const { translations, loading: translating, unavailable } = useArticleTranslation(articles);
  const { targetLanguage } = useLanguage();

  // Outlet context from AppLayout (handles opening full article directly from Explore)
  const outletContext = useOutletContext();
  const selectedArticleFromExplore = outletContext?.selectedArticle;

  const handleOpenFullArticle = useCallback((article) => {
    setActiveArticle(article);
    setViewMode('full');
  }, []);

  // Sync selected article from Explore drawer to open in full local reader view
  useEffect(() => {
    if (selectedArticleFromExplore) {
      handleOpenFullArticle(selectedArticleFromExplore);
    }
  }, [selectedArticleFromExplore, handleOpenFullArticle]);

  useEffect(() => {
    if (viewMode === 'full' && activeArticle?.url) {
      setFetchingFullText(true);
      setFetchError(false);
      setExtractedArticle(null);
      fetch(`http://localhost:5000/api/extract-article?url=${encodeURIComponent(activeArticle.url)}`)
        .then((res) => {
          if (!res.ok) throw new Error('Extraction failed');
          return res.json();
        })
        .then((data) => setExtractedArticle(data))
        .catch(() => setFetchError(true))
        .finally(() => setFetchingFullText(false));
    }
  }, [viewMode, activeArticle]);

  useEffect(() => {
    let isMounted = true;
    setLoading(true);
    setError(false);
    setOffset(0);
    fetchFeed(0, 20, selectedCategory)
      .then((data) => {
        if (!isMounted) return;
        const safeData = data?.articles || [];
        setArticles(safeData);
        if (safeData.length > 0 && !selectedArticleFromExplore) {
          setActiveArticle(safeData[0]);
        }
        setHasMore(data?.hasMore ?? false);
      })
      .catch(() => {
        if (isMounted) setError(true);
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });
    return () => {
      isMounted = false;
    };
  }, [selectedCategory]);

  const loadMoreArticles = useCallback(() => {
    if (loadingMore || !hasMore) return;
    setLoadingMore(true);
    const nextOffset = articles.length;
    fetchFeed(nextOffset, 20, selectedCategory)
      .then((data) => {
        const newArticles = data?.articles || [];
        if (newArticles.length === 0) {
          setHasMore(false);
        } else {
          setArticles((prev) => [...prev, ...newArticles]);
          setOffset(nextOffset);
          setHasMore(data?.hasMore ?? false);
        }
      })
      .catch(() => {
        setHasMore(false);
      })
      .finally(() => setLoadingMore(false));
  }, [selectedCategory, articles.length, loadingMore, hasMore]);

  const observer = useRef(null);
  const lastArticleElementRef = useCallback(
    (node) => {
      if (loading || loadingMore) return;
      if (observer.current) observer.current.disconnect();
      observer.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && hasMore) {
          loadMoreArticles();
        }
      });
      if (node) observer.current.observe(node);
    },
    [loading, loadingMore, hasMore, loadMoreArticles]
  );

  const toggleSummary = async (articleId) => {
    const isCurrentlyExpanded = expandedSummaries[articleId];

    if (isCurrentlyExpanded) {
      setExpandedSummaries(prev => ({ ...prev, [articleId]: false }));
      return;
    }

    setExpandedSummaries(prev => ({ ...prev, [articleId]: true }));

    const article = articles.find(a => (a._id || a.id || a.url) === articleId);
    if (article && !article.aiSummary) {
      setSummaryLoading(prev => ({ ...prev, [articleId]: true }));
      try {
        const result = await fetchSummaries([article._id || article.id]);
        if (result?.articles?.length > 0) {
          const updated = result.articles[0];
          setArticles(prev =>
            prev.map(a =>
              (a._id || a.id) === articleId ? { ...a, aiSummary: updated.aiSummary } : a
            )
          );
          if (activeArticle && (activeArticle._id || activeArticle.id) === articleId) {
            setActiveArticle(prev => ({ ...prev, aiSummary: updated.aiSummary }));
          }
        }
      } catch {
        // Summary generation failed — leave aiSummary as null
      } finally {
        setSummaryLoading(prev => ({ ...prev, [articleId]: false }));
      }
    }
  };

  const playSpeechFallback = useCallback((wordToSpeak) => {
    if ('speechSynthesis' in window && wordToSpeak) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(wordToSpeak);
      utterance.lang = 'en-US';
      window.speechSynthesis.speak(utterance);
    }
  }, []);

  const playAudio = (audioUrl) => {
    if (audioUrl) {
      const audio = new Audio(audioUrl);
      audio.play().catch(() => playSpeechFallback(selectedWord));
    } else {
      playSpeechFallback(selectedWord);
    }
  };


  const activeAbortController = useRef(null);
  const fetchWordIntelligence = async (selectedText, langCode, sentence = '') => {
    if (activeAbortController.current) {
      activeAbortController.current.abort();
    }
    activeAbortController.current = new AbortController();
    const { signal } = activeAbortController.current;

    setDetailsLoading(true);
    setWordDetails(null);
    setTranslation('');

    const cleanWord = selectedText.trim().replace(/[^a-zA-Z]/g, '').toLowerCase();
    if (!cleanWord) {
      setDetailsLoading(false);
      return;
    }

    const contextAnalysis = analyzeWordContext(cleanWord, sentence);
    const detectedPOS = contextAnalysis.pos;
    const lookupWord = contextAnalysis.lemma;

    try {
      const translationPromise = fetch(
        `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=${langCode}&dt=t&q=${encodeURIComponent(lookupWord)}`,
        { signal }
      ).then(res => res.json()).then(data => data[0]?.[0]?.[0]).catch(() => lookupWord);

      const conceptsPromise = fetchDatamuseConcepts(lookupWord, signal);

      const [translatedText, semanticConcepts] = await Promise.all([translationPromise, conceptsPromise]);

      if (!signal.aborted && translatedText) {
        setTranslation(translatedText);
      }

      let phoneticText = '';
      let audioUrl = '';
      let meaningsList = [];
      let synonymsSet = new Set(semanticConcepts.slice(0, 5));
      let antonymsSet = new Set();

      try {
        const dictRes = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${lookupWord}`, { signal });
        if (dictRes.ok) {
          const dictData = await dictRes.json();
          const entry = dictData[0];
          phoneticText = entry.phonetic || (entry.phonetics && entry.phonetics.find(p => p.text)?.text) || '';
          const audioObj = entry.phonetics?.find(p => p.audio && p.audio.trim() !== '');
          if (audioObj) audioUrl = audioObj.audio;

          if (entry.meanings && entry.meanings.length > 0) {
            entry.meanings.forEach((m) => {
              const defsObj = (m.definitions || []).map(d => {
                const evalResult = evaluateContextConfidence(sentence, d.definition, detectedPOS, m.partOfSpeech, semanticConcepts);
                return {
                  definition: d.definition,
                  example: d.example || null,
                  score: evalResult.score,
                  confidence: evalResult.confidence
                };
              });

              defsObj.sort((a, b) => b.score - a.score);

              meaningsList.push({
                partOfSpeech: m.partOfSpeech.toLowerCase(),
                definitions: defsObj
              });

              if (m.synonyms) m.synonyms.forEach(s => synonymsSet.add(s));
              if (m.antonyms) m.antonyms.forEach(a => antonymsSet.add(a));
            });
          }
        }
      } catch (err) {
        if (err.name === 'AbortError') return;
      }

      let primaryMeanings = meaningsList.filter(
        (m) => m.partOfSpeech.toLowerCase() === detectedPOS.toLowerCase()
      );

      let actualPOS = detectedPOS;
      let confidencePenalty = 0;

      if (primaryMeanings.length === 0 && meaningsList.length > 0) {
        primaryMeanings = [meaningsList[0]];
        actualPOS = meaningsList[0].partOfSpeech;
        confidencePenalty = 20;
      }

      const remainingMeanings = meaningsList.filter(
        (m) => !primaryMeanings.includes(m)
      );

      const baseConfidence = primaryMeanings[0]?.definitions[0]?.confidence || 75;
      const finalConfidence = Math.max(40, baseConfidence - confidencePenalty);

      if (!signal.aborted) {
        setWordDetails({
          phonetic: phoneticText || `/${lookupWord}/`,
          audioUrl: audioUrl,
          lemma: lookupWord,
          detectedPOS: actualPOS,
          confidenceScore: finalConfidence,
          primaryMeanings: primaryMeanings,
          otherMeanings: remainingMeanings,
          synonyms: Array.from(synonymsSet).slice(0, 6),
          antonyms: Array.from(antonymsSet).slice(0, 6),
          cefr: estimateCEFR(lookupWord),
          wordForms: deriveWordForms(lookupWord, meaningsList)
        });
      }
    } catch (err) {
      if (err.name !== 'AbortError') {
        console.error('Word Intelligence error:', err);
      }
    } finally {
      if (!signal.aborted) {
        setDetailsLoading(false);
      }
    }
  };

  const handleWordSelect = (word, sentence = '') => {
    setSelectedWord(word);
    setContextSentence(sentence);
    setShowOverlay(true);
    fetchWordIntelligence(word, targetLang, sentence);
  };

  const handleLangChange = (e) => {
    const newLang = e.target.value;
    setTargetLang(newLang);
    if (selectedWord) {
      fetchWordIntelligence(selectedWord, newLang, contextSentence);
    }
  };
 const handleSaveWord = async (wordData) => {
    try {
      let token = localStorage.getItem('token') || localStorage.getItem('jwt');
      if (!token) {
        const stored = localStorage.getItem('user');
        if (stored) token = JSON.parse(stored).token;
      }

      const res = await fetch('http://localhost:5000/api/saved-words', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token && { Authorization: `Bearer ${token}` })
        },
        body: JSON.stringify(wordData)
      });

      if (!res.ok) {
        console.error('Failed to save word to backend:', res.statusText);
      }
    } catch (err) {
      console.error('Error saving word:', err);
    }
  };
  // -----------------------------------------------------------
  const handleSaveWord = useCallback(async (payload) => {
  const wordToSave = payload?.word || selectedWord;
  if (!wordToSave) return;

  // Retrieve auth token from localStorage
  let token = localStorage.getItem('token') || localStorage.getItem('jwt');
  if (!token) {
    const storedUser = localStorage.getItem('user');
    if (storedUser) {
      try {
        const parsedUser = JSON.parse(storedUser);
        token = parsedUser.token || parsedUser.jwt;
      } catch (e) {
        console.error('Failed to parse user token:', e);
      }
    }
  }

  const wordPayload = {
    word: wordToSave,
    translation: payload?.translation || translation || '',
    contextSentence: payload?.contextSentence || contextSentence || '',
    phonetic: payload?.phonetic || wordDetails?.phonetic || '',
    pos: wordDetails?.detectedPOS || '',
    definition: payload?.definition || wordDetails?.primaryMeanings?.[0]?.definitions?.[0]?.definition || '',
    cefr: payload?.cefr || wordDetails?.cefr || 'B1'
  };

  try {
    const response = await fetch('http://localhost:5000/api/saved-words', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` })
      },
      body: JSON.stringify(wordPayload)
    });

    if (!response.ok) {
      console.error('Failed to save word:', response.statusText);
    }
  } catch (error) {
    console.error('Failed to auto-save word:', error);
  }
}, [selectedWord, translation, contextSentence, wordDetails]);

  if (error) return <NotFound />;

  return (
    <div style={{ maxWidth: '1350px', margin: '0 auto', padding: '0.75rem 1rem', height: '100vh', overflow: 'hidden', boxSizing: 'border-box' }}>
      
      {/* DRAGGABLE & RESIZABLE CONTEXTUAL COMMENTS SIDEBAR */}
      <CommentSidebar
        showComments={showComments}
        setShowComments={setShowComments}
        articleUrl={activeArticle?.url}
      />

      {/* PAGE 1: FEED VIEW */}
      {viewMode === 'feed' && (
        <div style={{ height: '100%', display: 'flex', flexDirection: 'column', position: 'relative' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
            <h2 style={{ margin: 0, fontSize: '1.25rem', fontWeight: 800, color: '#0f172a' }}>TODAY'S GLOBAL FEED</h2>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <button
                onClick={() => setViewMode('fast_feed')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.4rem',
                  background: '#800020',
                  color: '#fff',
                  border: 'none',
                  padding: '0.45rem 0.9rem',
                  borderRadius: '8px',
                  fontWeight: 600,
                  fontSize: '0.8rem',
                  cursor: 'pointer'
                }}
              >
                <FiZap size={14} /> Fast Feed
              </button>
            </div>
          </div>

          <div style={{ marginBottom: '0.75rem', display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
            {CATEGORIES.map((cat) => (
              <button
                key={cat.value}
                onClick={() => setSelectedCategory(cat.value)}
                style={{
                  padding: '0.25rem 0.75rem',
                  fontSize: '0.78rem',
                  borderRadius: '16px',
                  border: '1px solid #cbd5e1',
                  background: selectedCategory === cat.value ? '#800020' : '#fff',
                  color: selectedCategory === cat.value ? '#fff' : '#475569',
                  cursor: 'pointer'
                }}
              >
                {cat.label}
              </button>
            ))}
          </div>

          {(translating || unavailable) && targetLanguage !== 'en' && (
            <div style={{ marginBottom: '0.75rem', fontSize: '0.85rem', opacity: 0.7 }}>
              {unavailable
                ? 'Translation service unavailable — showing original text.'
                : `Translating to ${targetLanguage.toUpperCase()}...`}
            </div>
          )}

          <main style={{ flex: 1, overflowY: 'auto', paddingRight: '6px' }}>
            {loading ? (
              <div style={{ textAlign: 'center', padding: '2rem', color: '#64748b' }}>Loading articles...</div>
            ) : (
              articles.map((article, index) => {
                const isLast = index === articles.length - 1;
                const articleId = article._id || article.url || index;
                const isExpanded = !!expandedSummaries[articleId];
                const isLoadingSummary = !!summaryLoading[articleId];
                const imageUrl = article.urlToImage || article.image || article.imageUrl;
                const translation = translations[article._id || article.id];

                return (
                  <div key={articleId} ref={isLast ? lastArticleElementRef : null} style={{ background: '#fff', borderRadius: '12px', padding: '1rem', marginBottom: '1rem', border: '1px solid #e2e8f0', display: 'flex', gap: '1rem' }}>
                    <img src={imageUrl || 'https://via.placeholder.com/180x120?text=No+Image'} alt="" style={{ width: '180px', height: '120px', objectFit: 'cover', borderRadius: '8px', flexShrink: 0 }} />
                    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
                      <div>
                        <span style={{ fontSize: '0.7rem', color: '#64748b', fontWeight: 700, textTransform: 'uppercase' }}>
                          {article.source?.name || article.source || 'NEWS'} • {article.topic ? article.topic.replace('-', ' ') : ''} • {article.publishedAt ? new Date(article.publishedAt).toLocaleDateString() : article.fetchedAt ? new Date(article.fetchedAt).toLocaleDateString() : 'Today'}
                        </span>
                        <h3 style={{ margin: '0.25rem 0 0.5rem 0', fontSize: '1rem', color: '#0f172a', fontWeight: 700 }}>
                          <InteractiveText text={translation?.title || article.title} onSelectWord={handleWordSelect} />
                        </h3>
                        <p style={{ margin: 0, fontSize: '0.8rem', color: '#475569', lineHeight: 1.4 }}>
                          <InteractiveText text={translation?.description || article.description || article.snippet} onSelectWord={handleWordSelect} />
                        </p>
                      </div>

                      <div style={{ marginTop: '0.5rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <button onClick={() => toggleSummary(articleId)} style={{ border: 'none', background: 'transparent', color: '#800020', fontWeight: 600, fontSize: '0.75rem', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.2rem' }}>
                          {isExpanded ? <FiChevronUp size={14} /> : <FiChevronDown size={14} />}
                          {isExpanded ? "Hide Summary" : "Read Summary"}
                        </button>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <BookmarkButton article={article} />
                          <button onClick={() => handleOpenFullArticle(article)} style={{ border: 'none', background: 'transparent', color: '#64748b', fontWeight: 600, fontSize: '0.75rem', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.2rem' }}>
                            Full Article <FiExternalLink size={12} />
                          </button>
                        </div>
                      </div>

                      {isExpanded && (
                        <div style={{ marginTop: '0.5rem', padding: '0.65rem', background: '#fdf2f4', borderRadius: '6px', borderLeft: '3px solid #800020', fontSize: '0.78rem', color: '#334155' }}>
                          {isLoadingSummary ? (
                            <span style={{ fontStyle: 'italic', color: '#64748b' }}>Generating summary...</span>
                          ) : (
                            <InteractiveText text={translation?.aiSummary || article.aiSummary || translation?.content || article.content || article.description} onSelectWord={handleWordSelect} />
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </main>

          {showOverlay && selectedWord && (
            <div style={{ position: 'fixed', bottom: '24px', right: '24px', width: '320px', zIndex: 999 }}>
              <WordIntelligencePanel
                targetLang={targetLang}
                handleLangChange={handleLangChange}
                onClose={() => setShowOverlay(false)}
                selectedWord={selectedWord}
                contextSentence={contextSentence}
                detailsLoading={detailsLoading}
                wordDetails={wordDetails}
                playAudio={playAudio}
                translation={translation}
                onSaveWord={handleSaveWord}
              />
            </div>
          )}
        </div>
      )}

      {/* PAGE 2: PARSED READER VIEW */}
      {viewMode === 'full' && activeArticle && (
        <div style={{ height: '100%', display: 'flex', flexDirection: 'column', position: 'relative' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingBottom: '0.75rem', borderBottom: '1px solid #e2e8f0', marginBottom: '0.5rem' }}>
            <button onClick={() => setViewMode('feed')} style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', border: 'none', background: '#f1f5f9', padding: '0.4rem 0.8rem', borderRadius: '6px', cursor: 'pointer', color: '#0f172a', fontWeight: 600, fontSize: '0.8rem' }}>
              <FiArrowLeft size={14} /> Back to Feed
            </button>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <BookmarkButton article={activeArticle} />
              <button
                onClick={() => setShowComments(!showComments)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.4rem',
                  background: showComments ? '#1e293b' : '#f1f5f9',
                  color: showComments ? '#fff' : '#0f172a',
                  border: '1px solid #cbd5e1',
                  padding: '0.35rem 0.7rem',
                  borderRadius: '6px',
                  fontWeight: 600,
                  fontSize: '0.75rem',
                  cursor: 'pointer'
                }}
              >
                <FiMessageSquare size={14} /> Comments
              </button>
              <a href={activeArticle.url} target="_blank" rel="noopener noreferrer" style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', textDecoration: 'none', color: '#800020', border: '1px solid #e0a8b0', background: '#fdf2f4', padding: '0.35rem 0.7rem', borderRadius: '6px', fontSize: '0.75rem', fontWeight: 600 }}>
                Open Original Source <FiExternalLink size={12} />
              </a>
            </div>
          </div>

          <div style={{ flex: 1, overflowY: 'auto', background: '#fff', borderRadius: '12px', padding: '2rem', border: '1px solid #cbd5e1' }}>
            {fetchingFullText && (
              <div style={{ textAlign: 'center', padding: '4rem', color: '#64748b' }}>
                <p style={{ fontSize: '0.9rem', fontWeight: 600 }}>Extracting full article text...</p>
              </div>
            )}
            {fetchError && (
              <div style={{ textAlign: 'center', padding: '3rem' }}>
                <h3 style={{ fontSize: '1.1rem', color: '#0f172a' }}>Could not extract full text automatically.</h3>
                <p style={{ color: '#64748b', fontSize: '0.85rem', marginBottom: '1.25rem' }}>
                  This publisher blocks automated scraping or requires a subscription.
                </p>
                <a href={activeArticle.url} target="_blank" rel="noopener noreferrer" style={{ background: '#800020', color: '#fff', padding: '0.6rem 1.2rem', borderRadius: '8px', textDecoration: 'none', fontWeight: 600, fontSize: '0.85rem' }}>
                  Read directly on {activeArticle.source?.name || activeArticle.source || 'Source Website'}
                </a>
              </div>
            )}
            {extractedArticle && (
              <article style={{ maxWidth: '800px', margin: '0 auto' }}>
                <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#0f172a', marginBottom: '0.5rem', lineHeight: 1.25 }}>
                  <InteractiveText text={extractedArticle.title || activeArticle.title} onSelectWord={handleWordSelect} />
                </h1>
                {extractedArticle.byline && (
                  <p style={{ fontSize: '0.82rem', color: '#64748b', fontWeight: 600, marginBottom: '1.5rem' }}>
                    {extractedArticle.byline}
                  </p>
                )}
                <hr style={{ border: 'none', borderTop: '1px solid #e2e8f0', margin: '1rem 0 1.5rem 0' }} />
                <div style={{ fontSize: '1rem', color: '#334155', lineHeight: 1.7, display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  {extractedArticle.content.split('\n\n').map((paragraph, idx) => (
                    <p key={idx} style={{ margin: 0 }}>
                      <InteractiveText text={paragraph} onSelectWord={handleWordSelect} />
                    </p>
                  ))}
                </div>
              </article>
            )}
          </div>

          {showOverlay && selectedWord && (
            <div style={{ position: 'fixed', bottom: '24px', right: '24px', width: '320px', zIndex: 999 }}>
              <WordIntelligencePanel
                targetLang={targetLang}
                handleLangChange={handleLangChange}
                onClose={() => setShowOverlay(false)}
                selectedWord={selectedWord}
                contextSentence={contextSentence}
                detailsLoading={detailsLoading}
                wordDetails={wordDetails}
                playAudio={playAudio}
                translation={translation}
                onSaveWord={handleSaveWord}
              />
            </div>
          )}
        </div>
      )}

      {/* PAGE 3: FAST FEED REEL VIEW */}
      {viewMode === 'fast_feed' && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(15, 23, 42, 0.85)', backdropFilter: 'blur(8px)', zIndex: 1000, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          <button
            onClick={() => setViewMode('feed')}
            style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: 'rgba(255,255,255,0.2)', border: 'none', color: '#fff', borderRadius: '50%', width: '36px', height: '36px', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', zIndex: 1010 }}
          >
            <FiX size={20} />
          </button>
          <div
            style={{
              width: '95vw',
              maxWidth: '1280px',
              height: '88vh',
              overflowY: 'scroll',
              scrollSnapType: 'y mandatory',
              borderRadius: '20px',
              scrollbarWidth: 'none'
            }}
          >
            {articles.map((article, index) => {
              const isLast = index === articles.length - 1;
              const imageUrl = article.urlToImage || article.image || article.imageUrl || article.url_to_image;
              const translation = translations[article._id || article.id];

              return (
                <div
                  key={article._id || article.url || index}
                  ref={isLast ? lastArticleElementRef : null}
                  style={{
                    scrollSnapAlign: 'start',
                    scrollSnapStop: 'always',
                    height: '100%',
                    width: '100%',
                    background: '#fff',
                    borderRadius: '20px',
                    display: 'grid',
                    gridTemplateColumns: '1.1fr 1.8fr 1.1fr',
                    overflow: 'hidden',
                    marginBottom: '2rem',
                    boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.4)'
                  }}
                >
                  <div style={{ position: 'relative', background: '#0f172a', color: '#fff', padding: '2rem 1.5rem', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', overflow: 'hidden' }}>
                    <img
                      src={imageUrl || 'https://via.placeholder.com/600x400?text=No+Image'}
                      alt={article.title || 'Article Background'}
                      onError={(e) => {
                        e.target.onerror = null;
                        e.target.src = 'https://via.placeholder.com/600x400?text=No+Image';
                      }}
                      style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover', opacity: 0.35 }}
                    />
                    <div style={{ position: 'relative', zIndex: 2 }}>
                      <span style={{ background: 'rgba(255,255,255,0.2)', backdropFilter: 'blur(6px)', padding: '0.3rem 0.75rem', borderRadius: '12px', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                        {article.source?.name || article.source || 'NEWS'}
                      </span>
                    </div>
                    <div style={{ position: 'relative', zIndex: 2 }}>
                      <h2 style={{ fontSize: '1.45rem', fontWeight: 800, margin: '0 0 0.75rem 0', lineHeight: 1.35 }}>
                        <InteractiveText text={translation?.title || article.title} onSelectWord={handleWordSelect} />
                      </h2>
                      <span style={{ fontSize: '0.78rem', color: '#cbd5e1', fontWeight: 500 }}>
                        {article.publishedAt ? new Date(article.publishedAt).toLocaleDateString() : 'Today'}
                      </span>
                    </div>
                  </div>

                  <div style={{ padding: '2rem', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', borderRight: '1px solid #f1f5f9' }}>
                    <div style={{ overflowY: 'auto', paddingRight: '0.75rem' }}>
                      <p style={{ margin: 0, fontSize: '1rem', color: '#334155', lineHeight: 1.7, fontWeight: 400 }}>
                        <InteractiveText
                          text={translation?.aiSummary || article.aiSummary || translation?.content || article.description || article.content || "Summary content not available."}
                          onSelectWord={handleWordSelect}
                        />
                      </p>
                    </div>
                    <button
                      onClick={() => handleOpenFullArticle(article)}
                      style={{
                        marginTop: '1.5rem',
                        background: '#800020',
                        color: '#fff',
                        border: 'none',
                        padding: '0.85rem 1.25rem',
                        borderRadius: '12px',
                        fontWeight: 700,
                        fontSize: '0.9rem',
                        cursor: 'pointer',
                        width: '100%',
                        transition: 'background-color 0.2s ease'
                      }}
                    >
                      Read full article
                    </button>
                  </div>

                  <div style={{ background: '#f8fafc', padding: '1.5rem 1rem', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <button
                      onClick={() => setShowComments(!showComments)}
                      style={{ background: '#800020', color: '#fff', border: 'none', padding: '0.7rem', borderRadius: '10px', fontSize: '0.82rem', fontWeight: 700, cursor: 'pointer', width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.4rem' }}
                    >
                      <FiMessageSquare size={14} /> Comment Box
                    </button>
                    <WordIntelligencePanel
                      targetLang={targetLang}
                      handleLangChange={handleLangChange}
                      selectedWord={selectedWord}
                      contextSentence={contextSentence}
                      detailsLoading={detailsLoading}
                      wordDetails={wordDetails}
                      playAudio={playAudio}
                      translation={translation}
                      onSaveWord={handleSaveWord}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}