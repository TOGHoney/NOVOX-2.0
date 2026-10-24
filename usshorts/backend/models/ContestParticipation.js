const mongoose = require('mongoose');

const contestParticipationSchema = new mongoose.Schema({
  contest: { type: mongoose.Schema.Types.ObjectId, ref: 'Contest', required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  joinedAt: { type: Date, default: Date.now },
  status: { 
    type: String, 
    enum: ['registered', 'participated', 'cancelled', 'withdrawn'], 
    default: 'registered' 
  },
  score: { type: Number, default: null },
  timeTakenSeconds: { type: Number, default: null },
  submittedAt: { type: Date, default: null }
}, { timestamps: true });

// Prevent duplicate participation at the database level
contestParticipationSchema.index({ contest: 1, user: 1 }, { unique: true });
contestParticipationSchema.index({ user: 1, status: 1 });
contestParticipationSchema.index({ contest: 1, status: 1 });

module.exports = mongoose.model('ContestParticipation', contestParticipationSchema);
