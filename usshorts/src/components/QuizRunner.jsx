import React, { useState, useEffect } from 'react';
import { contestService } from '../api/contestService';

export default function QuizRunner({ contest, onCompleted, onBack }) {
  const [answers, setAnswers] = useState({});
  const [timeTakenSeconds, setTimeTakenSeconds] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [modal, setModal] = useState(null); // Controls modal visibility & content

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeTakenSeconds((prev) => prev + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const handleSelectOption = (qIdx, oIdx) => {
    setAnswers({ ...answers, [qIdx]: oIdx });
  };

  const handleSubmit = async () => {
    if (isSubmitting) return;
    setIsSubmitting(true);

    try {
      const res = await contestService.submitContest(contest._id, answers, timeTakenSeconds);
      setModal({
        type: 'success',
        title: 'Contest Submitted! 🎉',
        message: `Your final score is ${res.score} points.`
      });
    } catch (err) {
      setIsSubmitting(false); // Reset submit button state on error
      const errorMessage = err.response?.data?.message || 'Error submitting test';
      
      setModal({
        type: 'error',
        title: 'Notice',
        message: errorMessage
      });
    }
  };

  const formatTime = (seconds) => {
    const m = Math.floor(seconds / 60).toString().padStart(2, '0');
    const s = (seconds % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  return (
    <div style={{ maxWidth: '800px', margin: '2rem auto', padding: '0 1rem', fontFamily: 'inherit', position: 'relative' }}>
      
      {/* Quiz Card Container */}
      <div style={{ 
        background: '#ffffff', 
        borderRadius: '16px', 
        padding: '2rem', 
        border: '1px solid #e2e8f0', 
        boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)' 
      }}>
        
        {/* Header Section */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', paddingBottom: '1rem', borderBottom: '1px solid #e2e8f0' }}>
          <h2 style={{ margin: 0, color: '#0f172a', fontSize: '1.75rem', fontWeight: 800 }}>
            {contest.title || 'Untitled Contest'}
          </h2>
          <div style={{ 
            background: '#f1f5f9', 
            padding: '0.5rem 1rem', 
            borderRadius: '8px', 
            fontWeight: 700, 
            color: '#334155',
            fontSize: '0.95rem' 
          }}>
            ⏱ Time: {formatTime(timeTakenSeconds)}
          </div>
        </div>

        {/* Questions List */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          {contest.questions && contest.questions.map((q, qIdx) => (
            <div key={q._id || qIdx} style={{ 
              background: '#f8fafc', 
              border: '1px solid #cbd5e1', 
              borderRadius: '12px', 
              padding: '1.5rem' 
            }}>
              <p style={{ margin: '0 0 1rem 0', fontWeight: 700, color: '#0f172a', fontSize: '1.1rem' }}>
                <span style={{ color: '#64748b', marginRight: '0.5rem' }}>{qIdx + 1}.</span> 
                {q.questionText}
              </p>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                {q.options.map((opt, oIdx) => {
                  const isSelected = answers[qIdx] === oIdx;
                  return (
                    <button
                      key={oIdx}
                      onClick={() => handleSelectOption(qIdx, oIdx)}
                      disabled={isSubmitting}
                      style={{
                        width: '100%',
                        textAlign: 'left',
                        padding: '0.85rem 1rem',
                        borderRadius: '8px',
                        border: isSelected ? '2px solid #3b82f6' : '1px solid #cbd5e1',
                        background: isSelected ? '#eff6ff' : '#ffffff',
                        color: isSelected ? '#1d4ed8' : '#334155',
                        fontWeight: isSelected ? 700 : 500,
                        fontSize: '0.95rem',
                        cursor: isSubmitting ? 'not-allowed' : 'pointer',
                        transition: 'all 0.2s ease'
                      }}
                    >
                      {opt}
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </div>

        {/* Submit Button */}
        <div style={{ marginTop: '2.5rem' }}>
          <button
            onClick={handleSubmit}
            disabled={isSubmitting}
            style={{
              width: '100%',
              background: '#0f172a',
              color: '#ffffff',
              border: 'none',
              padding: '1rem',
              borderRadius: '10px',
              fontWeight: 800,
              fontSize: '1.1rem',
              cursor: isSubmitting ? 'not-allowed' : 'pointer',
              opacity: isSubmitting ? 0.7 : 1,
              transition: 'opacity 0.2s'
            }}
          >
            {isSubmitting ? 'Submitting Answers...' : 'Submit Contest Answers'}
          </button>
        </div>

      </div>

      {/* Modern In-App Modal Overlay */}
      {modal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(15, 23, 42, 0.65)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000,
          backdropFilter: 'blur(4px)'
        }}>
          <div style={{
            background: '#ffffff',
            borderRadius: '16px',
            padding: '2rem',
            maxWidth: '420px',
            width: '90%',
            textAlign: 'center',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
            border: '1px solid #e2e8f0'
          }}>
            {/* Status Icon */}
            <div style={{
              width: '56px',
              height: '56px',
              borderRadius: '50%',
              backgroundColor: modal.type === 'success' ? '#dcfce7' : '#fee2e2',
              color: modal.type === 'success' ? '#166534' : '#991b1b',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '1.5rem',
              fontWeight: 800,
              margin: '0 auto 1.25rem auto'
            }}>
              {modal.type === 'success' ? '✓' : 'ℹ'}
            </div>

            <h3 style={{ margin: '0 0 0.5rem 0', color: '#0f172a', fontSize: '1.35rem', fontWeight: 800 }}>
              {modal.title}
            </h3>

            <p style={{ margin: '0 0 1.75rem 0', color: '#475569', fontSize: '0.95rem', lineHeight: '1.5', fontWeight: 500 }}>
              {modal.message}
            </p>

            {/* Action Buttons */}
            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'center' }}>
              {modal.type === 'success' ? (
                <button
                  onClick={() => {
                    if (onCompleted) onCompleted();
                  }}
                  style={{
                    flex: 1,
                    padding: '0.85rem 1rem',
                    background: '#0f172a',
                    color: '#ffffff',
                    border: 'none',
                    borderRadius: '8px',
                    fontWeight: 700,
                    cursor: 'pointer'
                  }}
                >
                  View Leaderboard
                </button>
              ) : (
                <>
                  <button
                    onClick={() => setModal(null)}
                    style={{
                      flex: 1,
                      padding: '0.85rem 1rem',
                      background: '#f1f5f9',
                      color: '#334155',
                      border: '1px solid #cbd5e1',
                      borderRadius: '8px',
                      fontWeight: 700,
                      cursor: 'pointer'
                    }}
                  >
                    Close
                  </button>
                  {onBack && (
                    <button
                      onClick={onBack}
                      style={{
                        flex: 1,
                        padding: '0.85rem 1rem',
                        background: '#0f172a',
                        color: '#ffffff',
                        border: 'none',
                        borderRadius: '8px',
                        fontWeight: 700,
                        cursor: 'pointer'
                      }}
                    >
                      Go Home
                    </button>
                  )}
                </>
              )}
            </div>

          </div>
        </div>
      )}

    </div>
  );
}