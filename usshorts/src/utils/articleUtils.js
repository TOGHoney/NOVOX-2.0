import winkNLP from 'wink-nlp';
import model from 'wink-eng-lite-web-model';

const nlp = winkNLP(model);
const { its } = nlp;

export const CATEGORIES = [
  { label: 'All', value: 'all' },
  { label: 'Technology', value: 'technology' },
  { label: 'Movies', value: 'movies' },
  { label: 'USA', value: 'usa' },
  { label: 'India', value: 'india' },
  { label: 'Japan', value: 'japan' },
  { label: 'China', value: 'china' },
  { label: 'Russia', value: 'russia' },
  { label: 'Sports', value: 'sports' },
  { label: 'Education', value: 'education' },
  { label: 'Politics', value: 'politics' },
  { label: 'Foreign Relations', value: 'foreign-relations' },
];

export const LANGUAGES = [
  { label: 'Spanish', code: 'es' },
  { label: 'Hindi', code: 'hi' },
  { label: 'French', code: 'fr' },
  { label: 'German', code: 'de' },
  { label: 'Italian', code: 'it' },
  { label: 'Japanese', code: 'ja' },
];

const AUXILIARY_VERBS = new Set([
  "am", "is", "are", "was", "were", "be", "been", "being",
  "have", "has", "had", "do", "does", "did", "can", "could",
  "shall", "should", "will", "would", "may", "might", "must"
]);

const STOP_WORDS = new Set(['the', 'a', 'an', 'is', 'are', 'was', 'were', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'it', 'this', 'that']);
const SHORT_EXCEPTIONS = new Set(['be', 'see', 'flee', 'free', 'knee', 'tree', 'go', 'do']);

export const tokenizeText = (text) => {
  return text ? text.toLowerCase().match(/\b[a-z]{3,}\b/g) || [] : [];
};

export const estimateCEFR = (word) => {
  const len = word.length;
  const commonA1 = ['a', 'an', 'the', 'in', 'on', 'at', 'go', 'see', 'their', 'they', 'them', 'he', 'she', 'it', 'my', 'his'];
  if (commonA1.includes(word.toLowerCase())) return 'A1';
  if (len <= 4) return 'A2';
  if (len <= 6) return 'B1';
  if (len <= 8) return 'B2';
  if (len <= 11) return 'C1';
  return 'C2';
};

const mapWinkPosToStandard = (posTag) => {
  switch (posTag) {
    case 'NOUN':
    case 'PROPN':
      return 'noun';
    case 'VERB':
    case 'AUX':
      return 'verb';
    case 'ADJ':
      return 'adjective';
    case 'ADV':
      return 'adverb';
    default:
      return 'noun';
  }
};

const detectPosBySuffix = (word) => {
  const w = word.toLowerCase();
  if (w.endsWith("ly") && w.length > 3) return "adverb";
  if (w.endsWith("ing") || w.endsWith("ed") || w.endsWith("ize") || w.endsWith("ise")) return "verb";
  if (w.endsWith("able") || w.endsWith("ible") || w.endsWith("ous") || w.endsWith("ful") || w.endsWith("less") || w.endsWith("ic") || w.endsWith("al")) return "adjective";
  if (w.endsWith("tion") || w.endsWith("sion") || w.endsWith("ment") || w.endsWith("ness") || w.endsWith("ity") || w.endsWith("ance") || w.endsWith("ence")) return "noun";
  return null;
};

const normalizeLemma = (word, pos) => {
  let w = word.toLowerCase().trim();
  if (SHORT_EXCEPTIONS.has(w)) return w;
  if (pos === "verb") {
    if (w.endsWith("ing")) {
      let stem = w.slice(0, -3);
      if (stem === "be") return "be";
      if (stem.length > 2 && stem[stem.length - 1] === stem[stem.length - 2]) {
        return stem.slice(0, -1);
      }
      const lastChar = stem[stem.length - 1];
      const vowels = ['a', 'e', 'i', 'o', 'u'];
      if (stem.length >= 3 && !vowels.includes(lastChar)) {
        return stem + "e";
      }
      return stem;
    }
    if (w.endsWith("ed")) {
      let stem = w.slice(0, -2);
      if (stem.length > 2 && stem[stem.length - 1] === stem[stem.length - 2]) {
        return stem.slice(0, -1);
      }
      return stem;
    }
  }
  if (w.endsWith("ies")) return w.slice(0, -3) + "y";
  if (w.endsWith("s") && !w.endsWith("ss")) return w.slice(0, -1);
  return w;
};

export const analyzeWordContext = (word, sentence) => {
  const cleanWord = word.toLowerCase().replace(/[^a-z]/g, '');
  const suffixPos = detectPosBySuffix(cleanWord);
  if (!sentence) {
    const fallbackPos = suffixPos || 'noun';
    return { pos: fallbackPos, lemma: normalizeLemma(cleanWord, fallbackPos) };
  }
  let detectedPOS = null;
  let detectedLemma = null;
  try {
    const doc = nlp.readDoc(sentence);
    const tokens = doc.tokens();
    tokens.each((token, index) => {
      const tokenVal = token.out().toLowerCase().replace(/[^a-z]/g, '');
      if (tokenVal === cleanWord) {
        const pos = token.out(its.pos);
        const winkLemma = token.out(its.lemma);
        detectedPOS = mapWinkPosToStandard(pos);
        const previousWords = [];
        for (let i = index - 3; i < index; i++) {
          if (i >= 0) {
            const t = tokens.itemAt(i);
            previousWords.push(t.out().toLowerCase().replace(/[^a-z]/g, ''));
          }
        }
        if (previousWords.some((w) => AUXILIARY_VERBS.has(w))) {
          detectedPOS = "verb";
        }
        detectedLemma = (winkLemma && winkLemma.length > 1) ? winkLemma : cleanWord;
      }
    });
  } catch (e) {
    console.error("NLP Analysis Error:", e);
  }
  const finalPOS = suffixPos || detectedPOS || 'noun';
  const finalLemma = detectedLemma ? normalizeLemma(detectedLemma, finalPOS) : normalizeLemma(cleanWord, finalPOS);
  return { pos: finalPOS, lemma: finalLemma };
};

export const fetchDatamuseConcepts = async (lemma, signal) => {
  try {
    const res = await fetch(`https://api.datamuse.com/words?ml=${encodeURIComponent(lemma)}&max=15`, { signal });
    if (res.ok) {
      const data = await res.json();
      return data.map(item => item.word.toLowerCase());
    }
  } catch (e) {
    // Fallback
  }
  return [];
};

export const evaluateContextConfidence = (sentence, definitionText, detectedPOS, meaningPOS, semanticConcepts = []) => {
  let posScore = (detectedPOS.toLowerCase() === meaningPOS.toLowerCase()) ? 40 : 10;
  if (!sentence || !definitionText) {
    return { score: posScore, confidence: posScore + 20 };
  }
  const sentenceWords = tokenizeText(sentence).filter(w => !STOP_WORDS.has(w));
  const defTextClean = definitionText.toLowerCase();
  let directMatches = 0;
  sentenceWords.forEach(w => {
    if (defTextClean.includes(w)) directMatches++;
  });
  const directScore = Math.min(40, directMatches * 15);
  let semanticMatches = 0;
  semanticConcepts.forEach(concept => {
    if (defTextClean.includes(concept) || sentence.toLowerCase().includes(concept)) {
      semanticMatches++;
    }
  });
  const semanticScore = Math.min(20, semanticMatches * 5);
  const totalConfidence = Math.min(98, Math.max(45, posScore + directScore + semanticScore));
  return { score: directScore + semanticScore, confidence: totalConfidence };
};

export const deriveWordForms = (word, meaningsList = []) => {
  const w = word.toLowerCase().trim();
  const availablePOS = meaningsList.map(m => m.partOfSpeech.toLowerCase());
  return {
    noun: availablePOS.includes('noun') ? w : '-',
    verb: availablePOS.includes('verb') ? w : '-',
    adjective: availablePOS.includes('adjective') ? w : '-',
    adverb: availablePOS.includes('adverb') ? w : '-'
  };
};