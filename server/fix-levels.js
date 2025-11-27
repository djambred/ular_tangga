const mongoose = require('mongoose');
const User = require('./models/User');

// Connect to MongoDB
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ular_tangga';

mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB'))
.catch(err => console.error('❌ MongoDB connection error:', err));

async function fixHighestLevel() {
  try {
    console.log('🔧 Fixing users with highestLevel = 0...');
    
    // Update all users with highestLevel 0 to 1
    const result = await User.updateMany(
      { 'statistics.highestLevel': 0 },
      { $set: { 'statistics.highestLevel': 1 } }
    );
    
    console.log(`✅ Fixed ${result.modifiedCount} users`);
    
    // Show current user stats
    const users = await User.find({ role: 'player' })
      .select('username statistics.highestLevel')
      .sort({ 'statistics.highestLevel': 1 });
    
    console.log('\n📊 Current User Levels:');
    users.forEach(user => {
      console.log(`  - ${user.username}: Level ${user.statistics.highestLevel}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

// Run fix
fixHighestLevel();
