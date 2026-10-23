const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const MODEL_NAME = 'gemini-3.5-flash-lite';

async function summarizeArticle(title, content) {
    const model = genAI.getGenerativeModel({ model: MODEL_NAME });

    const text = content || title;
    const prompt = `Summarize the following news article in exactly 60-80 words. Be concise and factual. Do not add opinions or extra information beyond what the article states.\n\nTitle: ${title}\nContent: ${text}\n\nSummary:`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text();
}

/**
 * Explains a word, phrase, or sentence in context according to user's learning mode:
 * - A1, A2, B1 (Mode A): User reads in base language, learning target language.
 *   Original expression is in base language.
 *   Translation is in target language.
 *   Target expression is the translation.
 * - B2, C1, C2 (Mode B): User reads in target language, base language is native.
 *   Original expression is in target language.
 *   Translation is in base language.
 *   Target expression is the original expression.
 *
 * CRITICAL RULE: Contextual meaning MUST ALWAYS be written in the user's base language for both modes.
 */
async function explainWordIntelligence({ expression, sentence, baseLanguage = 'en', targetLanguage = 'es', cefrLevel = 'B1' }) {
    const model = genAI.getGenerativeModel({
        model: MODEL_NAME,
        generationConfig: {
            temperature: 0.2,
            responseMimeType: 'application/json'
        }
    });

    const isBeginnerOrIntermediate = ['A1', 'A2', 'B1'].includes(cefrLevel.toUpperCase());

    const prompt = `You are an expert language pedagogy AI for the language learning app Linguabrief.
Analyze the selected expression in its sentence context and return a structured JSON response.

Learner Profile:
- Base / Native Language: "${baseLanguage}" (the language the learner comfortably understands).
- Target / Learning Language: "${targetLanguage}" (the language the learner is actively studying).
- CEFR Level: "${cefrLevel}".
- Learning Mode: ${isBeginnerOrIntermediate ? 'Mode A (Beginner/Intermediate: A1-B1). The user reads in their base language and learns target language equivalents.' : 'Mode B (Upper-Intermediate/Advanced: B2-C2). The user reads authentic target language news and needs base language translations.'}

Input:
- Selected Expression: "${expression}"
- Surrounding Sentence / Context: "${sentence || expression}"

Rules:
1. "originalExpression": Keep the EXACT selected expression without altering spelling or script ("${expression}").
2. "translation":
   - If Mode A: Translate the base-language expression into "${targetLanguage}". Context-aware translation appropriate for the sentence.
   - If Mode B: Translate the target-language expression into "${baseLanguage}". Context-aware translation appropriate for the sentence.
3. "targetExpression": The expression in the target language ("${targetLanguage}").
   - If Mode A, this is the "${targetLanguage}" translation.
   - If Mode B, this is the original "${targetLanguage}" expression.
4. "pronunciationGuide": Provide clear pronunciation guidance for "targetExpression":
   - For Japanese ("ja"): Provide standard Hepburn romanization (e.g., "keizai seichō").
   - For Spanish ("es"), French ("fr"), German ("de"): Provide learner-friendly phonetic breakdown (e.g., "meh-DEE-dahs" or syllables with primary stress capitalized).
   - For Thai ("th"): Provide established romanized transliteration with tone marks or clear syllables.
   - For English ("en"): Provide readable phonetic respelling.
   - Do NOT confuse pronunciation with translation.
5. "contextualMeaning":
   - MUST ALWAYS BE WRITTEN IN THE LEARNER'S BASE LANGUAGE ("${baseLanguage}").
   - NEVER output the contextual explanation in the target language if base language is different.
   - Explain what the expression specifically means in the original sentence context.
   - Explain any idioms, phrasal verbs, figurative expressions, or nuance.
   - Calibrate explanation difficulty for CEFR "${cefrLevel}" (simple clarity for A1-B1, deeper nuance/register for B2-C2).
6. "dictionaryDefinition":
   - Provide a formal definition in "${baseLanguage}".
7. "partOfSpeech": The grammatical part of speech (noun, verb, adjective, adverb, idiom, phrase, etc.).
8. "isSentence": Boolean indicating if the selection is a full sentence or multi-word phrase (true if 4+ words or complete sentence).

Output strictly valid JSON matching this schema:
{
  "originalExpression": "${expression}",
  "translation": "...",
  "targetExpression": "...",
  "pronunciationGuide": "...",
  "contextualMeaning": "...",
  "dictionaryDefinition": "...",
  "partOfSpeech": "...",
  "detectedCefr": "${cefrLevel}",
  "isSentence": boolean
}`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    return JSON.parse(text);
}

module.exports = { summarizeArticle, explainWordIntelligence };

