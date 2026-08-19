import client from './client'; // Uses your pre-configured Axios/Fetch client

export const contestService = {
  // Fetch public contests for Home screen
  getPublicContests: async () => {
    const response = await client.get('/contests/public');
    return response.data;
  },

  // Search private contest via passcode
  joinByPasscode: async (passcode) => {
    const response = await client.post('/contests/join-passcode', { passcode });
    return response.data;
  },

  // Submit test answers
  submitContest: async (contestId, answers, timeTakenSeconds) => {
    const response = await client.post('/contests/submit', {
      contestId,
      answers,
      timeTakenSeconds,
    });
    return response.data;
  },

  // Fetch Leaderboard rankings
  getLeaderboard: async (contestId) => {
    const response = await client.get(`/contests/${contestId}/leaderboard`);
    return response.data;
  },

  // Admin: Create contest
  createContest: async (contestData) => {
    const response = await client.post('/contests/create', contestData);
    return response.data;
  },
  // Admin / Host: Delete a contest
  deleteContest: async (contestId) => {
    const response = await client.delete(`/contests/${contestId}`);
    return response.data;
  },
};