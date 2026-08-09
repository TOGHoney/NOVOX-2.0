import client from './client';

export const fetchComments = async (articleUrl) => {
    const response = await client.get('/comments', {
        params: { articleUrl },
    });
    return response.data;
};

export const postComment = async (articleUrl, text, parentId = null) => {
    const response = await client.post('/comments', { articleUrl, text, parentId });
    return response.data;
};

export const deleteComment = async (id) => {
    const response = await client.delete(`/comments/${id}`);
    return response.data;
};
