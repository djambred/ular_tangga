const mongoose = require('mongoose');

const appConfigSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  value: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  description: {
    type: String,
    trim: true
  },
  category: {
    type: String,
    enum: ['api', 'game', 'feature', 'ui', 'environment', 'other'],
    default: 'other'
  },
  isPublic: {
    type: Boolean,
    default: true // Public configs can be fetched by client app
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
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
appConfigSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Index for faster queries
appConfigSchema.index({ key: 1 });
appConfigSchema.index({ category: 1, isPublic: 1 });

const AppConfig = mongoose.model('AppConfig', appConfigSchema);

module.exports = AppConfig;
