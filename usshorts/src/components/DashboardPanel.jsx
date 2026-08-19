import { useState, useEffect } from 'react';
import { dashboardStats, leaderboard, quests, topics } from '../data/mockData';
import { useBookmarks } from '../context/BookmarksContext';
import { FiBookmark, FiTrash2, FiX } from 'react-icons/fi';

// Helper function to update and fetch daily streak logic
const updateDailyStreak = () => {
  const todayStr = new Date().toLocaleDateString('en-CA');
  const lastVisit = localStorage.getItem('lastStreakVisitDate');
  const storedStreak = localStorage.getItem('userStreakCount');
  
  let currentStreak = storedStreak ? parseInt(storedStreak, 10) : 0;

  if (!lastVisit) {
    currentStreak = 1;
  } else if (lastVisit !== todayStr) {
    const lastDate = new Date(lastVisit);
    const todayDate = new Date(todayStr);

    const diffTime = todayDate.getTime() - lastDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 3600 * 24));

    if (diffDays === 1) {
      currentStreak = (currentStreak > 0 ? currentStreak : 0) + 1;
    } else if (diffDays > 1) {
      currentStreak = 1;
    }
  } else if (currentStreak === 0) {
    currentStreak = 1;
  }

  localStorage.setItem('lastStreakVisitDate', todayStr);
  localStorage.setItem('userStreakCount', currentStreak.toString());

  return currentStreak;
};

// Helper function to update and fetch daily streak logic
const updateDailyStreak = () => {
  const todayStr = new Date().toLocaleDateString('en-CA'); // Formats local date as YYYY-MM-DD
  const lastVisit = localStorage.getItem('lastStreakVisitDate');
  const storedStreak = localStorage.getItem('userStreakCount');
  
  let currentStreak = storedStreak ? parseInt(storedStreak, 10) : 0;

  if (!lastVisit) {
    // First visit ever: set streak to 1
    currentStreak = 1;
  } else if (lastVisit !== todayStr) {
    const lastDate = new Date(lastVisit);
    const todayDate = new Date(todayStr);

    const diffTime = todayDate.getTime() - lastDate.getTime();
    const diffDays = Math.round(diffTime / (1000 * 3600 * 24));

    if (diffDays === 1) {
      // Consecutive day visit
      currentStreak = (currentStreak > 0 ? currentStreak : 0) + 1;
    } else if (diffDays > 1) {
      // Missed one or more days: reset streak to 1 today
      currentStreak = 1;
    }
  } else if (currentStreak === 0) {
    // Fallback if stored streak was somehow 0 on same-day visit
    currentStreak = 1;
  }

  // Persist updated values
  localStorage.setItem('lastStreakVisitDate', todayStr);
  localStorage.setItem('userStreakCount', currentStreak.toString());

  return currentStreak;
};

function BookmarksPanel() {
  const { bookmarks, loading, remove } = useBookmarks();

  return (
    <div className="panel" style={{ gridColumn: '1 / -1' }}>
      <div className="panel-heading">
        <div>
          <p className="eyebrow">Saved for later</p>
          <h3>Bookmarks</h3>
        </div>
        <span className="pill soft">{bookmarks.length} saved</span>
      </div>
      {loading ? (
        <p style={{ opacity: 0.6, fontSize: '0.9rem' }}>Loading bookmarks...</p>
      ) : bookmarks.length === 0 ? (
        <p style={{ opacity: 0.6, fontSize: '0.9rem' }}>
          No bookmarks yet. Save articles from the Articles page to build your reading list.
        </p>
      ) : (
        <div className="bookmark-list" style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {bookmarks.map((bookmark) => {
            const article = bookmark.article || {};
            const imageUrl = article.imageUrl || '';
            return (
              <div
                key={bookmark.articleUrl}
                style={{
                  display: 'flex',
                  gap: '0.75rem',
                  alignItems: 'center',
                  padding: '0.6rem 0.75rem',
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  borderRadius: '10px'
                }}
              >
                {imageUrl ? (
                  <img
                    src={imageUrl}
                    alt=""
                    style={{ width: '64px', height: '48px', objectFit: 'cover', borderRadius: '6px', flexShrink: 0 }}
                    onError={(e) => { e.target.style.display = 'none'; }}
                  />
                ) : (
                  <div style={{ width: '64px', height: '48px', borderRadius: '6px', flexShrink: 0, background: 'var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)' }}>
                    <FiBookmark size={16} />
                  </div>
                )}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <a
                    href={article.url || bookmark.articleUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{ fontWeight: 600, fontSize: '0.92rem', color: 'var(--text)', textDecoration: 'none', display: 'block', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}
                  >
                    {article.title || 'Untitled article'}
                  </a>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                    {article.source || 'News'}
                    {article.publishedAt ? ` · ${new Date(article.publishedAt).toLocaleDateString()}` : ''}
                  </span>
                </div>
                <button
                  onClick={() => remove(bookmark.articleUrl)}
                  title="Remove bookmark"
                  style={{ border: 'none', background: 'transparent', color: 'var(--text-muted)', cursor: 'pointer', display: 'flex', padding: '6px', borderRadius: '6px' }}
                  onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(239, 68, 68, 0.12)'; e.currentTarget.style.color = '#ef4444'; }}
                  onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent'; e.currentTarget.color = 'var(--text-muted)'; }}
                >
                  <FiTrash2 size={16} />
                </button>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default function DashboardPanel() {
  const [savedWordsCount, setSavedWordsCount] = useState(0);
  const [commentsCount, setCommentsCount] = useState(0);
  const [streakCount, setStreakCount] = useState(() => updateDailyStreak());

  useEffect(() => {
    // 1. Evaluate Daily Streak on mount and window focus
  const [savedWordsList, setSavedWordsList] = useState([]);
  const [commentsCount, setCommentsCount] = useState(0);
  const [streakCount, setStreakCount] = useState(() => updateDailyStreak());
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    const updateStreak = () => {
      const currentStreak = updateDailyStreak();
      setStreakCount(currentStreak);
    };

    updateStreak();

    // 2. Fetch Saved Words Count
    const fetchSavedWordsCount = async () => {
    const fetchSavedWords = async () => {
      try {
        let token = localStorage.getItem('token') || localStorage.getItem('jwt');
        if (!token) {
          const storedUser = localStorage.getItem('user');
          if (storedUser) {
            try {
              const parsedUser = JSON.parse(storedUser);
              token = parsedUser.token || parsedUser.jwt;
            } catch (e) {
              console.error('Failed to parse user from localStorage', e);
            }
          }
        }

        const res = await fetch(`http://localhost:5000/api/saved-words?t=${Date.now()}`, {
          headers: {
            'Content-Type': 'application/json',
            ...(token && { Authorization: `Bearer ${token}` })
          }
        });

        if (res.ok) {
          const json = await res.json();
          
          let list = [];
          if (Array.isArray(json)) {
            list = json;
          } else if (Array.isArray(json.data)) {
            list = json.data;
          } else if (Array.isArray(json.words)) {
            list = json.words;
          } else if (Array.isArray(json.savedWords)) {
            list = json.savedWords;
          }

          setSavedWordsCount(list.length);
        }
      } catch (err) {
        console.error('Failed to fetch saved words count:', err);
      }
    };

    fetchSavedWordsCount();

    const handleFocus = () => {
      updateStreak();
      fetchSavedWordsCount();
          setSavedWordsList(list);
        }
      } catch (err) {
        console.error('Failed to fetch saved words list:', err);
      }
    };

    fetchSavedWords();

    const handleFocus = () => {
      updateStreak();
      fetchSavedWords();
    };

    window.addEventListener('focus', handleFocus);
    return () => window.removeEventListener('focus', handleFocus);
  }, []);

  return (
    <div className="dashboard-grid">
      <div className="panel full">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Overview</p>
            <h3>Learning Metrics</h3>
          </div>
        </div>
        <div className="stats-grid">
          {dashboardStats.map((item) => {
            const isWordsLearned = item.label.toLowerCase() === 'words learned';
            const isWordsRead = item.label.toLowerCase() === 'words read';
            const isReadingStreak = item.label.toLowerCase().includes('streak');

            // Render "Comments made"
            if (isWordsRead) {
              return (
                <div className="stat-card" key="comments-made">
                  <span>Comments made</span>
                  <strong>{commentsCount.toLocaleString()}</strong>
                  <small>{item.delta}</small>
                </div>
              );
            }

            // Render live "Reading streak"
            if (isReadingStreak) {
              return (
                <div className="stat-card" key={item.label}>
                  <span>{item.label}</span>
                  <strong>{streakCount} {streakCount === 1 ? 'day' : 'days'}</strong>
                  <small>{item.delta}</small>
                </div>
              );
            }

            // Default card rendering
            return (
              <div className="stat-card" key={item.label}>
                <span>{item.label}</span>
                <strong>
                  {isWordsLearned ? savedWordsCount.toLocaleString() : item.value}
                </strong>
            if (isWordsLearned) {
              return (
                <div 
                  className="stat-card" 
                  key={item.label}
                  onClick={() => setIsModalOpen(true)}
                  style={{ cursor: 'pointer', transition: 'transform 0.15s ease' }}
                  title="Click to view saved words"
                >
                  <span>{item.label}</span>
                  <strong>{savedWordsList.length.toLocaleString()}</strong>
                  <small>{item.delta}</small>
                </div>
              );
            }

            return (
              <div className="stat-card" key={item.label}>
                <span>{item.label}</span>
                <strong>{item.value}</strong>
                <small>{item.delta}</small>
              </div>
            );
          })}
        </div>
      </div>

      {/* Modal for Words Learned */}
      {isModalOpen && (
        <div 
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            width: '100vw',
            height: '100vh',
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            display: 'flex',
            alignItems: 'center',
            justify: 'center',
            zIndex: 1000
          }}
          onClick={() => setIsModalOpen(false)}
        >
          <div 
            style={{
              background: 'var(--bg-card, #fff)',
              padding: '1.5rem',
              borderRadius: '12px',
              maxWidth: '500px',
              width: '90%',
              maxHeight: '80vh',
              overflowY: 'auto',
              boxShadow: '0 10px 25px rgba(0,0,0,0.15)',
              position: 'relative'
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', borderBottom: '1px solid var(--border, #eee)', paddingBottom: '0.5rem' }}>
              <h3 style={{ margin: 0, fontSize: '1.2rem' }}>Saved Words ({savedWordsList.length})</h3>
              <button 
                onClick={() => setIsModalOpen(false)} 
                style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--text-muted, #666)' }}
              >
                <FiX size={20} />
              </button>
            </div>

            {savedWordsList.length === 0 ? (
              <p style={{ opacity: 0.7, fontSize: '0.9rem' }}>No saved words found.</p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                {savedWordsList.map((item, index) => {
                  const word = typeof item === 'string' ? item : item.word || item.term || 'Unknown word';
                  const meaning = typeof item === 'object' ? item.meaning || item.definition || item.translation || 'No definition available.' : 'No definition available.';
                  
                  return (
                    <div 
                      key={item._id || index}
                      style={{
                        padding: '0.75rem',
                        borderRadius: '8px',
                        background: 'var(--bg-body, #f8fafc)',
                        border: '1px solid var(--border, #e2e8f0)'
                      }}
                    >
                      <strong style={{ fontSize: '1rem', color: 'var(--text, #0f172a)', display: 'block', marginBottom: '0.25rem' }}>
                        {word}
                      </strong>
                      <p style={{ margin: 0, fontSize: '0.85rem', color: 'var(--text-muted, #475569)' }}>
                        {meaning}
                      </p>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}

      <div className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">This week</p>
            <h3>Quests</h3>
          </div>
        </div>
        <ul className="list">
          {quests.map((quest) => <li key={quest}>{quest}</li>)}
        </ul>
      </div>
      <div className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Top Learners</p>
            <h3>Leaderboard</h3>
          </div>
        </div>
        <ol className="list">
          {leaderboard.map((user) => (
            <li key={user.name}>
              <span>{user.name}</span>
              <strong>{user.points} pts</strong>
            </li>
          ))}
        </ol>
      </div>
      <BookmarksPanel />
    </div>
  );
}