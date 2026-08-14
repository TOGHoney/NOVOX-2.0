// geminiService.js
const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function summarizeArticle(title, content) {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const text = content || title;
    const prompt = `You are a concise news editor. Write an accurate, objective summary of the provided news article.
STRICT RULE: The final output MUST be between 60 and 80 words long.

Title: ${title}
Full Article Text: ${text}

Summary (60-80 words):`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text().trim();
}

module.exports = { summarizeArticle };