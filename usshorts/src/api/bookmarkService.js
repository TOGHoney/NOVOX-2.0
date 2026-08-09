import client from './client';

export const getBookmarks = async () => {
    const response = await client.get('/bookmarks');
    return response.data;
};

export const addBookmark = async (article) => {
    const response = await client.post('/bookmarks', {
        articleUrl: article.url,
        article: {
            title: article.title,
            description: article.description,
            content: article.content,
            imageUrl: article.imageUrl,
            url: article.url,
            source: article.source?.name || article.source || '',
            publishedAt: article.publishedAt,
            category: article.category,
            aiSummary: article.aiSummary,
        },
    });
    return response.data;
};

export const removeBookmark = async (articleUrl) => {
    const response = await client.delete('/bookmarks', {
        params: { articleUrl },
    });
    return response.data;
};
