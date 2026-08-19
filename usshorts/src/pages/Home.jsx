import { useEffect, useMemo, useState } from 'react';
import NewsCard from '../components/NewsCard';
import ArticlePanel from '../components/ArticlePanel';
import NotFound from './NotFound';
import { fetchHeadlines } from '../api/newsService';
import useArticleTranslation from '../hooks/useArticleTranslation';
import { useLanguage } from '../context/LanguageContext';

// Centralized Axios Client
import client from '../api/client';
// Quiz & Flashcard Utilities and Modals
import { filterWordsByTimeframe, filterWordsByDateRange, generateQuizQuestions } from '../utils/quizUtils';
import { QuizModal, FlashcardViewer } from '../components/StudyTools';
import { FiLayers, FiAward, FiTrash2, FiCalendar, FiFlag } from 'react-icons/fi';
// Contest Features & Services Integration
import { contestService } from '../api/contestService';
import ContestSearch from '../components/ContestSearch';
import QuizRunner from '../components/QuizRunner';
import Leaderboard from '../components/Leaderboard';

// Shared styles and configuration constants
const inputStyle = {
    flex: 1,
    padding: '0.6rem 0.8rem',
    borderRadius: '8px',
    border: '1px solid #e2e8f0',
    color: '#0f172a',
    backgroundColor: '#f8fafc',
    fontSize: '0.85rem',
    fontWeight: '600',
    outline: 'none'
};

const deckColors = [
    { bg: '#f0e8e6', border: '#e2d4d0' },
    { bg: '#ffffff', border: '#e2e8f0' }
];

export default function Home() {
    const [articles, setArticles] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(false);
    const [activeId, setActiveId] = useState(null);
    const { translations, loading: translating, unavailable } = useArticleTranslation(articles);
    const { targetLanguage } = useLanguage();
    // Saved Words & Study Tools State
    const [savedWords, setSavedWords] = useState([]);
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [deckName, setDeckName] = useState('');
    // Custom Decks State (Backed by Backend API)
    const [customDecks, setCustomDecks] = useState([]);
    const [activeQuiz, setActiveQuiz] = useState(null);
    const [activeDeck, setActiveDeck] = useState(null);
    // Contests State
    const [publicContests, setPublicContests] = useState([]);
    const [activeContest, setActiveContest] = useState(null);
    const [viewLeaderboardId, setViewLeaderboardId] = useState(null);

    // Fetch Custom Flashcard Decks from Backend via Central Axios Client
    useEffect(() => {
        client.get('/flashcard-decks')
            .then((res) => {
                const response = res.data;
                const decksArray = response?.data || (Array.isArray(response) ? response : []);
                setCustomDecks(decksArray);
            })
            .catch((err) => console.error('Failed to load flashcard decks:', err));
    }, []);

    // Fetch Public Contests
    useEffect(() => {
        contestService.getPublicContests()
            .then((data) => {
                const contestsArray = data?.data || (Array.isArray(data) ? data : []);
                setPublicContests(contestsArray);
            })
            .catch((err) => console.error('Failed to load public contests:', err));
    }, []);

    // Fetch News Headlines
    useEffect(() => {
        fetchHeadlines('general')
            .then((data) => {
                if (data) {
                    setArticles(data);
                    if (data.length > 0) setActiveId(data[0].id);
                }
            })
            .catch((err) => {
                console.error('Failed to load news headlines:', err);
                setError(true);
            })
            .finally(() => setLoading(false));
    }, []);

    // Fetch Saved Words for Quizzes & Flashcards via Central Axios Client
    useEffect(() => {
        client.get('/saved-words')
            .then((res) => {
                const response = res.data;
                const wordsArray = response?.data || (Array.isArray(response) ? response : []);
                setSavedWords(wordsArray);
            })
            .catch((err) => console.error('Failed to load saved words:', err));
    }, []);

    const activeArticle = useMemo(
        () => articles.find((item) => item.id === activeId) ?? articles[0],
        [activeId, articles]
    );

    // Quiz Handlers
    const handleStartQuiz = (timeframe, title) => {
        const filtered = filterWordsByTimeframe(savedWords, timeframe);
        const questions = generateQuizQuestions(filtered, savedWords);
        setActiveQuiz({ questions, title });
    };

    // Custom Deck Creation Handler (POST to Backend via Central Client)
    const handleCreateCustomDeck = async (e) => {
        e.preventDefault();
        const filtered = filterWordsByDateRange(savedWords, startDate, endDate);
        const title =
            deckName.trim() ||
            (startDate && endDate
                ? `Deck ${startDate} - ${endDate}`
                : `Custom Deck (${filtered.length} words)`);
        const newDeckPayload = {
            title,
            deck: filtered,
            wordCount: filtered.length,
            createdAt: new Date().toISOString()
        };
        try {
            const res = await client.post('/flashcard-decks', newDeckPayload);
            const responseData = res.data;
            const createdDeck = responseData?.data || responseData;
            setCustomDecks((prev) => [createdDeck, ...prev]);
        } catch (err) {
            console.error('Error creating deck:', err);
        }
        setDeckName('');
        setStartDate('');
        setEndDate('');
    };

    // Delete Custom Deck Handler (DELETE to Backend via Central Client)
    const handleDeleteDeck = async (id) => {
        try {
            await client.delete(`/flashcard-decks/${id}`);
            setCustomDecks((prev) => prev.filter((deck) => (deck._id || deck.id) !== id));
        } catch (err) {
            console.error('Error deleting deck:', err);
        }
    };

    if (error) return <NotFound title="API Error" message="Unable to load news data. Please check your backend connection." />;

    if (loading) {
        return (
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '50vh' }}>
                <p style={{ opacity: 0.5 }}>Loading news...</p>
            </div>
        );
    }


    // Active Contest Interactive Runner Overlay
    if (activeContest) {
        return (
            <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '2rem' }}>
                <button
                    onClick={() => setActiveContest(null)}
                    style={{ marginBottom: '1rem', background: 'none', border: 'none', color: '#0f172a', fontWeight: 700, cursor: 'pointer' }}
                >
                    ← Exit Contest
                </button>
                <QuizRunner
                    contest={activeContest}
                    onCompleted={() => {
                        setViewLeaderboardId(activeContest._id);
                        setActiveContest(null);
                    }}
                />
            </div>
        );
    }

    // Active Contest Leaderboard Overlay
    if (viewLeaderboardId) {
        return (
            <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '2rem' }}>
                <button
                    onClick={() => setViewLeaderboardId(null)}
                    style={{ marginBottom: '1rem', background: 'none', border: 'none', color: '#0f172a', fontWeight: 700, cursor: 'pointer' }}
                >
                    ← Back to Home
                </button>
                <Leaderboard contestId={viewLeaderboardId} />
            </div>
        );
    }

    return (
        <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '2rem' }}>
            
            {/* CONTESTS SECTION (SEARCH PRIVATE & PUBLIC LIST) */}
            <div style={{ marginBottom: '3rem', background: '#ffffff', borderRadius: '16px', padding: '1.5rem', border: '1px solid #e2e8f0', boxShadow: '0 2px 4px rgba(0,0,0,0.02)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1.25rem' }}>
                    <FiFlag size={22} color="#5a1818" />
                    <h3 style={{ margin: 0, fontSize: '1.4rem', color: '#5a1818', fontWeight: 800 }}>
                        Official Contests
                    </h3>
                </div>
                {/* Passcode Entry Bar */}
                <div style={{ marginBottom: '1.5rem' }}>
                    <ContestSearch onContestFound={(contest) => setActiveContest(contest)} />
                </div>
                {/* Public Contests Display */}
                <div>
                    <h4 style={{ margin: '0 0 1rem 0', fontSize: '1rem', color: '#1e293b', fontWeight: 700 }}>
                        Weekly & Monthly Challenges
                    </h4>
                    {publicContests.length === 0 ? (
                        <p style={{ opacity: 0.6, fontSize: '0.9rem', margin: 0 }}>No public contests scheduled right now. Check back soon!</p>
                    ) : (
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem' }}>
                            {publicContests.map((contest) => (
                                <div key={contest._id || contest.id} style={{ background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '1rem', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
                                    <div>
                                        <h5 style={{ margin: '0 0 0.25rem 0', fontSize: '1rem', color: '#0f172a', fontWeight: 700 }}>{contest.title}</h5>
                                        <p style={{ margin: 0, fontSize: '0.82rem', color: '#64748b' }}>{contest.description || 'Test your knowledge in this timed challenge.'}</p>
                                    </div>
                                    <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem' }}>
                                        <button
                                            onClick={() => setActiveContest(contest)}
                                            style={{ flex: 1, background: '#0f172a', color: '#ffffff', border: 'none', padding: '0.5rem', borderRadius: '8px', fontWeight: 700, fontSize: '0.82rem', cursor: 'pointer' }}
                                        >
                                            Start Quiz
                                        </button>
                                        <button
                                            onClick={() => setViewLeaderboardId(contest._id || contest.id)}
                                            style={{ background: '#ffffff', border: '1px solid #cbd5e1', padding: '0.5rem 0.8rem', borderRadius: '8px', fontWeight: 700, fontSize: '0.82rem', color: '#0f172a', cursor: 'pointer' }}
                                        >
                                            Rankings
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>

            {/* 2-COLUMN VOCABULARY DASHBOARD */}
            <div
                style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(420px, 1fr))',
                    gap: '2.5rem',
                    marginBottom: '3rem'
                }}
            >
                {/* LEFT COLUMN: PRACTICE QUIZZES */}
                <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                        <FiAward size={22} color="#5a1818" />
                        <h3 style={{ margin: 0, fontSize: '1.4rem', color: '#5a1818', fontWeight: 800 }}>
                            Practice Quizzes
                        </h3>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                        <QuizBarCard
                            title="General Quiz"
                            desc="All saved words"
                            bgColor="#f0e8e6"
                            borderColor="#e2d4d0"
                            onClick={() => handleStartQuiz('general', 'General Vocabulary Quiz')}
                        />
                        <QuizBarCard
                            title="Last Week"
                            desc="Last 7 days"
                            bgColor="#ffffff"
                            borderColor="#e2e8f0"
                            onClick={() => handleStartQuiz('last_week', 'Last 7 Days Quiz')}
                        />
                        <QuizBarCard
                            title="Last Month"
                            desc="Last 30 days"
                            bgColor="#f0e8e6"
                            borderColor="#e2d4d0"
                            onClick={() => handleStartQuiz('last_month', 'Last Month Quiz')}
                        />
                        <QuizBarCard
                            title="Last 3 Months"
                            desc="Last 90 days"
                            bgColor="#ffffff"
                            borderColor="#e2e8f0"
                            onClick={() => handleStartQuiz('last_3_months', 'Last 3 Months Quiz')}
                        />
                        <QuizBarCard
                            title="Last 6 Months"
                            desc="Last 180 days"
                            bgColor="#f0e8e6"
                            borderColor="#e2d4d0"
                            onClick={() => handleStartQuiz('last_6_months', 'Last 6 Months Quiz')}
                        />
                    </div>
                </div>

                {/* RIGHT COLUMN: FLASHCARDS (CREATOR + DECK LIST) */}
                <div>
                    {/* Section 1: Flashcard Form */}
                    <div style={{ marginBottom: '2rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                            <FiCalendar size={20} color="#5a1818" />
                            <h3 style={{ margin: 0, fontSize: '1.4rem', color: '#5a1818', fontWeight: 800 }}>
                                Flashcards
                            </h3>
                        </div>
                        <form
                            onSubmit={handleCreateCustomDeck}
                            style={{
                                background: '#ffffff',
                                border: '1px solid #e2e8f0',
                                borderRadius: '16px',
                                padding: '1.25rem',
                                display: 'flex',
                                flexDirection: 'column',
                                gap: '0.75rem',
                                boxShadow: '0 2px 4px rgba(0,0,0,0.02)'
                            }}
                        >
                            <input
                                type="text"
                                placeholder="dd-mm-yyyy"
                                value={deckName}
                                onChange={(e) => setDeckName(e.target.value)}
                                style={inputStyle}
                            />
                            <div style={{ display: 'flex', gap: '0.5rem' }}>
                                <input
                                    type="date"
                                    value={startDate}
                                    onChange={(e) => setStartDate(e.target.value)}
                                    style={inputStyle}
                                />
                                <input
                                    type="date"
                                    value={endDate}
                                    onChange={(e) => setEndDate(e.target.value)}
                                    style={inputStyle}
                                />
                            </div>
                            <button
                                type="submit"
                                style={{
                                    background: '#ffffff',
                                    color: '#0f172a',
                                    border: '1.5px solid #0f172a',
                                    padding: '0.7rem',
                                    borderRadius: '10px',
                                    fontWeight: 700,
                                    fontSize: '0.9rem',
                                    cursor: 'pointer'
                                }}
                            >
                                Create Flashcard Deck
                            </button>
                        </form>
                    </div>

                    {/* Section 2: Saved Decks List */}
                    <div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                            <FiLayers size={20} color="#5a1818" />
                            <h3 style={{ margin: 0, fontSize: '1.4rem', color: '#5a1818', fontWeight: 800 }}>
                                Flashcard Decks
                            </h3>
                        </div>
                        {customDecks.length === 0 ? (
                            <p style={{ opacity: 0.6, fontSize: '0.9rem' }}>
                                No flashcard decks created yet. Use the form above to generate one!
                            </p>
                        ) : (
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                                {customDecks.map((deckItem, idx) => {
                                    const id = deckItem._id || deckItem.id;
                                    return (
                                        <DeckRowCard
                                            key={id}
                                            title={deckItem.title}
                                            wordCount={deckItem.wordCount}
                                            bgColor={deckColors[idx % deckColors.length].bg}
                                            borderColor={deckColors[idx % deckColors.length].border}
                                            onStudy={() => setActiveDeck({ deck: deckItem.deck, title: deckItem.title })}
                                            onDelete={() => handleDeleteDeck(id)}
                                        />
                                    );
                                })}
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* ORIGINAL LIVE NEWS FEED LAYOUT */}
            <section className="feed-layout">
                <div className="news-column">
                    <div className="section-head">
                        <div>
                            <p className="eyebrow">Smart short feed</p>
                            <h2>Live news with AI-powered summaries</h2>
                        </div>
                        <span className="pill soft">{articles.length} articles</span>
                    </div>
                    {(translating || unavailable) && targetLanguage !== 'en' && (
                        <div style={{ marginBottom: '1rem', fontSize: '0.85rem', opacity: 0.7 }}>
                            {unavailable
                                ? 'Translation service unavailable — showing original text.'
                                : `Translating to ${targetLanguage.toUpperCase()}...`}
                        </div>
                    )}
                    <div className="news-list">
                        {articles.map((article) => (
                            <NewsCard
                                key={article.id}
                                article={article}
                                activeId={activeId}
                                onSelect={(id) => setActiveId(id)}
                                translation={translations[article.id] || null}
                            />
                        ))}
                    </div>
                </div>
                {activeArticle && (
                    <ArticlePanel
                        article={activeArticle}
                        translation={translations[activeArticle.id] || null}
                    />
                )}
            </section>

            {/* Active Flashcard Deck Overlay */}
            {activeDeck && (
                <FlashcardViewer
                    deck={activeDeck.deck}
                    title={activeDeck.title}
                    onClose={() => setActiveDeck(null)}
                />
            )}

            {/* Active Quiz Overlay */}
            {activeQuiz && (
                <QuizModal
                    questions={activeQuiz.questions}
                    title={activeQuiz.title}
                    onClose={() => setActiveQuiz(null)}
                />
            )}
        </div>
    );
}

function QuizBarCard({ title, desc, bgColor, borderColor, onClick }) {
    return (
        <div
            style={{
                background: bgColor,
                border: `1px solid ${borderColor}`,
                borderRadius: '14px',
                padding: '0.9rem 1.25rem',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                boxShadow: '0 2px 4px rgba(0,0,0,0.02)'
            }}
        >
            <div>
                <h4 style={{ margin: 0, fontSize: '1rem', color: '#1e293b', fontWeight: 700 }}>{title}</h4>
                <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '0.2rem 0 0 0' }}>{desc}</p>
            </div>
            <button
                type="button"
                onClick={onClick}
                style={{
                    background: '#ffffff',
                    border: '1px solid #cbd5e1',
                    padding: '0.45rem 1rem',
                    borderRadius: '8px',
                    fontWeight: 700,
                    fontSize: '0.85rem',
                    color: '#0f172a',
                    cursor: 'pointer'
                }}
            >
                Start Quiz
            </button>
        </div>
    );
}

function DeckRowCard({ title, wordCount, bgColor, borderColor, onStudy, onDelete }) {
    return (
        <div
            style={{
                background: bgColor,
                border: `1px solid ${borderColor}`,
                borderRadius: '14px',
                padding: '0.85rem 1.1rem',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                boxShadow: '0 2px 4px rgba(0,0,0,0.02)'
            }}
        >
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <h4 style={{ margin: 0, fontSize: '0.95rem', color: '#1e293b', fontWeight: 700 }}>{title}</h4>
                <span style={{ fontSize: '0.8rem', color: '#64748b', fontWeight: 500 }}>
                    {wordCount} words
                </span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <button
                    type="button"
                    onClick={onStudy}
                    style={{
                        background: '#ffffff',
                        border: '1px solid #cbd5e1',
                        padding: '0.4rem 0.9rem',
                        borderRadius: '8px',
                        fontWeight: 700,
                        fontSize: '0.82rem',
                        color: '#0f172a',
                        cursor: 'pointer'
                    }}
                >
                    Study
                </button>
                <button
                    type="button"
                    onClick={onDelete}
                    style={{
                        background: 'transparent',
                        border: 'none',
                        padding: '0.45rem',
                        borderRadius: '8px',
                        color: '#b91c1c',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        cursor: 'pointer'
                    }}
                    title="Delete Deck"
                >
                    <FiTrash2 size={15} />
                </button>
            </div>
        </div>
    );
}