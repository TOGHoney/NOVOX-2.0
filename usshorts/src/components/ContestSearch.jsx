import React, { useState } from 'react';
import { contestService } from '../api/contestService'; //
import { getToken } from '../api/authService'; // Use authService directly

export default function ContestSearch({ onContestFound }) {
  const [passcode, setPasscode] = useState('');
  const [error, setError] = useState('');

  const handleSearch = async (e) => {
    e.preventDefault();
    setError('');

    // Safely check if a valid token exists via authService
    const token = getToken();
    if (!token) {
      setError('Please log in to join private contests.');
      return;
    }

    try {
      // contestService passes through client.js, attaching the Authorization header automatically
      const contest = await contestService.joinByPasscode(passcode.trim()); //

      if (contest.hasAttempted) { //[cite: 4]
        setError('You have already completed this contest.'); //[cite: 4]
        return;
      }

      onContestFound(contest);
    } catch (err) {
      // Handles 401 (Unauthorized), 404 (Invalid Passcode), etc.
      setError(err.response?.data?.message || 'Contest not found or invalid passcode.'); //[cite: 4]
    }
  };

  return (
    <div className="contest-search-box">
      <form onSubmit={handleSearch} style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
        <input 
          type="text" 
          placeholder="Enter Passcode..." 
          value={passcode} 
          onChange={(e) => setPasscode(e.target.value)} 
          required 
          style={{
            flex: 1,
            padding: '0.6rem 0.8rem',
            borderRadius: '8px',
            border: '1px solid #cbd5e1',
            color: '#0f172a',
            backgroundColor: '#ffffff',
            fontSize: '0.85rem',
            fontWeight: '600',
            outline: 'none'
          }}
        />
        <button 
          type="submit"
          style={{
            background: '#ffffff',
            border: '1px solid #cbd5e1',
            padding: '0.6rem 1rem',
            borderRadius: '8px',
            fontWeight: 700,
            fontSize: '0.85rem',
            color: '#0f172a',
            cursor: 'pointer',
            whiteSpace: 'nowrap'
          }}
        >
          Join Private Contest
        </button>
      </form>
      {error && (
        <p style={{ color: '#b91c1c', fontSize: '0.82rem', marginTop: '0.5rem', fontWeight: '500' }}>
          {error}
        </p>
      )}
    </div>
  );
}