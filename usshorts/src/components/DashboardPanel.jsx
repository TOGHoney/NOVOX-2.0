import { dashboardStats, leaderboard, quests, topics } from '../data/mockData';
import { useBookmarks } from '../context/BookmarksContext';
import { FiBookmark, FiTrash2 } from 'react-icons/fi';

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
                  onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = 'var(--text-muted)'; }}
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
  return (
    <section className="dashboard-grid">
      <div className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Learning dashboard</p>
            <h3>Weekly progress</h3>
          </div>
          <span className="pill success">On track</span>
        </div>
        <div className="stats-grid">
          {dashboardStats.map((item) => (
            <div className="stat-card" key={item.label}>
              <span>{item.label}</span>
              <strong>{item.value}</strong>
              <small>{item.delta}</small>
            </div>
          ))}
        </div>
      </div>
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
            <p className="eyebrow">Trending topics</p>
            <h3>Personalized focus</h3>
          </div>
        </div>
        <div className="topic-wrap">
          {topics.map((topic) => <span key={topic} className="topic-chip">{topic}</span>)}
        </div>
      </div>
      <div className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Leaderboard</p>
            <h3>Community momentum</h3>
          </div>
        </div>
        <ul className="rank-list">
          {leaderboard.map((player, index) => (
            <li key={player.name}>
              <div>
                <strong>#{index + 1} {player.name}</strong>
                <span>{player.badge}</span>
              </div>
              <b>{player.xp} XP</b>
            </li>
          ))}
        </ul>
      </div>
      <BookmarksPanel />
    </section>
  );
}
