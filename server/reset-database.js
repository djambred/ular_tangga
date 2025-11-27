const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./models/User');
const Quiz = require('./models/Quiz');
const BoardConfig = require('./models/BoardConfig');
const GameHistory = require('./models/GameHistory');
const Content = require('./models/Content');
const AppConfig = require('./models/AppConfig');

async function resetDatabase() {
  try {
    console.log('🗑️  Resetting database...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/ulartangga', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ Connected to MongoDB');

    // Drop all collections
    console.log('\n📦 Dropping collections...');
    
    const collections = [
      { name: 'Users', model: User },
      { name: 'Quizzes', model: Quiz },
      { name: 'BoardConfigs', model: BoardConfig },
      { name: 'GameHistories', model: GameHistory },
      { name: 'Contents', model: Content },
      { name: 'AppConfigs', model: AppConfig }
    ];

    for (const collection of collections) {
      try {
        await collection.model.collection.drop();
        console.log(`  ✅ Dropped ${collection.name}`);
      } catch (error) {
        if (error.code === 26) {
          console.log(`  ⚠️  ${collection.name} collection doesn't exist (skipping)`);
        } else {
          console.log(`  ❌ Error dropping ${collection.name}:`, error.message);
        }
      }
    }

    console.log('\n✅ Database reset complete!');
    console.log('\n💡 Next steps:');
    console.log('   1. Run: node seed.js');
    console.log('   2. Run: node seed-content.js');
    console.log('   3. Run: node seed-environment.js');
    console.log('   Or use: ./setup.sh to reset and seed everything');

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error resetting database:', error);
    process.exit(1);
  }
}

resetDatabase();
