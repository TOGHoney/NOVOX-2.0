// src/utils/quizUtils.js

// Utility to parse and filter saved words by date ranges
export function filterWordsByTimeframe(words = [], timeframe = 'general') {
  if (!Array.isArray(words) || words.length === 0) return [];
  if (timeframe === 'general') return words;

  const now = new Date();
  let cutoff = new Date();

  switch (timeframe) {
    case 'yesterday': {
      const startOfYesterday = new Date(now);
      startOfYesterday.setDate(now.getDate() - 1);
      startOfYesterday.setHours(0, 0, 0, 0);

      const endOfYesterday = new Date(now);
      endOfYesterday.setDate(now.getDate() - 1);
      endOfYesterday.setHours(23, 59, 59, 999);

      return words.filter((item) => {
        const dateValue = item.createdAt || item.timestamp || item.date || item.created_at;
        if (!dateValue) return false;
        const d = new Date(dateValue);
        return d >= startOfYesterday && d <= endOfYesterday;
      });
    }
    case 'last_week':
      cutoff.setDate(now.getDate() - 7);
      break;
    case 'last_month':
      cutoff.setDate(now.getDate() - 30);
      break;
    case 'last_3_months':
      cutoff.setDate(now.getDate() - 90);
      break;
    case 'last_6_months':
      cutoff.setDate(now.getDate() - 180);
      break;
    default:
      return words;
  }

  return words.filter((item) => {
    const dateValue = item.createdAt || item.timestamp || item.date || item.created_at;
    if (!dateValue) return false;
    return new Date(dateValue) >= cutoff;
  });
}

// Filter words by custom date range
export function filterWordsByDateRange(words = [], startDateStr, endDateStr) {
  if (!Array.isArray(words) || words.length === 0) return [];
  if (!startDateStr && !endDateStr) return words;

  let start = startDateStr ? new Date(`${startDateStr}T00:00:00`) : new Date(0);
  if (isNaN(start.getTime())) {
    start = new Date(startDateStr);
    start.setHours(0, 0, 0, 0);
  }

  let end = endDateStr ? new Date(`${endDateStr}T23:59:59.999`) : new Date();
  if (isNaN(end.getTime())) {
    end = new Date(endDateStr);
    end.setHours(23, 59, 59, 999);
  }

  return words.filter((item) => {
    const dateValue = item.createdAt || item.timestamp || item.date || item.created_at;
    if (!dateValue) return false;
    const wordDate = new Date(dateValue);
    return wordDate >= start && wordDate <= end;
  });
}

// Generate 4-option multiple-choice quiz questions
export const generateQuizQuestions = (filteredWords = [], allWords = []) => {
  if (!Array.isArray(filteredWords) || filteredWords.length === 0) return [];

  const pool = Array.isArray(allWords) && allWords.length > 0 ? allWords : filteredWords;

  return filteredWords.map((item) => {
    const correctAnswer = item.translation || item.definition || 'N/A';

    // Distractors from all saved words (unique and distinct from correct answer)
    const uniqueDistractors = Array.from(
      new Set(
        pool
          .filter((w) => w.word !== item.word)
          .map((w) => w.translation || w.definition)
          .filter((val) => val && val !== correctAnswer)
      )
    );

    // Shuffle and take up to 3 distractors
    const selectedDistractors = uniqueDistractors.sort(() => 0.5 - Math.random()).slice(0, 3);

    // Combine correct answer + distractors and shuffle final 4 choices
    const options = [correctAnswer, ...selectedDistractors].sort(() => 0.5 - Math.random());

    return {
      word: item.word,
      correctAnswer,
      contextSentence: item.contextSentence || item.definition || '',
      options
    };
  });
};