import React, { useState, useEffect, useRef } from 'react';
import { FiVolume2, FiBookOpen, FiX } from 'react-icons/fi';
import { HiSparkles } from 'react-icons/hi2';
import { LANGUAGES } from '../utils/articleUtils';

export const InteractiveText = ({ text, onSelectWord, style }) => {
  if (!text) return null;
  const words = text.split(/(\s+)/);
  const handleWordClick = (e, word) => {
    e.stopPropagation();
    const cleanWord = word.replace(/[^a-zA-Z]/g, '');
    if (cleanWord.length > 1) {
      onSelectWord(cleanWord, text);
    }
  };
  return (
    <span style={style}>
      {words.map((chunk, index) => {
        const isWord = /^[a-zA-Z]+$/.test(chunk.replace(/[^a-zA-Z]/g, ''));
        if (isWord) {
          return (
            <span
              key={index}
              onClick={(e) => handleWordClick(e, chunk)}
              style={{
                cursor: 'pointer',
                transition: 'background-color 0.15s ease',
                borderRadius: '2px',
                display: 'inline'
              }}
              className="interactive-word"
              title="Click for Word Intelligence"
            >
              {chunk}
            </span>
          );
        }
        return chunk;
      })}
    </span>
  );
};

export const WordIntelligencePanel = ({
  targetLang,
  handleLangChange,
  onClose,
  selectedWord,
  detailsLoading,
  wordDetails,
  playAudio,
  translation,
  contextSentence,
  onSaveWord
}) => {
  // Track words saved during this session to prevent duplicate calls
  const savedWordsRef = useRef(new Set());

  // Auto-save word whenever a word is selected and details finish loading
  useEffect(() => {
    if (selectedWord && !detailsLoading && wordDetails && onSaveWord) {
      const wordKey = `${selectedWord.toLowerCase()}_${targetLang}`;
      if (!savedWordsRef.current.has(wordKey)) {
        savedWordsRef.current.add(wordKey);

        onSaveWord({
          word: selectedWord,
          translation: translation || '',
          contextSentence: contextSentence || '',
          phonetic: wordDetails?.phonetic || '',
          cefr: wordDetails?.cefr || 'B1',
          definition: wordDetails?.primaryMeanings?.[0]?.definitions?.[0]?.definition || ''
        });
      }
    }
  }, [selectedWord, detailsLoading, wordDetails, translation, contextSentence, targetLang, onSaveWord]);

  return (
    <div style={{
      background: 'rgba(235, 240, 246, 0.92)',
      backdropFilter: 'blur(16px)',
      WebkitBackdropFilter: 'blur(16px)',
      border: '1px solid rgba(255, 255, 255, 0.7)',
      borderRadius: '20px',
      padding: '1.25rem',
      boxShadow: '0 20px 40px rgba(15, 23, 42, 0.15)',
      color: '#1e293b',
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.85rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
          <HiSparkles size={18} color="#38bdf8" />
          <span style={{ fontSize: '0.88rem', fontWeight: 700, color: '#0f172a' }}>
            Word Intelligence
          </span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
          <select
            value={targetLang}
            onChange={handleLangChange}
            style={{ padding: '0.15rem 0.4rem', borderRadius: '6px', fontSize: '0.7rem', background: 'rgba(255, 255, 255, 0.8)', color: '#1e293b', border: '1px solid rgba(0,0,0,0.08)', fontWeight: 600, cursor: 'pointer' }}
          >
            {LANGUAGES.map(lang => (
              <option key={lang.code} value={lang.code}>{lang.label}</option>
            ))}
          </select>
          {onClose && (
            <button onClick={onClose} style={{ border: 'none', background: 'rgba(0,0,0,0.05)', borderRadius: '50%', width: '22px', height: '22px', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: '#64748b' }}>
              <FiX size={13} />
            </button>
          )}
        </div>
      </div>
      {selectedWord ? (
        detailsLoading ? (
          <div style={{ padding: '1.5rem 0', textAlign: 'center', color: '#64748b', fontSize: '0.82rem' }}>
            Analyzing context...
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: '0.5rem' }}>
              <h2 style={{ margin: 0, fontSize: '1.65rem', fontWeight: 800, color: '#09090b', lineHeight: 1.1 }}>
                {selectedWord}
              </h2>
              <span style={{ fontSize: '0.68rem', fontWeight: 700, background: 'rgba(255, 255, 255, 0.8)', color: '#475569', padding: '0.2rem 0.45rem', borderRadius: '6px', flexShrink: 0 }}>
                CEFR: {wordDetails?.cefr || 'B1'}
              </span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span style={{ fontSize: '0.82rem', color: '#64748b', fontFamily: 'monospace' }}>
                {wordDetails?.phonetic}
              </span>
              <button onClick={() => playAudio(wordDetails?.audioUrl)} style={{ border: 'none', background: '#fff', color: '#0f172a', padding: '0.22rem 0.55rem', borderRadius: '6px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.3rem', fontSize: '0.72rem', fontWeight: 700 }}>
                <FiVolume2 size={12} /> Listen
              </button>
            </div>
            <div style={{ fontSize: '0.98rem', fontWeight: 600, color: '#0f172a' }}>
              Translation: <strong>{translation}</strong>
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', marginBottom: '0.4rem', color: '#475569' }}>
                <FiBookOpen size={13} />
                <span style={{ fontSize: '0.68rem', fontWeight: 800, textTransform: 'uppercase' }}>
                  MEANING IN CONTEXT
                </span>
              </div>
              {wordDetails?.primaryMeanings?.map((meaning, mIdx) => (
                <div key={mIdx}>
                  <div style={{ fontSize: '0.72rem', fontWeight: 800, color: '#1e3a8a', textTransform: 'uppercase', marginBottom: '0.3rem' }}>
                    {meaning.partOfSpeech}
                  </div>
                  <ol style={{ margin: 0, paddingLeft: '1.1rem', fontSize: '0.8rem', color: '#334155', lineHeight: 1.4 }}>
                    {meaning.definitions.map((def, dIdx) => (
                      <li key={dIdx} style={{ marginBottom: '0.35rem' }}>
                        {def.definition}
                      </li>
                    ))}
                  </ol>
                </div>
              ))}
            </div>
          </div>
        )
      ) : (
        <p style={{ fontSize: '0.78rem', color: '#64748b', margin: '0.5rem 0', fontStyle: 'italic' }}>
          Click any word in the article to analyze.
        </p>
      )}
    </div>
  );
};