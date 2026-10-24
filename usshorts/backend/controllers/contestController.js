const Contest = require('../models/Contest');
const ContestParticipation = require('../models/ContestParticipation');
const DebateRoom = require('../models/DebateRoom');

// Helper to format contest response with dynamic status and user participation
const formatContestWithStatus = (contest, userId, userParticipationsMap = null) => {
  const plain = contest.toObject ? contest.toObject() : contest;
  const now = new Date();
  
  let computedStatus = plain.status;
  if (plain.status !== 'cancelled') {
    const start = plain.startTime ? new Date(plain.startTime) : null;
    const end = plain.endTime ? new Date(plain.endTime) : null;
    if (end && now > end) {
      computedStatus = 'completed';
    } else if (start && now >= start && (!end || now <= end)) {
      computedStatus = 'live';
    } else {
      computedStatus = 'upcoming';
    }
  }

  // Registration closed status
  const regDeadline = plain.registrationDeadline ? new Date(plain.registrationDeadline) : (plain.startTime ? new Date(plain.startTime) : null);
  const isRegistrationClosed = computedStatus === 'cancelled' || computedStatus === 'completed' || (regDeadline && now > regDeadline);
  const isFull = plain.maxParticipants && plain.maxParticipants > 0 ? (plain.participantCount >= plain.maxParticipants) : false;

  let isRegistered = false;
  let participationStatus = null;
  if (userId) {
    if (userParticipationsMap) {
      const part = userParticipationsMap[plain._id.toString()];
      if (part && part.status !== 'withdrawn') {
        isRegistered = true;
        participationStatus = part.status;
      }
    } else if (Array.isArray(plain.submissions)) {
      isRegistered = plain.submissions.some((sub) => sub.user && sub.user.toString() === userId.toString());
    }
  }

  return {
    ...plain,
    computedStatus,
    isRegistrationClosed,
    isFull,
    isRegistered,
    participationStatus
  };
};

// ==========================================
// 1. ADMIN: Create a new contest
// ==========================================
exports.createContest = async (req, res) => {
  try {
    const {
      title,
      description,
      rules,
      type,
      language,
      difficulty,
      startTime,
      registrationDeadline,
      endTime,
      durationMinutes,
      maxParticipants,
      isPublic,
      visibility,
      passcode,
      scoringCriteria,
      prizes,
      questions
    } = req.body;

    if (!title || typeof title !== 'string' || title.trim().length === 0) {
      return res.status(400).json({ message: 'Contest title is required.' });
    }

    if (!startTime || !endTime) {
      return res.status(400).json({ message: 'Start time and end time are required.' });
    }

    const startDate = new Date(startTime);
    const endDate = new Date(endTime);
    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      return res.status(400).json({ message: 'Invalid start or end date format.' });
    }

    if (endDate <= startDate) {
      return res.status(400).json({ message: 'End time must be after start time.' });
    }

    let regDate = registrationDeadline ? new Date(registrationDeadline) : startDate;
    if (isNaN(regDate.getTime())) {
      regDate = startDate;
    }
    if (regDate > startDate) {
      return res.status(400).json({ message: 'Registration deadline cannot be after start time.' });
    }

    const determinedVisibility = visibility === 'invite-only' || isPublic === false ? 'invite-only' : 'public';
    const isPublicBool = determinedVisibility === 'public';

    if (determinedVisibility === 'invite-only' && (!passcode || passcode.trim().length === 0)) {
      return res.status(400).json({ message: 'Passcode is required for invite-only contests.' });
    }

    const userId = req.user._id || req.user.id;
    const contestType = ['Debate', 'Language Challenge', 'Vocabulary Quiz'].includes(type) ? type : 'Vocabulary Quiz';
    const contestLang = language && language.trim().length > 0 ? language.trim() : 'Spanish';
    const contestDiff = difficulty && difficulty.trim().length > 0 ? difficulty.trim() : 'All Levels';

    // Format optional questions
    const formattedQuestions = Array.isArray(questions)
      ? questions.map((q) => ({
          questionText: q.questionText || q.question || '',
          options: q.options || [],
          correctOptionIndex: q.correctOptionIndex !== undefined ? q.correctOptionIndex : (q.correctAnswer || 0),
          points: q.points || 1
        }))
      : [];

    let linkedDebateRoomId = null;

    // Connect to actual debate room for Debate contests
    if (contestType === 'Debate') {
      try {
        const debateRoom = new DebateRoom({
          host: userId,
          topic: title.trim(),
          prompt: description || rules || 'Contest debate round',
          language: contestLang,
          level: contestDiff === 'All Levels' ? 'B1' : contestDiff,
          maxParticipants: maxParticipants && Number(maxParticipants) > 0 ? Math.min(Number(maxParticipants), 20) : 6,
          status: 'open'
        });
        const savedRoom = await debateRoom.save();
        linkedDebateRoomId = savedRoom._id;
      } catch (err) {
        console.error('Error creating linked debate room:', err);
      }
    }

    const contest = new Contest({
      title: title.trim(),
      description: description ? description.trim() : '',
      rules: rules ? rules.trim() : '',
      type: contestType,
      language: contestLang,
      difficulty: contestDiff,
      startTime: startDate,
      endTime: endDate,
      registrationDeadline: regDate,
      durationMinutes: durationMinutes ? Number(durationMinutes) : null,
      maxParticipants: maxParticipants && Number(maxParticipants) > 0 ? Number(maxParticipants) : null,
      participantCount: 0,
      isPublic: isPublicBool,
      visibility: determinedVisibility,
      passcode: determinedVisibility === 'invite-only' ? passcode.trim() : null,
      scoringCriteria: scoringCriteria ? scoringCriteria.trim() : 'Accuracy & Speed',
      prizes: prizes ? prizes.trim() : 'Leaderboard Recognition & Learning XP',
      status: 'upcoming',
      questions: formattedQuestions,
      createdBy: userId,
      linkedDebateRoom: linkedDebateRoomId
    });

    await contest.save();
    return res.status(201).json({ 
      message: 'Contest created successfully', 
      contest: formatContestWithStatus(contest, userId) 
    });
  } catch (error) {
    console.error('Create Contest Error:', error);
    return res.status(500).json({ message: 'Error creating contest', error: error.message });
  }
};

// ==========================================
// 2. GET CONTESTS (List & Filter)
// ==========================================
exports.getContests = async (req, res) => {
  try {
    const userId = req.user?._id || req.user?.id;
    const { status, type, language, difficulty, visibility, filter } = req.query;

    const query = {};

    if (type && type !== 'all') {
      query.type = type;
    }
    if (language && language !== 'all') {
      query.language = new RegExp(`^${language}$`, 'i');
    }
    if (difficulty && difficulty !== 'all') {
      query.difficulty = difficulty;
    }
    if (visibility === 'public') {
      query.isPublic = true;
    } else if (visibility === 'invite-only') {
      query.visibility = 'invite-only';
    }

    // Preload user's participations
    let userParticipationsMap = {};
    if (userId) {
      const participations = await ContestParticipation.find({ 
        user: userId, 
        status: { $ne: 'withdrawn' } 
      }).select('contest status');
      participations.forEach((p) => {
        userParticipationsMap[p.contest.toString()] = p;
      });
    }

    if (filter === 'my' && userId) {
      const contestIds = Object.keys(userParticipationsMap);
      query._id = { $in: contestIds };
    }

    const contests = await Contest.find(query)
      .select('-questions.correctOptionIndex')
      .populate('createdBy', 'username email')
      .populate('linkedDebateRoom', '_id status participants')
      .sort({ startTime: 1, createdAt: -1 });

    let formatted = contests.map((c) => formatContestWithStatus(c, userId, userParticipationsMap));

    // Dynamic status filter if requested
    if (status && status !== 'all') {
      formatted = formatted.filter((c) => c.computedStatus === status.toLowerCase());
    }

    return res.json(formatted);
  } catch (error) {
    console.error('Get Contests Error:', error);
    return res.status(500).json({ message: 'Error fetching contests', error: error.message });
  }
};

// ==========================================
// 3. GET SINGLE CONTEST DETAILS
// ==========================================
exports.getContestById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?._id || req.user?.id;

    const contest = await Contest.findById(id)
      .select('-questions.correctOptionIndex')
      .populate('createdBy', 'username email role')
      .populate('linkedDebateRoom', '_id status participants');

    if (!contest) {
      return res.status(404).json({ message: 'Contest not found' });
    }

    let userParticipation = null;
    if (userId) {
      userParticipation = await ContestParticipation.findOne({ contest: id, user: userId });
    }

    const userParticipationsMap = userParticipation ? { [id]: userParticipation } : {};
    const formatted = formatContestWithStatus(contest, userId, userParticipationsMap);

    return res.json({
      ...formatted,
      myParticipation: userParticipation || null
    });
  } catch (error) {
    console.error('Get Contest By ID Error:', error);
    return res.status(500).json({ message: 'Error retrieving contest details', error: error.message });
  }
};

// ==========================================
// 4. ADMIN: Update/Edit an existing contest
// ==========================================
exports.updateContest = async (req, res) => {
  try {
    const { id } = req.params;
    const contest = await Contest.findById(id);

    if (!contest) {
      return res.status(404).json({ message: 'Contest not found.' });
    }

    if (contest.status === 'cancelled') {
      return res.status(400).json({ message: 'Cannot edit a cancelled contest.' });
    }

    const now = new Date();
    if (contest.endTime && now > contest.endTime) {
      return res.status(400).json({ message: 'Cannot edit a completed contest.' });
    }

    const {
      title,
      description,
      rules,
      language,
      difficulty,
      startTime,
      endTime,
      registrationDeadline,
      maxParticipants,
      scoringCriteria,
      prizes
    } = req.body;

    if (title && title.trim().length > 0) contest.title = title.trim();
    if (description !== undefined) contest.description = description.trim();
    if (rules !== undefined) contest.rules = rules.trim();
    if (language !== undefined) contest.language = language.trim();
    if (difficulty !== undefined) contest.difficulty = difficulty.trim();
    if (scoringCriteria !== undefined) contest.scoringCriteria = scoringCriteria.trim();
    if (prizes !== undefined) contest.prizes = prizes.trim();

    if (startTime) {
      const sDate = new Date(startTime);
      if (!isNaN(sDate.getTime())) contest.startTime = sDate;
    }
    if (endTime) {
      const eDate = new Date(endTime);
      if (!isNaN(eDate.getTime()) && eDate > contest.startTime) {
        contest.endTime = eDate;
      }
    }
    if (registrationDeadline) {
      const rDate = new Date(registrationDeadline);
      if (!isNaN(rDate.getTime()) && rDate <= contest.startTime) {
        contest.registrationDeadline = rDate;
      }
    }

    if (maxParticipants !== undefined) {
      const num = Number(maxParticipants);
      if (num >= contest.participantCount) {
        contest.maxParticipants = num > 0 ? num : null;
      } else {
        return res.status(400).json({ 
          message: `Cannot reduce capacity below current participant count (${contest.participantCount}).` 
        });
      }
    }

    await contest.save();
    return res.json({ 
      message: 'Contest updated successfully', 
      contest: formatContestWithStatus(contest, req.user._id) 
    });
  } catch (error) {
    console.error('Update Contest Error:', error);
    return res.status(500).json({ message: 'Error updating contest', error: error.message });
  }
};

// ==========================================
// 5. ADMIN: Cancel a contest
// ==========================================
exports.cancelContest = async (req, res) => {
  try {
    const { id } = req.params;
    const contest = await Contest.findById(id);

    if (!contest) {
      return res.status(404).json({ message: 'Contest not found.' });
    }

    if (contest.status === 'cancelled') {
      return res.status(400).json({ message: 'Contest is already cancelled.' });
    }

    contest.status = 'cancelled';
    await contest.save();

    // Mark all participations cancelled
    await ContestParticipation.updateMany(
      { contest: id },
      { status: 'cancelled' }
    );

    // If debate room linked, close it
    if (contest.linkedDebateRoom) {
      await DebateRoom.findByIdAndUpdate(contest.linkedDebateRoom, { status: 'closed' });
    }

    return res.json({ 
      message: 'Contest cancelled successfully', 
      contest: formatContestWithStatus(contest, req.user._id) 
    });
  } catch (error) {
    console.error('Cancel Contest Error:', error);
    return res.status(500).json({ message: 'Error cancelling contest', error: error.message });
  }
};

// ==========================================
// 6. USER: Join a contest (Atomic capacity + DB uniqueness)
// ==========================================
exports.joinContest = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id || req.user.id;

    const contest = await Contest.findById(id);
    if (!contest) {
      return res.status(404).json({ message: 'Contest not found.' });
    }

    if (contest.status === 'cancelled') {
      return res.status(400).json({ message: 'This contest has been cancelled.' });
    }

    const now = new Date();
    if (contest.endTime && now > contest.endTime) {
      return res.status(400).json({ message: 'This contest has already ended.' });
    }

    const regDeadline = contest.registrationDeadline || contest.startTime;
    if (regDeadline && now > regDeadline) {
      return res.status(400).json({ message: 'Registration has closed for this contest.' });
    }

    // Check existing registration
    const existingParticipation = await ContestParticipation.findOne({
      contest: id,
      user: userId
    });

    if (existingParticipation && existingParticipation.status !== 'withdrawn' && existingParticipation.status !== 'cancelled') {
      return res.status(400).json({ message: 'You have already joined this contest.' });
    }

    // Concurrency-safe capacity management using atomic update
    let updatedContest;
    if (contest.maxParticipants && contest.maxParticipants > 0) {
      updatedContest = await Contest.findOneAndUpdate(
        {
          _id: id,
          status: { $ne: 'cancelled' },
          participantCount: { $lt: contest.maxParticipants }
        },
        { $inc: { participantCount: 1 } },
        { returnDocument: 'after' }
      );

      if (!updatedContest) {
        return res.status(400).json({ message: 'Contest is full. Maximum participant capacity reached.' });
      }
    } else {
      updatedContest = await Contest.findByIdAndUpdate(
        id,
        { $inc: { participantCount: 1 } },
        { returnDocument: 'after' }
      );
    }

    // Create or reactivate participation
    let participation;
    if (existingParticipation) {
      existingParticipation.status = 'registered';
      existingParticipation.joinedAt = new Date();
      participation = await existingParticipation.save();
    } else {
      participation = await ContestParticipation.create({
        contest: id,
        user: userId,
        status: 'registered',
        joinedAt: new Date()
      });
    }

    // If Debate contest, add user to linked debate room
    if (contest.type === 'Debate' && contest.linkedDebateRoom) {
      try {
        const debateRoom = await DebateRoom.findById(contest.linkedDebateRoom);
        if (debateRoom && !debateRoom.isParticipant(userId)) {
          debateRoom.participants.push({ user: userId, joinedAt: new Date() });
          await debateRoom.save();
        }
      } catch (err) {
        console.error('Error adding user to debate room:', err);
      }
    }

    // Include user participation in map so formatContestWithStatus correctly sets isRegistered
    const userParticipationsMap = { [id]: participation };
    return res.status(200).json({
      message: 'Successfully joined contest!',
      contest: formatContestWithStatus(updatedContest, userId, userParticipationsMap),
      participation
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'You have already registered for this contest.' });
    }
    console.error('Join Contest Error:', error);
    return res.status(500).json({ message: 'Error joining contest', error: error.message });
  }
};

// ==========================================
// 7. USER: Leave a contest (Before cutoff)
// ==========================================
exports.leaveContest = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id || req.user.id;

    const contest = await Contest.findById(id);
    if (!contest) {
      return res.status(404).json({ message: 'Contest not found.' });
    }

    const now = new Date();
    if (contest.startTime && now >= contest.startTime) {
      return res.status(400).json({ message: 'Cannot leave a contest that is already live or completed.' });
    }

    const participation = await ContestParticipation.findOne({
      contest: id,
      user: userId,
      status: 'registered'
    });

    if (!participation) {
      return res.status(400).json({ message: 'You are not currently registered for this contest.' });
    }

    participation.status = 'withdrawn';
    await participation.save();

    // Safely decrement participant count
    const updatedContest = await Contest.findByIdAndUpdate(
      id,
      { $inc: { participantCount: -1 } },
      { returnDocument: 'after' }
    );

    // If Debate contest, remove from linked debate room
    if (contest.linkedDebateRoom) {
      try {
        await DebateRoom.findByIdAndUpdate(contest.linkedDebateRoom, {
          $pull: { participants: { user: userId } }
        });
      } catch (err) {
        console.error('Error removing from debate room:', err);
      }
    }

    // Include user participation in map so formatContestWithStatus correctly sets isRegistered
    const userParticipationsMap = { [id]: { ...participation.toObject(), status: 'withdrawn' } };
    return res.json({
      message: 'Successfully left the contest.',
      contest: formatContestWithStatus(updatedContest, userId, userParticipationsMap)
    });
  } catch (error) {
    console.error('Leave Contest Error:', error);
    return res.status(500).json({ message: 'Error leaving contest', error: error.message });
  }
};

// ==========================================
// 8. USER: Get my joined contests
// ==========================================
exports.getMyContests = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;

    const participations = await ContestParticipation.find({
      user: userId,
      status: { $in: ['registered', 'participated'] }
    })
      .populate({
        path: 'contest',
        populate: [
          { path: 'createdBy', select: 'username email' },
          { path: 'linkedDebateRoom', select: '_id status participants' }
        ]
      })
      .sort({ joinedAt: -1 });

    const userParticipationsMap = {};
    participations.forEach((p) => {
      if (p.contest) {
        userParticipationsMap[p.contest._id.toString()] = p;
      }
    });

    const result = participations
      .filter((p) => p.contest != null)
      .map((p) => ({
        ...formatContestWithStatus(p.contest, userId, userParticipationsMap),
        participationStatus: p.status,
        joinedAt: p.joinedAt,
        score: p.score,
        timeTakenSeconds: p.timeTakenSeconds
      }));

    return res.json(result);
  } catch (error) {
    console.error('Get My Contests Error:', error);
    return res.status(500).json({ message: 'Error fetching your contests', error: error.message });
  }
};

// ==========================================
// 9. ADMIN: View registered participants
// ==========================================
exports.getContestParticipants = async (req, res) => {
  try {
    const { id } = req.params;

    const contest = await Contest.findById(id).select('title participantCount maxParticipants');
    if (!contest) {
      return res.status(404).json({ message: 'Contest not found.' });
    }

    const participants = await ContestParticipation.find({ contest: id })
      .populate('user', 'username email role targetLanguage cefrLevel streak')
      .sort({ joinedAt: 1 });

    return res.json({
      contestId: contest._id,
      contestTitle: contest.title,
      totalCount: participants.length,
      participants: participants.map((p) => ({
        id: p._id,
        user: p.user ? {
          id: p.user._id,
          username: p.user.username,
          email: p.user.email,
          targetLanguage: p.user.targetLanguage,
          cefrLevel: p.user.cefrLevel,
          streak: p.user.streak
        } : null,
        status: p.status,
        joinedAt: p.joinedAt,
        score: p.score,
        timeTakenSeconds: p.timeTakenSeconds
      }))
    });
  } catch (error) {
    console.error('Get Participants Error:', error);
    return res.status(500).json({ message: 'Error fetching contest participants', error: error.message });
  }
};

// ==========================================
// 10. PRESERVED LEGACY/COMPATIBILITY ENDPOINTS
// ==========================================

// Legacy Home screen public contests
exports.getPublicContests = async (req, res) => {
  try {
    const userId = req.user?._id || req.user?.id;
    const contests = await Contest.find({ isPublic: true })
      .select('-questions.correctOptionIndex -passcode')
      .sort({ startTime: -1 })
      .lean();

    const formattedContests = contests.map((contest) => {
      const hasAttempted = userId && Array.isArray(contest.submissions)
        ? contest.submissions.some((sub) => sub.user && sub.user.toString() === userId.toString())
        : false;
      return {
        ...contest,
        hasAttempted
      };
    });

    return res.json(formattedContests);
  } catch (error) {
    return res.status(500).json({ message: 'Error fetching contests', error: error.message });
  }
};

// Legacy all contests for old admin panel
exports.getAllContests = async (req, res) => {
  try {
    const contests = await Contest.find()
      .select('-questions.correctOptionIndex')
      .sort({ createdAt: -1 })
      .lean();
    return res.json(contests);
  } catch (error) {
    return res.status(500).json({ message: 'Error fetching contests', error: error.message });
  }
};

// Search private contest via passcode
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

    return res.json({
      ...contest,
      hasAttempted
    });
  } catch (error) {
    return res.status(500).json({ message: 'Error searching contest', error: error.message });
  }
};

// Submit contest answers
exports.submitContest = async (req, res) => {
  try {
    const { contestId, answers, timeTakenSeconds } = req.body;
    const contest = await Contest.findById(contestId);
    if (!contest) return res.status(404).json({ message: 'Contest not found' });

    const userId = req.user?._id || req.user?.id;

    const alreadySubmitted = contest.submissions.some(
      (sub) => sub.user && sub.user.toString() === userId.toString()
    );

    if (alreadySubmitted) {
      return res.status(400).json({ message: 'You have already submitted this contest.' });
    }

    let score = 0;
    if (Array.isArray(contest.questions)) {
      contest.questions.forEach((q, idx) => {
        const userAns = answers ? answers[idx] ?? answers[String(idx)] : undefined;
        if (userAns !== undefined && Number(userAns) === q.correctOptionIndex) {
          score += (q.points || 1);
        }
      });
    }

    contest.submissions.push({
      user: userId,
      score,
      timeTakenSeconds: Number(timeTakenSeconds) || 0
    });

    await contest.save();

    // Also update ContestParticipation if exists
    await ContestParticipation.findOneAndUpdate(
      { contest: contestId, user: userId },
      {
        status: 'participated',
        score,
        timeTakenSeconds: Number(timeTakenSeconds) || 0,
        submittedAt: new Date()
      },
      { upsert: false }
    );

    return res.json({ message: 'Submission successful', score });
  } catch (error) {
    return res.status(500).json({ message: 'Error submitting test', error: error.message });
  }
};

// Leaderboard: Ranked by score first, then lowest time
exports.getLeaderboard = async (req, res) => {
  try {
    const { id } = req.params;
    const contest = await Contest.findById(id).populate('submissions.user', 'username email');

    if (!contest) {
      return res.status(404).json({ message: 'Contest not found' });
    }

    const sortedSubmissions = [...contest.submissions].sort((a, b) => {
      if (b.score !== a.score) {
        return b.score - a.score;
      }
      return (a.timeTakenSeconds || 0) - (b.timeTakenSeconds || 0);
    });

    return res.json(sortedSubmissions);
  } catch (error) {
    return res.status(500).json({ message: 'Error fetching leaderboard', error: error.message });
  }
};

// Delete a contest
exports.deleteContest = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?._id || req.user?.id;

    const contest = await Contest.findById(id);
    if (!contest) {
      return res.status(404).json({ message: 'Contest not found' });
    }

    // Admins can delete any contest; hosts can delete their own
    if (req.user.role !== 'admin' && contest.createdBy.toString() !== userId.toString()) {
      return res.status(403).json({ message: 'Not authorized to delete this contest.' });
    }

    await Contest.findByIdAndDelete(id);
    await ContestParticipation.deleteMany({ contest: id });

    return res.json({ message: 'Contest deleted successfully', id });
  } catch (error) {
    return res.status(500).json({ message: 'Error deleting contest', error: error.message });
  }
};