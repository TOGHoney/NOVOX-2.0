const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
  questionText: { type: String, required: true },
  options: [{ type: String, required: true }],
  correctOptionIndex: { type: Number, required: true },
  points: { type: Number, default: 1 }
});

const submissionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  score: { type: Number, required: true },
  timeTakenSeconds: { type: Number, required: true },
  submittedAt: { type: Date, default: Date.now }
});

const contestSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true },
  description: { type: String, default: '' },
  rules: { type: String, default: '' },
  type: { 
    type: String, 
    enum: ['Debate', 'Language Challenge', 'Vocabulary Quiz'], 
    default: 'Vocabulary Quiz' 
  },
  language: { type: String, default: 'Spanish' },
  difficulty: { type: String, default: 'All Levels' }, // A1, A2, B1, B2, C1, C2, All Levels
  
  // Scheduling
  startTime: { type: Date, required: true },
  endTime: { type: Date, required: true },
  registrationDeadline: { type: Date },
  durationMinutes: { type: Number, default: null },
  
  // Capacity & Visibility
  maxParticipants: { type: Number, default: null }, // null or 0 = unlimited
  participantCount: { type: Number, default: 0, min: 0 },
  isPublic: { type: Boolean, default: true },
  visibility: { type: String, enum: ['public', 'invite-only'], default: 'public' },
  passcode: { type: String, default: null }, // Required if visibility is invite-only
  
  // Scoring & Awards
  scoringCriteria: { type: String, default: 'Accuracy & Speed' },
  prizes: { type: String, default: 'Leaderboard Recognition & Learning XP' },
  
  // Lifecycle
  status: { 
    type: String, 
    enum: ['upcoming', 'live', 'completed', 'cancelled'], 
    default: 'upcoming' 
  },
  
  // Associations
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  linkedDebateRoom: { type: mongoose.Schema.Types.ObjectId, ref: 'DebateRoom', default: null },
  
  // Activities
  questions: [questionSchema],
  submissions: [submissionSchema]
}, { timestamps: true });

// Dynamic status resolution
contestSchema.methods.getComputedStatus = function() {
  if (this.status === 'cancelled') return 'cancelled';
  const now = new Date();
  if (this.endTime && now > this.endTime) return 'completed';
  if (this.startTime && now >= this.startTime && (!this.endTime || now <= this.endTime)) return 'live';
  return 'upcoming';
};

// Helpful indexes for filtering
contestSchema.index({ status: 1, startTime: -1 });
contestSchema.index({ type: 1, language: 1, difficulty: 1 });
contestSchema.index({ createdBy: 1 });

module.exports = mongoose.model('Contest', contestSchema);