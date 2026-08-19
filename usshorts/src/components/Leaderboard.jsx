import React, { useState, useEffect } from 'react';
import { contestService } from '../api/contestService';

export default function Leaderboard({ contestId, onBack }) {
  const [submissions, setSubmissions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchLeaderboard = async () => {
      try {
        setLoading(true);
        const data = await contestService.getLeaderboard(contestId);
        setSubmissions(data || []);
      } catch (err) {
        setError(err.response?.data?.message || 'Failed to load leaderboard data.');
      } finally {
        setLoading(false);
      }
    };

    if (contestId) {
      fetchLeaderboard();
    }
  }, [contestId]);

  return (
    <div style={{ maxWidth: '850px', margin: '2rem auto', padding: '0 1rem', fontFamily: 'inherit' }}>
      
      {/* Navigation Header */}
      <div style={{ marginBottom: '1.5rem' }}>
        <button
          onClick={onBack}
          style={{
            background: 'none',
            border: 'none',
            color: '#475569',
            fontWeight: 700,
            fontSize: '0.95rem',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            padding: 0
          }}
        >
          ← Back to Home
        </button>
      </div>

      <div style={{
        background: '#ffffff',
        borderRadius: '16px',
        padding: '2rem',
        border: '1px solid #e2e8f0',
        boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)'
      }}>
        
        {/* Title Banner */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
          <div>
            <h2 style={{ margin: 0, color: '#0f172a', fontSize: '1.75rem', fontWeight: 800 }}>
              Contest Leaderboard 🏆
            </h2>
            <p style={{ margin: '0.25rem 0 0 0', color: '#64748b', fontSize: '0.9rem', fontWeight: 600 }}>
              Rankings based on highest score and fastest time taken.
            </p>
          </div>
        </div>

        {/* Loading State */}
        {loading && (
          <div style={{ textAlign: 'center', padding: '3rem 0', color: '#64748b', fontWeight: 600 }}>
            Loading leaderboard standings...
          </div>
        )}

        {/* Error State */}
        {error && (
          <div style={{
            padding: '1rem',
            borderRadius: '8px',
            backgroundColor: '#fee2e2',
            color: '#991b1b',
            border: '1px solid #fecaca',
            fontWeight: 600
          }}>
            {error}
          </div>
        )}

        {/* Submissions Table */}
        {!loading && !error && submissions.length > 0 && (
          <div style={{ overflowX: 'auto', marginTop: '1rem' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid #e2e8f0' }}>
                  <th style={thStyle}>Rank</th>
                  <th style={thStyle}>User</th>
                  <th style={thStyle}>Score</th>
                  <th style={{ ...thStyle, textAlign: 'right' }}>Time Spent</th>
                </tr>
              </thead>
              <tbody>
                {submissions.map((sub, index) => {
                  const rank = index + 1;
                  const username = sub.user?.username || sub.user?.email || 'Anonymous Participant';

                  return (
                    <tr key={sub._id || index} style={{ borderBottom: '1px solid #f1f5f9' }}>
                      {/* Rank Column */}
                      <td style={tdStyle}>
                        <span style={getRankBadgeStyle(rank)}>
                          #{rank}
                        </span>
                      </td>

                      {/* User Column */}
                      <td style={tdStyle}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                          <div style={{
                            width: '32px',
                            height: '32px',
                            borderRadius: '50%',
                            background: '#0f172a',
                            color: '#ffffff',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: 800,
                            fontSize: '0.85rem'
                          }}>
                            {username.charAt(0).toUpperCase()}
                          </div>
                          <span style={{ fontWeight: 700, color: '#0f172a' }}>{username}</span>
                        </div>
                      </td>

                      {/* Score Column */}
                      <td style={tdStyle}>
                        <span style={{
                          fontWeight: 800,
                          color: '#166534',
                          background: '#dcfce7',
                          padding: '0.25rem 0.6rem',
                          borderRadius: '6px',
                          fontSize: '0.875rem'
                        }}>
                          {sub.score} pts
                        </span>
                      </td>

                      {/* Time Column */}
                      <td style={{ ...tdStyle, textAlign: 'right', fontWeight: 700, color: '#475569' }}>
                        ⏱ {sub.timeTakenSeconds ?? 0}s
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Empty State */}
        {!loading && !error && submissions.length === 0 && (
          <div style={{ textAlign: 'center', padding: '3rem 0', color: '#64748b' }}>
            <p style={{ margin: 0, fontWeight: 700, fontSize: '1.1rem' }}>No submissions recorded yet!</p>
            <p style={{ margin: '0.5rem 0 0 0', fontSize: '0.9rem' }}>Be the first to participate and take the top spot.</p>
          </div>
        )}

      </div>
    </div>
  );
}

// Table Header Style
const thStyle = {
  padding: '0.85rem 1rem',
  fontSize: '0.85rem',
  fontWeight: 800,
  color: '#475569',
  textTransform: 'uppercase',
  letterSpacing: '0.05em'
};

// Table Data Cell Style
const tdStyle = {
  padding: '1rem',
  fontSize: '0.95rem',
  verticalAlign: 'middle'
};

// Top 3 Rank Badges Color Customizer
function getRankBadgeStyle(rank) {
  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: '36px',
    height: '28px',
    borderRadius: '6px',
    fontWeight: 800,
    fontSize: '0.85rem'
  };

  if (rank === 1) {
    return { ...base, background: '#fef3c7', color: '#b45309', border: '1px solid #fde68a' }; // Gold
  }
  if (rank === 2) {
    return { ...base, background: '#f1f5f9', color: '#475569', border: '1px solid #cbd5e1' }; // Silver
  }
  if (rank === 3) {
    return { ...base, background: '#ffedd5', color: '#c2410c', border: '1px solid #fed7aa' }; // Bronze
  }
  return { ...base, background: '#ffffff', color: '#64748b', border: '1px solid #e2e8f0' };
}