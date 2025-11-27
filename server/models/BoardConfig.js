const mongoose = require('mongoose');

const boardConfigSchema = new mongoose.Schema({
  level: {
    type: Number,
    required: true,
    min: 1,
    max: 10,
    unique: true
  },
  snakes: [{
    start: { type: Number, required: true },
    end: { type: Number, required: true }
  }],
  ladders: [{
    start: { type: Number, required: true },
    end: { type: Number, required: true }
  }],
  quizPositions: [{
    position: { type: Number, required: true },
    quizId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Quiz'
    }
  }],
  requiredQuizzes: {
    type: Number,
    required: true,
    min: 1,
    max: 10
  },
  boardSize: {
    type: Number,
    default: 100
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update timestamp on save
boardConfigSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('BoardConfig', boardConfigSchema);
