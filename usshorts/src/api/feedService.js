import axios from 'axios';

const API_URL = '/api/feed';

export const fetchFeed = async (offset = 0, limit = 20, topic = 'all') => {
    const response = await axios.get(API_URL, {
        params: { offset, limit, topic },
    });
    return response.data;
};

export const fetchSummaries = async (articleIds) => {
    const response = await axios.post(`${API_URL}/summary`, { articleIds });
    return response.data;
};
