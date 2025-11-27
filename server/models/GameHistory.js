const mongoose = require('mongoose');

const gameHistorySchema = new mongoose.Schema({
  gameId: {
    type: String,
    required: true,
    unique: true
  },
  gameMode: {
    type: String,
    enum: ['single', 'multiplayer'],
    required: true
  },
  level: {
    type: Number,
    required: true,
    min: 1,
    max: 10
  },
  players: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    username: String,
    finalPosition: Number,
    quizzesAnswered: Number,
    quizzesCorrect: Number,
    isWinner: Boolean,
    playTime: Number // in seconds
  }],
  quizzes: [{
    quizId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Quiz'
    },
    position: Number,
    answeredBy: [{
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      isCorrect: Boolean,
      timeSpent: Number // in seconds
    }]
  }],
  startedAt: {
    type: Date,
    required: true
  },
  endedAt: {
    type: Date,
    required: true
  },
  duration: {
    type: Number, // in seconds
    required: true
  },
  roomCode: {
    type: String
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Indexes for faster queries
gameHistorySchema.index({ gameId: 1 });
gameHistorySchema.index({ 'players.userId': 1 });
gameHistorySchema.index({ createdAt: -1 });
gameHistorySchema.index({ gameMode: 1 });

module.exports = mongoose.model('GameHistory', gameHistorySchema);
