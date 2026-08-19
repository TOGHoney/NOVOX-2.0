import { useState } from 'react';
import { FiX, FiCheck, FiRefreshCw, FiVolume2, FiChevronRight, FiChevronLeft } from 'react-icons/fi';

// 1. Flashcard Deck Viewer Component
export function FlashcardViewer({ deck, title, onClose }) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isFlipped, setIsFlipped] = useState(false);

  if (!deck || deck.length === 0) {
    return (
      <div style={modalOverlayStyle}>
        <div style={modalContentStyle}>
          <h3>{title}</h3>
          <p>No words found for the selected date range.</p>
          <button onClick={onClose} style={btnPrimaryStyle}>Close</button>
        </div>
      </div>
    );
  }

  const currentCard = deck[currentIndex];

  const playAudio = (text) => {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'en-US';
      window.speechSynthesis.speak(utterance);
    }
  };

  return (
    <div style={modalOverlayStyle}>
      <div style={{ ...modalContentStyle, maxWidth: '480px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h3 style={{ margin: 0, color: '#0f172a' }}>{title} ({currentIndex + 1}/{deck.length})</h3>
          <button onClick={onClose} style={closeIconBtnStyle}><FiX size={18} /></button>
        </div>

        {/* Flip Card Container */}
        <div 
          onClick={() => setIsFlipped(!isFlipped)} 
          style={{
            minHeight: '240px',
            background: isFlipped ? '#fdf2f4' : '#fff',
            border: '2px solid #800020',
            borderRadius: '16px',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            alignItems: 'center',
            padding: '1.5rem',
            cursor: 'pointer',
            textAlign: 'center',
            boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.08)',
            transition: 'all 0.3s ease'
          }}
        >
          {!isFlipped ? (
            <div>
              <span style={{ fontSize: '0.75rem', color: '#800020', fontWeight: 700, textTransform: 'uppercase' }}>Word</span>
              <h2 style={{ fontSize: '2rem', margin: '0.5rem 0', color: '#0f172a' }}>{currentCard.word}</h2>
              {currentCard.phonetic && <p style={{ color: '#64748b', margin: 0 }}>{currentCard.phonetic}</p>}
              <span style={{ marginTop: '1rem', display: 'inline-block', fontSize: '0.75rem', color: '#94a3b8' }}>Click to reveal definition</span>
            </div>
          ) : (
            <div>
              <span style={{ fontSize: '0.75rem', color: '#800020', fontWeight: 700, textTransform: 'uppercase' }}>Translation & Meaning</span>
              <h3 style={{ fontSize: '1.6rem', margin: '0.5rem 0', color: '#800020' }}>{currentCard.translation || 'N/A'}</h3>
              {currentCard.definition && (
                <p style={{ fontSize: '0.9rem', color: '#334155', margin: '0.5rem 0', lineHeight: '1.4' }}>
                  {currentCard.definition}
                </p>
              )}
            </div>
          )}
        </div>

        {/* Card Controls */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '1.25rem' }}>
          <button 
            disabled={currentIndex === 0} 
            onClick={() => { setIsFlipped(false); setCurrentIndex((prev) => prev - 1); }}
            style={{ ...btnSecondaryStyle, opacity: currentIndex === 0 ? 0.5 : 1 }}
          >
            <FiChevronLeft size={16} /> Prev
          </button>
          
          <button onClick={() => playAudio(currentCard.word)} style={btnAudioStyle}>
            <FiVolume2 size={16} /> Listen
          </button>

          <button 
            disabled={currentIndex === deck.length - 1} 
            onClick={() => { setIsFlipped(false); setCurrentIndex((prev) => prev + 1); }}
            style={{ ...btnSecondaryStyle, opacity: currentIndex === deck.length - 1 ? 0.5 : 1 }}
          >
            Next <FiChevronRight size={16} />
          </button>
        </div>
      </div>
    </div>
  );
}

// 2. Interactive Quiz Modal Component
export function QuizModal({ questions, title, onClose }) {
  const [index, setIndex] = useState(0);
  const [selectedOption, setSelectedOption] = useState(null);
  const [score, setScore] = useState(0);
  const [isFinished, setIsFinished] = useState(false);

  if (!questions || questions.length === 0) {
    return (
      <div style={modalOverlayStyle}>
        <div style={modalContentStyle}>
          <h3>{title}</h3>
          <p>No saved words available to generate a quiz for this timeframe.</p>
          <button onClick={onClose} style={btnPrimaryStyle}>Close</button>
        </div>
      </div>
    );
  }

  const currentQ = questions[index];

  const handleOptionSelect = (option) => {
    if (selectedOption !== null) return; // Prevent double clicking
    setSelectedOption(option);
    if (option === currentQ.correctAnswer) {
      setScore((prev) => prev + 1);
    }
  };

  const handleNext = () => {
    setSelectedOption(null);
    if (index + 1 < questions.length) {
      setIndex((prev) => prev + 1);
    } else {
      setIsFinished(true);
    }
  };

  return (
    <div style={modalOverlayStyle}>
      <div style={{ ...modalContentStyle, maxWidth: '520px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h3 style={{ margin: 0, color: '#0f172a' }}>{title}</h3>
          <button onClick={onClose} style={closeIconBtnStyle}><FiX size={18} /></button>
        </div>

        {!isFinished ? (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', color: '#64748b', marginBottom: '0.5rem' }}>
              <span>Question {index + 1} of {questions.length}</span>
              <span>Score: {score}</span>
            </div>

            <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: '12px', border: '1px solid #e2e8f0', marginBottom: '1rem' }}>
              <span style={{ fontSize: '0.75rem', color: '#800020', fontWeight: 700 }}>WHAT IS THE TRANSLATION / MEANING OF:</span>
              <h2 style={{ margin: '0.25rem 0 0.5rem 0', color: '#0f172a' }}>"{currentQ.word}"</h2>
            </div>

            {/* Quiz Options */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
              {currentQ.options.map((opt, idx) => {
                let bgColor = '#fff';
                let borderColor = '#cbd5e1';
                let textColor = '#334155';

                if (selectedOption !== null) {
                  if (opt === currentQ.correctAnswer) {
                    bgColor = '#dcfce7';
                    borderColor = '#22c55e';
                    textColor = '#15803d';
                  } else if (opt === selectedOption) {
                    bgColor = '#fee2e2';
                    borderColor = '#ef4444';
                    textColor = '#b91c1c';
                  }
                }

                return (
                  <button
                    key={idx}
                    onClick={() => handleOptionSelect(opt)}
                    style={{
                      padding: '0.75rem 1rem',
                      textAlign: 'left',
                      background: bgColor,
                      border: `1.5px solid ${borderColor}`,
                      color: textColor,
                      borderRadius: '10px',
                      fontWeight: 600,
                      fontSize: '0.88rem',
                      cursor: selectedOption === null ? 'pointer' : 'default',
                      transition: 'all 0.2s ease'
                    }}
                  >
                    {opt}
                  </button>
                );
              })}
            </div>

            {selectedOption !== null && (
              <button onClick={handleNext} style={{ ...btnPrimaryStyle, width: '100%', marginTop: '1.25rem' }}>
                {index + 1 === questions.length ? 'See Results' : 'Next Question'}
              </button>
            )}
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: '1rem 0' }}>
            <h2>Quiz Completed! 🎉</h2>
            <p style={{ fontSize: '1.1rem', color: '#334155' }}>
              You scored <strong>{score}</strong> out of <strong>{questions.length}</strong>
            </p>
            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'center', marginTop: '1.5rem' }}>
              <button onClick={onClose} style={btnSecondaryStyle}>Close</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// Styling definitions matching global burgundy (#800020) theme
const modalOverlayStyle = {
  position: 'fixed',
  inset: 0,
  background: 'rgba(15, 23, 42, 0.65)',
  backdropFilter: 'blur(4px)',
  zIndex: 2000,
  display: 'flex',
  justifyContent: 'center',
  alignItems: 'center'
};

const modalContentStyle = {
  background: '#fff',
  width: '90%',
  borderRadius: '16px',
  padding: '1.5rem',
  boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)'
};

const closeIconBtnStyle = {
  background: 'transparent',
  border: 'none',
  cursor: 'pointer',
  color: '#64748b'
};

const btnPrimaryStyle = {
  background: '#800020',
  color: '#fff',
  border: 'none',
  padding: '0.6rem 1.2rem',
  borderRadius: '8px',
  fontWeight: 600,
  cursor: 'pointer'
};

const btnSecondaryStyle = {
  background: '#f1f5f9',
  color: '#0f172a',
  border: '1px solid #cbd5e1',
  padding: '0.5rem 1rem',
  borderRadius: '8px',
  fontWeight: 600,
  cursor: 'pointer',
  display: 'flex',
  alignItems: 'center',
  gap: '0.3rem'
};

const btnAudioStyle = {
  background: '#fdf2f4',
  color: '#800020',
  border: '1px solid #e0a8b0',
  padding: '0.5rem 0.9rem',
  borderRadius: '8px',
  fontWeight: 600,
  cursor: 'pointer',
  display: 'flex',
  alignItems: 'center',
  gap: '0.3rem'
};

