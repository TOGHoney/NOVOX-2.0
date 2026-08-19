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
  title: { type: String, required: true },
  description: { type: String },
  isPublic: { type: Boolean, default: false },
  passcode: { type: String, default: null }, // Required if isPublic is false
  startTime: { type: Date, required: true },
  endTime: { type: Date, required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  questions: [questionSchema],
  submissions: [submissionSchema]
}, { timestamps: true });

module.exports = mongoose.model('Contest', contestSchema);