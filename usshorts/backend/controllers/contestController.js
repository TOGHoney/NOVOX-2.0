const Contest = require('../models/Contest');



// Admin: Get all contests (for admin panel)

exports.getAllContests = async (req, res) => {

try {

const contests = await Contest.find()

.select('-questions.correctOptionIndex')

.sort({ createdAt: -1 })

.lean();

res.json(contests);

} catch (error) {

console.error('Get All Contests Error:', error);

res.status(500).json({ message: 'Error fetching contests', error: error.message });

}

};



// Admin: Create a new contest (Public or Private)

exports.createContest = async (req, res) => {

try {

const { title, description, isPublic, passcode, startTime, endTime, questions } = req.body;



if (!isPublic && !passcode) {

return res.status(400).json({ message: 'Passcode is required for private contests.' });

}



// Retrieve user ID from auth middleware safely

const userId = req.user?._id || req.user?.id;

if (!userId) {

return res.status(401).json({ message: 'Not authorized. Missing user credentials.' });

}



// Format questions to match schema keys (correctOptionIndex)

const formattedQuestions = Array.isArray(questions)

? questions.map((q) => ({

questionText: q.questionText || q.question || '',

options: q.options || [],

correctOptionIndex: q.correctOptionIndex !== undefined ? q.correctOptionIndex : (q.correctAnswer || 0),

points: q.points || 1

}))

: [];



const contest = new Contest({

title,

description: description || '',

isPublic: isPublic !== undefined ? isPublic : true,

passcode: isPublic ? null : passcode,

startTime: startTime || new Date(),

endTime: endTime || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),

questions: formattedQuestions,

createdBy: userId

});



await contest.save();

res.status(201).json({ message: 'Contest created successfully', contest });

} catch (error) {

console.error('Create Contest Error:', error);

res.status(500).json({ message: 'Error creating contest', error: error.message });

}

};



// Home Screen: Get all public team-hosted contests

exports.getPublicContests = async (req, res) => {

try {

const userId = req.user?._id || req.user?.id;

const contests = await Contest.find({ isPublic: true })

.select('-questions.correctOptionIndex -passcode')

.sort({ startTime: -1 })

.lean();



// Map through contests and append the hasAttempted flag for the logged-in user

const formattedContests = contests.map((contest) => {

const hasAttempted = userId && Array.isArray(contest.submissions)

? contest.submissions.some((sub) => sub.user && sub.user.toString() === userId.toString())

: false;



return {

...contest,

hasAttempted

};

});



res.json(formattedContests);

} catch (error) {

res.status(500).json({ message: 'Error fetching contests', error: error.message });

}

};



// Search Box: Join private contest via passcode

exports.getContestByPasscode = async (req, res) => {

try {

const { passcode } = req.body;

const userId = req.user?._id || req.user?.id;



const contest = await Contest.findOne({ passcode, isPublic: false })

.select('-questions.correctOptionIndex')

.lean();



if (!contest) {

return res.status(404).json({ message: 'Invalid passcode or contest not found.' });

}



const hasAttempted = userId && Array.isArray(contest.submissions)

? contest.submissions.some((sub) => sub.user && sub.user.toString() === userId.toString())

: false;



res.json({

...contest,

hasAttempted

});

} catch (error) {

res.status(500).json({ message: 'Error searching contest', error: error.message });

}

};



// Users: Submit contest answers & calculate score

exports.submitContest = async (req, res) => {

try {

const { contestId, answers, timeTakenSeconds } = req.body;

const contest = await Contest.findById(contestId);

if (!contest) return res.status(404).json({ message: 'Contest not found' });



const userId = req.user?._id || req.user?.id;



// Check if user has already submitted this contest

const alreadySubmitted = contest.submissions.some(

(sub) => sub.user && sub.user.toString() === userId.toString()

);



if (alreadySubmitted) {

return res.status(400).json({ message: 'You have already submitted this contest.' });

}



let score = 0;

contest.questions.forEach((q, idx) => {

if (answers[idx] !== undefined && answers[idx] === q.correctOptionIndex) {

score += q.points;

}

});



contest.submissions.push({

user: userId,

score,

timeTakenSeconds

});



await contest.save();

res.json({ message: 'Submission successful', score });

} catch (error) {

res.status(500).json({ message: 'Error submitting test', error: error.message });

}

};



// Leaderboard: Ranked by score first, then time speed

exports.getLeaderboard = async (req, res) => {

try {

const { id } = req.params; // Matches router parameter :id

const contest = await Contest.findById(id).populate('submissions.user', 'username email');



if (!contest) {

return res.status(404).json({ message: 'Contest not found' });

}



// Sort submissions: Highest score first, then lowest time taken

const sortedSubmissions = [...contest.submissions].sort((a, b) => {

if (b.score !== a.score) {

return b.score - a.score;

}

return a.timeTakenSeconds - b.timeTakenSeconds;

});



res.json(sortedSubmissions);

} catch (error) {

res.status(500).json({ message: 'Error fetching leaderboard', error: error.message });

}

};
// Admin / Host: Delete a contest by ID (with ownership check)
exports.deleteContest = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?._id || req.user?.id;

    const contest = await Contest.findById(id);
    if (!contest) {
      return res.status(404).json({ message: 'Contest not found' });
    }

    // Verify if logged-in user is creator of this contest
    if (contest.createdBy.toString() !== userId.toString()) {
      return res.status(403).json({ message: 'Not authorized to delete this contest.' });
    }

    await Contest.findByIdAndDelete(id);
    res.json({ message: 'Contest deleted successfully', id });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting contest', error: error.message });
  }
};