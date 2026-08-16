const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function summarizeArticle(title, content) {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const text = content || title;
    const prompt = `Summarize the following news article in exactly 60-80 words. Be concise and factual. Do not add opinions or extra information beyond what the article states.\n\nTitle: ${title}\nContent: ${text}\n\nSummary:`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text();
}

module.exports = { summarizeArticle };
