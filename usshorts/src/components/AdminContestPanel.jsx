import React, { useState, useEffect } from 'react';
import { contestService } from '../api/contestService';

export default function AdminContestPanel() {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [isPublic, setIsPublic] = useState(true);
  const [passcode, setPasscode] = useState('');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [questions, setQuestions] = useState([
    { questionText: '', options: ['', '', '', ''], correctAnswer: 0 }
  ]);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [loading, setLoading] = useState(false);

  // State for hosted contests
  const [contests, setContests] = useState([]);
  const [contestsLoading, setContestsLoading] = useState(true);

  // Fetch hosted contests with robust fallback parsing
  const fetchContests = async () => {
    try {
      setContestsLoading(true);
      let list = [];
      
      // Try admin/all contests endpoint first
      try {
        const response = await contestService.getAllContests();
        list = response?.data?.contests || response?.data?.data || response?.data || response || [];
      } catch (err) {
        console.warn('getAllContests failed, falling back to public contests:', err);
      }

      // If list is empty, fallback to public contests endpoint
      if (!Array.isArray(list) || list.length === 0) {
        const publicRes = await contestService.getPublicContests();
        list = publicRes?.data?.contests || publicRes?.data?.data || publicRes?.data || publicRes || [];
      }

      setContests(Array.isArray(list) ? list : []);
    } catch (err) {
      console.error('Failed to fetch contests:', err);
      setContests([]);
    } finally {
      setContestsLoading(false);
    }
  };

  useEffect(() => {
    fetchContests();
  }, []);

  const handleAddQuestion = () => {
    setQuestions([
      ...questions,
      { questionText: '', options: ['', '', '', ''], correctAnswer: 0 }
    ]);
  };

  const handleRemoveQuestion = (index) => {
    if (questions.length === 1) return;
    setQuestions(questions.filter((_, i) => i !== index));
  };

  const handleQuestionChange = (index, value) => {
    const updated = [...questions];
    updated[index].questionText = value;
    setQuestions(updated);
  };

  const handleOptionChange = (qIndex, oIndex, value) => {
    const updated = [...questions];
    updated[qIndex].options[oIndex] = value;
    setQuestions(updated);
  };

  const handleCorrectAnswerChange = (qIndex, value) => {
    const updated = [...questions];
    updated[qIndex].correctAnswer = parseInt(value, 10);
    setQuestions(updated);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setMessage({ type: '', text: '' });
    setLoading(true);

    const formattedQuestions = questions.map((q) => ({
      questionText: q.questionText,
      options: q.options,
      correctOptionIndex: q.correctAnswer,
      points: 1
    }));

    const payload = {
      title,
      description,
      isPublic,
      passcode: isPublic ? undefined : passcode,
      startTime: startTime || new Date().toISOString(),
      endTime: endTime || new Date(Date.now() + 86400000 * 7).toISOString(),
      questions: formattedQuestions
    };

    try {
      await contestService.createContest(payload);
      setMessage({ type: 'success', text: 'Contest created and published successfully!' });
      setTitle('');
      setDescription('');
      setPasscode('');
      setQuestions([{ questionText: '', options: ['', '', '', ''], correctAnswer: 0 }]);
      
      // Refresh list immediately after creation
      fetchContests();
    } catch (err) {
      setMessage({
        type: 'error',
        text: err.response?.data?.message || err.message || 'Failed to create contest.'
      });
    } finally {
      setLoading(false);
    }
  };

  // Handle Delete Contest
  const handleDeleteContest = async (id) => {
    if (!window.confirm('Are you sure you want to delete this contest?')) return;
    try {
      await contestService.deleteContest(id);
      setContests((prev) => prev.filter((c) => (c._id || c.id) !== id));
    } catch (err) {
      alert(err.response?.data?.message || err.message || 'Failed to delete contest.');
    }
  };

  return (
    <div style={{ maxWidth: '900px', margin: '0 auto', padding: '2rem' }}>
      
      {/* FORM: CREATE CONTEST */}
      <div style={{ background: '#ffffff', borderRadius: '16px', padding: '2rem', border: '1px solid #e2e8f0', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)', marginBottom: '2.5rem' }}>
        <h2 style={{ margin: '0 0 1.5rem 0', color: '#0f172a', fontSize: '1.75rem', fontWeight: 800 }}>
          Host New MCQ Contest
        </h2>

        {message.text && (
          <div style={{
            padding: '0.85rem 1rem',
            borderRadius: '8px',
            marginBottom: '1.5rem',
            fontWeight: 600,
            fontSize: '0.9rem',
            backgroundColor: message.type === 'success' ? '#dcfce7' : '#fee2e2',
            color: message.type === 'success' ? '#166534' : '#991b1b',
            border: `1px solid ${message.type === 'success' ? '#bbf7d0' : '#fecaca'}`
          }}>
            {message.text}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div>
            <label style={labelStyle}>Contest Title</label>
            <input
              type="text"
              placeholder="e.g. Weekly Vocabulary Challenge"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
              style={inputStyle}
            />
          </div>

          <div>
            <label style={labelStyle}>Description</label>
            <textarea
              placeholder="Brief description of the contest..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
              style={{ ...inputStyle, resize: 'vertical' }}
            />
          </div>

          <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: '10px', border: '1px solid #e2e8f0' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontWeight: 700, color: '#0f172a', fontSize: '0.9rem' }}>
              <input
                type="checkbox"
                checked={isPublic}
                onChange={(e) => setIsPublic(e.target.checked)}
                style={{ width: '16px', height: '16px' }}
              />
              Public Contest (Visible directly on Home screen)
            </label>

            {!isPublic && (
              <div style={{ marginTop: '0.85rem' }}>
                <label style={labelStyle}>Private Contest Passcode</label>
                <input
                  type="text"
                  placeholder="e.g. SECRET123"
                  value={passcode}
                  onChange={(e) => setPasscode(e.target.value)}
                  required={!isPublic}
                  style={inputStyle}
                />
              </div>
            )}
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div>
              <label style={labelStyle}>Start Time</label>
              <input
                type="datetime-local"
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                style={inputStyle}
              />
            </div>
            <div>
              <label style={labelStyle}>End Time</label>
              <input
                type="datetime-local"
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                style={inputStyle}
              />
            </div>
          </div>

          <div style={{ marginTop: '1rem' }}>
            <h3 style={{ fontSize: '1.25rem', color: '#0f172a', margin: '0 0 1rem 0', fontWeight: 800 }}>
              Questions ({questions.length})
            </h3>

            {questions.map((q, qIndex) => (
              <div key={qIndex} style={{ background: '#f8fafc', border: '1px solid #cbd5e1', borderRadius: '12px', padding: '1.25rem', marginBottom: '1.25rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                  <span style={{ fontWeight: 800, color: '#0f172a', fontSize: '0.95rem' }}>
                    Question {qIndex + 1}
                  </span>
                  {questions.length > 1 && (
                    <button
                      type="button"
                      onClick={() => handleRemoveQuestion(qIndex)}
                      style={{ background: 'none', border: 'none', color: '#ef4444', fontWeight: 700, cursor: 'pointer', fontSize: '0.82rem' }}
                    >
                      Remove
                    </button>
                  )}
                </div>

                <input
                  type="text"
                  placeholder="Enter question text..."
                  value={q.questionText}
                  onChange={(e) => handleQuestionChange(qIndex, e.target.value)}
                  required
                  style={{ ...inputStyle, marginBottom: '0.85rem' }}
                />

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginBottom: '0.85rem' }}>
                  {q.options.map((opt, oIndex) => (
                    <input
                      key={oIndex}
                      type="text"
                      placeholder={`Option ${oIndex + 1}`}
                      value={opt}
                      onChange={(e) => handleOptionChange(qIndex, oIndex, e.target.value)}
                      required
                      style={inputStyle}
                    />
                  ))}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <label style={{ fontSize: '0.85rem', fontWeight: 700, color: '#475569' }}>Correct Answer:</label>
                  <select
                    value={q.correctAnswer}
                    onChange={(e) => handleCorrectAnswerChange(qIndex, e.target.value)}
                    style={{ ...inputStyle, width: 'auto', padding: '0.4rem 0.8rem' }}
                  >
                    {q.options.map((_, idx) => (
                      <option key={idx} value={idx}>
                        Option {idx + 1}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            ))}

            <button
              type="button"
              onClick={handleAddQuestion}
              style={{
                width: '100%',
                background: '#ffffff',
                border: '1.5px dashed #cbd5e1',
                padding: '0.75rem',
                borderRadius: '10px',
                fontWeight: 700,
                fontSize: '0.9rem',
                color: '#0f172a',
                cursor: 'pointer',
                marginBottom: '1.5rem'
              }}
            >
              + Add Another Question
            </button>
          </div>

          <button
            type="submit"
            disabled={loading}
            style={{
              background: '#0f172a',
              color: '#ffffff',
              border: 'none',
              padding: '0.9rem',
              borderRadius: '10px',
              fontWeight: 800,
              fontSize: '1rem',
              cursor: loading ? 'not-allowed' : 'pointer',
              opacity: loading ? 0.7 : 1
            }}
          >
            {loading ? 'Publishing Contest...' : 'Publish Contest'}
          </button>
        </form>
      </div>

      {/* SECTION: HOSTED CONTESTS LIST */}
      <div style={{ background: '#ffffff', borderRadius: '16px', padding: '2rem', border: '1px solid #e2e8f0', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)' }}>
        <h2 style={{ margin: '0 0 1.25rem 0', color: '#0f172a', fontSize: '1.5rem', fontWeight: 800 }}>
          Hosted Contests
        </h2>

        {contestsLoading ? (
          <p style={{ color: '#64748b', fontSize: '0.9rem' }}>Loading contests...</p>
        ) : contests.length === 0 ? (
          <p style={{ color: '#64748b', fontSize: '0.9rem' }}>No contests hosted yet.</p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {contests.map((contest) => {
              const contestId = contest._id || contest.id;
              return (
                <div
                  key={contestId}
                  style={{
                    background: '#f8fafc',
                    border: '1px solid #cbd5e1',
                    borderRadius: '12px',
                    padding: '1.25rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    gap: '1rem'
                  }}
                >
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginBottom: '0.25rem' }}>
                      <h4 style={{ margin: 0, fontSize: '1.1rem', color: '#0f172a', fontWeight: 800 }}>
                        {contest.title}
                      </h4>
                      <span style={{
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        padding: '0.2rem 0.5rem',
                        borderRadius: '6px',
                        backgroundColor: contest.isPublic !== false ? '#dcfce7' : '#fef3c7',
                        color: contest.isPublic !== false ? '#166534' : '#92400e'
                      }}>
                        {contest.isPublic !== false ? 'Public' : 'Private'}
                      </span>
                    </div>

                    <p style={{ margin: '0 0 0.5rem 0', fontSize: '0.85rem', color: '#64748b' }}>
                      {contest.description || 'No description provided.'}
                    </p>

                    <div style={{ display: 'flex', gap: '1rem', fontSize: '0.8rem', color: '#334155', fontWeight: 600 }}>
                      <span>Questions: {contest.questions?.length || 0}</span>
                      {!contest.isPublic && contest.passcode && (
                        <span>Passcode: <code style={{ background: '#e2e8f0', padding: '0.1rem 0.3rem', borderRadius: '4px' }}>{contest.passcode}</code></span>
                      )}
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() => handleDeleteContest(contestId)}
                    style={{
                      background: '#fee2e2',
                      border: '1px solid #fca5a5',
                      color: '#991b1b',
                      padding: '0.5rem 0.85rem',
                      borderRadius: '8px',
                      fontWeight: 700,
                      fontSize: '0.85rem',
                      cursor: 'pointer'
                    }}
                  >
                    Delete
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>

    </div>
  );
}

const labelStyle = {
  display: 'block',
  fontSize: '0.85rem',
  fontWeight: 700,
  color: '#334155',
  marginBottom: '0.35rem'
};

const inputStyle = {
  width: '100%',
  padding: '0.65rem 0.85rem',
  borderRadius: '8px',
  border: '1px solid #cbd5e1',
  color: '#0f172a',
  backgroundColor: '#ffffff',
  fontSize: '0.875rem',
  fontWeight: '600',
  outline: 'none',
  boxSizing: 'border-box'
};