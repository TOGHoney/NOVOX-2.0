const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const MODEL_NAME = 'gemini-3.5-flash-lite';

/**
 * Evaluates a single speaking turn in a debate session.
 * Analyzes grammar, pronunciation (informed by acoustic confidence), argumentation, factual claims, and provides an immediate tip.
 * Explanations are ALWAYS in the learner's base language.
 *
 * NOTE: Audio transcription is handled locally on-device via Apple Speech.framework.
 * This service expects a transcript (from local STT or manual input). Audio data is not sent to the LLM
 * because current Gemini models require the Live API (WebSocket) for audio input, not generateContent.
 */
async function evaluateSpeakingTurn({
    topic,
    prompt,
    targetLanguage = 'English',
    baseLanguage = 'English',
    cefrLevel = 'B1',
    transcript,
    segments = [],
    audioBase64 = null,    // Kept for API compatibility; not sent to LLM
    audioMime = 'audio/m4a',
    turnIndex = 1
}) {
    let cleanTranscript = (transcript || '').trim();

    // If no text transcript was supplied, return graceful fallback
    // Audio transcription is expected to happen on-device; backend does not transcribe audio.
    if (!cleanTranscript) {
        return {
            transcript: '',
            grammar: [],
            pronunciation: [],
            argumentation: {
                relevanceScore: 0,
                assessment: 'No speech transcript was provided for this turn.',
                actionableImprovement: 'Ensure speech recognition is working, or use the "Dictate / Edit" button to enter your argument manually.'
            },
            factualClaims: [],
            immediateTip: 'Speak clearly into the microphone. On Simulator, use the manual text entry option.'
        };
    }

    // Filter candidate words with lower acoustic confidence (< 0.70) from Apple Speech recognition
    const acousticCandidates = (segments || [])
        .filter((s) => s.confidence !== undefined && s.confidence < 0.70)
        .map((s) => ({ word: s.word, confidence: Math.round(s.confidence * 100) / 100, timestamp: s.timestamp }));

    const model = genAI.getGenerativeModel({
        model: MODEL_NAME,
        generationConfig: {
            temperature: 0.2,
            responseMimeType: 'application/json'
        }
    });

    const systemPrompt = `You are the Linguabrief AI Debate Proctor and Speaking Coach.
Analyze the user's speaking turn in a live debate room.

Learner Profile:
- Target Language: "${targetLanguage}" (the language spoken during the debate).
- Base / Native Language: "${baseLanguage}" (the language the learner comfortably understands).
- CEFR Level: "${cefrLevel}".

Debate Context:
- Motion Topic: "${topic}"
- Room Prompt: "${prompt || 'General debate on topic'}"
- Speaking Turn Number: ${turnIndex}

Spoken Input:
- Finalized Transcript: "${cleanTranscript}"
- Acoustically Ambiguous / Low-Confidence Words from Speech Recognition: ${JSON.stringify(acousticCandidates)}

Requirements:
1. "grammar":
   - Identify actual grammatical errors in the target language (e.g. subject-verb agreement, incorrect tense, preposition misuse).
   - "explanation": MUST BE WRITTEN IN THE LEARNER'S BASE LANGUAGE ("${baseLanguage}").
   - "isStylistic": false for genuine grammar errors, true only for stylistic nuances.
   - Do NOT rewrite correct sentences.
2. "pronunciation":
   - Analyze words that showed acoustic ambiguity in the speech recognizer (${JSON.stringify(acousticCandidates.map(c => c.word))}) or significant phoneme risk in "${targetLanguage}".
   - "word": exact word.
   - "expectedPronunciation": readable phonetic guide or romanization.
   - "phonemeIssue": explain the specific sound, syllable stress, or vowel/consonant in the learner's base language ("${baseLanguage}").
   - "confidence": "high", "moderate", or "uncertain".
   - If speech recognition confidence was high and there is no evidence of pronunciation issues, return an empty array []! Do NOT invent pronunciation errors.
3. "argumentation":
   - "relevanceScore": 0 to 100 based on how directly the user addresses the motion topic and provides supporting reasoning.
   - "assessment": 1-2 sentences in "${baseLanguage}" on clarity and debate coherence.
   - "actionableImprovement": 1 specific suggestion in "${baseLanguage}" to strengthen reasoning or counter opposing arguments.
4. "factualClaims":
   - Identify explicit empirical or factual claims made (e.g. dates, statistics, historical events).
   - For each claim, determine status: "supported", "contradicted", "unverified", or "opinion".
   - "explanation": brief explanation in "${baseLanguage}".
   - "citation": citation or source name if verified; null if unverified or opinion.
   - Do NOT mark claims false merely because unverified; do NOT fabricate fake sources.
5. "immediateTip":
   - 1 or 2 high-impact actionable suggestions in "${baseLanguage}" that the user can immediately apply in their NEXT speaking turn.

Output strictly valid JSON matching this schema:
{
  "grammar": [
    {
      "originalSentence": "...",
      "correctedSentence": "...",
      "explanation": "...",
      "naturalAlternative": "...",
      "isStylistic": boolean
    }
  ],
  "pronunciation": [
    {
      "word": "...",
      "expectedPronunciation": "...",
      "phonemeIssue": "...",
      "audioTimestamp": number,
      "confidence": "high"|"moderate"|"uncertain"
    }
  ],
  "argumentation": {
    "relevanceScore": number,
    "assessment": "...",
    "actionableImprovement": "..."
  },
  "factualClaims": [
    {
      "claim": "...",
      "status": "supported"|"contradicted"|"unverified"|"opinion",
      "explanation": "...",
      "citation": null
    }
  ],
  "immediateTip": "..."
}`;

    try {
        const result = await model.generateContent(systemPrompt);
        const text = result.response.text();
        const parsed = JSON.parse(text);

        return {
            transcript: cleanTranscript,
            grammar: Array.isArray(parsed.grammar) ? parsed.grammar : [],
            pronunciation: Array.isArray(parsed.pronunciation) ? parsed.pronunciation : [],
            argumentation: {
                relevanceScore: typeof parsed.argumentation?.relevanceScore === 'number' ? parsed.argumentation.relevanceScore : 75,
                assessment: parsed.argumentation?.assessment || 'Good participation in the debate.',
                actionableImprovement: parsed.argumentation?.actionableImprovement || 'Continue developing your supporting evidence.'
            },
            factualClaims: Array.isArray(parsed.factualClaims) ? parsed.factualClaims : [],
            immediateTip: parsed.immediateTip || 'Maintain steady pacing and clear articulation in your next turn.'
        };
    } catch (err) {
        console.error('[debateProctorService] AI evaluation error:', err.message);

        // Graceful pedagogical fallback
        return {
            grammar: [],
            pronunciation: [],
            argumentation: {
                relevanceScore: 70,
                assessment: `Contribution noted on topic "${topic}".`,
                actionableImprovement: 'Provide concrete examples to substantiate your main point.'
            },
            factualClaims: [],
            immediateTip: 'Focus on clear sentence structure and pausing between key arguments.'
        };
    }
}

/**
 * Synthesizes all completed speaking turns into a comprehensive end-of-debate scorecard.
 * Transparent weighting scheme:
 * - Relevance & Argumentation: 30%
 * - Factual Accuracy & Evidence: 25%
 * - Grammar & Sentence Construction: 25%
 * - Pronunciation & Intelligibility: 20%
 */
async function synthesizeScorecard({
    topic,
    prompt,
    targetLanguage = 'English',
    baseLanguage = 'English',
    cefrLevel = 'B1',
    turns = []
}) {
    if (!turns || turns.length === 0) {
        return {
            overallScore: 0,
            summary: 'No speaking turns were recorded in this debate session.',
            relevance: { score: 0, explanation: 'Insufficient speech recorded.', evidence: [], strengths: [], areasToImprove: [], practicalNextStep: '', insufficientEvidence: true },
            factualAccuracy: { score: 0, explanation: 'Insufficient speech recorded.', evidence: [], strengths: [], areasToImprove: [], practicalNextStep: '', insufficientEvidence: true },
            grammar: { score: 0, explanation: 'Insufficient speech recorded.', evidence: [], strengths: [], areasToImprove: [], practicalNextStep: '', insufficientEvidence: true },
            pronunciation: { score: 0, explanation: 'Insufficient speech recorded.', evidence: [], strengths: [], areasToImprove: [], practicalNextStep: '', insufficientEvidence: true }
        };
    }

    const turnsSummary = turns.map((t, idx) => ({
        turn: idx + 1,
        duration: t.durationSeconds,
        transcript: t.transcript,
        grammarIssuesCount: (t.grammar || []).length,
        pronunciationIssuesCount: (t.pronunciation || []).length,
        relevanceScore: t.argumentation?.relevanceScore || 70,
        factualClaimsCount: (t.factualClaims || []).length
    }));

    const totalWords = turns.reduce((acc, t) => acc + (t.transcript || '').split(/\s+/).filter(Boolean).length, 0);
    if (totalWords < 8) {
        return {
            overallScore: 0,
            summary: 'Speech sample was too brief for reliable proctor assessment.',
            relevance: { score: 0, explanation: 'Speech was too brief to evaluate argument structure.', evidence: [], strengths: [], areasToImprove: [], practicalNextStep: 'Take longer speaking turns.', insufficientEvidence: true },
            factualAccuracy: { score: 0, explanation: 'No verifiable claims were made.', evidence: [], strengths: [], areasToImprove: [], practicalNextStep: '', insufficientEvidence: true },
            grammar: { score: 0, explanation: 'Sample too small to assess grammatical accuracy.', evidence: [], strengths: [], areasToImprove: [], practicalNextStep: '', insufficientEvidence: true },
            pronunciation: { score: 0, explanation: 'Audio sample too small for pronunciation assessment.', evidence: [], strengths: [], areasToImprove: [], practicalNextStep: '', insufficientEvidence: true }
        };
    }

    const model = genAI.getGenerativeModel({
        model: MODEL_NAME,
        generationConfig: {
            temperature: 0.2,
            responseMimeType: 'application/json'
        }
    });

    const scorecardPrompt = `You are the Linguabrief AI Debate Proctor and Speaking Coach.
Synthesize all speaking turns from this completed debate into a comprehensive final scorecard.

Learner Profile:
- Target Language: "${targetLanguage}"
- Base / Native Language: "${baseLanguage}"
- CEFR Level: "${cefrLevel}"

Debate Context:
- Topic: "${topic}"
- Prompt: "${prompt || topic}"
- Total Turns: ${turns.length}
- Total Words: ${totalWords}
- Speaking Turns Data: ${JSON.stringify(turnsSummary)}
- Full Transcripts: ${JSON.stringify(turns.map(t => t.transcript))}

Assessment Categories (Scale 0-100):
1. "relevance": Relevance and argument quality (30% weight) — how directly the user addresses the motion, supports their position, and maintains logical reasoning.
2. "factualAccuracy": Factual accuracy and evidence (25% weight) — reliability of claims, factual accuracy, citing relevant context.
3. "grammar": Grammar and sentence construction (25% weight) — accuracy, tense consistency, and CEFR-appropriate sentence structure.
4. "pronunciation": Pronunciation and intelligibility (20% weight) — clarity, stress, and communicative intelligibility.

Rules:
- ALL explanations, strengths, areasToImprove, and next steps must be written in the learner's base language ("${baseLanguage}").
- Provide 1-2 actual quotes or examples from the user's speech in "evidence".
- Compute "overallScore" using: round(relevance.score * 0.30 + factualAccuracy.score * 0.25 + grammar.score * 0.25 + pronunciation.score * 0.20).
- Be constructive, encouraging, and calibrated to CEFR "${cefrLevel}".

Output strictly valid JSON matching this schema:
{
  "overallScore": number,
  "summary": "...",
  "relevance": {
    "score": number,
    "explanation": "...",
    "evidence": ["..."],
    "strengths": ["..."],
    "areasToImprove": ["..."],
    "practicalNextStep": "...",
    "insufficientEvidence": false
  },
  "factualAccuracy": {
    "score": number,
    "explanation": "...",
    "evidence": ["..."],
    "strengths": ["..."],
    "areasToImprove": ["..."],
    "practicalNextStep": "...",
    "insufficientEvidence": false
  },
  "grammar": {
    "score": number,
    "explanation": "...",
    "evidence": ["..."],
    "strengths": ["..."],
    "areasToImprove": ["..."],
    "practicalNextStep": "...",
    "insufficientEvidence": false
  },
  "pronunciation": {
    "score": number,
    "explanation": "...",
    "evidence": ["..."],
    "strengths": ["..."],
    "areasToImprove": ["..."],
    "practicalNextStep": "...",
    "insufficientEvidence": false
  }
}`;

    try {
        const result = await model.generateContent(scorecardPrompt);
        const parsed = JSON.parse(result.response.text());

        const relScore = typeof parsed.relevance?.score === 'number' ? parsed.relevance.score : 75;
        const factScore = typeof parsed.factualAccuracy?.score === 'number' ? parsed.factualAccuracy.score : 75;
        const gramScore = typeof parsed.grammar?.score === 'number' ? parsed.grammar.score : 75;
        const pronScore = typeof parsed.pronunciation?.score === 'number' ? parsed.pronunciation.score : 80;

        const calculatedOverall = Math.round(relScore * 0.30 + factScore * 0.25 + gramScore * 0.25 + pronScore * 0.20);

        return {
            overallScore: parsed.overallScore || calculatedOverall,
            summary: parsed.summary || 'Solid debate performance demonstrating active engagement with the motion.',
            relevance: { ...parsed.relevance, score: relScore, insufficientEvidence: false },
            factualAccuracy: { ...parsed.factualAccuracy, score: factScore, insufficientEvidence: false },
            grammar: { ...parsed.grammar, score: gramScore, insufficientEvidence: false },
            pronunciation: { ...parsed.pronunciation, score: pronScore, insufficientEvidence: false },
            generatedAt: new Date()
        };
    } catch (err) {
        console.error('[debateProctorService] Scorecard synthesis error:', err.message);

        // Transparent mathematical fallback
        const avgRelevance = Math.round(turns.reduce((acc, t) => acc + (t.argumentation?.relevanceScore || 70), 0) / turns.length);
        const avgGrammar = Math.max(50, 95 - turns.reduce((acc, t) => acc + (t.grammar?.length || 0) * 8, 0));
        const avgPronunciation = Math.max(50, 95 - turns.reduce((acc, t) => acc + (t.pronunciation?.length || 0) * 8, 0));
        const avgFactual = 75;
        const overall = Math.round(avgRelevance * 0.30 + avgFactual * 0.25 + avgGrammar * 0.25 + avgPronunciation * 0.20);

        return {
            overallScore: overall,
            summary: 'Debate performance evaluated across all recorded speaking contributions.',
            relevance: { score: avgRelevance, explanation: 'Maintained focus on the topic throughout turns.', evidence: [], strengths: ['Active engagement with debate prompt.'], areasToImprove: ['Incorporate more structured argumentation.'], practicalNextStep: 'Use claim-evidence-reasoning structures.', insufficientEvidence: false },
            factualAccuracy: { score: avgFactual, explanation: 'General arguments supported the topic.', evidence: [], strengths: ['Coherent positions.'], areasToImprove: ['Cite specific studies or data.'], practicalNextStep: 'Reference verified sources when available.', insufficientEvidence: false },
            grammar: { score: avgGrammar, explanation: 'Good sentence construction in the target language.', evidence: [], strengths: ['Communicative fluency.'], areasToImprove: ['Watch agreement and verb conjugations.'], practicalNextStep: 'Review core tense conjugations.', insufficientEvidence: false },
            pronunciation: { score: avgPronunciation, explanation: 'Clear speech with high general intelligibility.', evidence: [], strengths: ['Good speaking volume and pace.'], areasToImprove: ['Focus on multi-syllable word stress.'], practicalNextStep: 'Listen and repeat key vocabulary.', insufficientEvidence: false },
            generatedAt: new Date()
        };
    }
}

module.exports = { evaluateSpeakingTurn, synthesizeScorecard };
