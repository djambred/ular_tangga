const mongoose = require('mongoose');
const AppConfig = require('./models/AppConfig');

// Connect to MongoDB
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ular_tangga';

mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB'))
.catch(err => console.error('❌ MongoDB connection error:', err));

const environmentConfigs = [
  // Development Environment
  {
    key: 'env_dev_api_url',
    value: 'http://localhost:3000',
    description: 'Development API base URL',
    category: 'environment',
    isPublic: true
  },
  {
    key: 'env_dev_socket_url',
    value: 'ws://localhost:3000',
    description: 'Development WebSocket URL',
    category: 'environment',
    isPublic: true
  },
  {
    key: 'env_dev_enabled',
    value: false,
    description: 'Enable development mode',
    category: 'environment',
    isPublic: true
  },
  
  // Production Environment
  {
    key: 'env_prod_api_url',
    value: 'https://apiular.ueu-fasilkom.my.id',
    description: 'Production API base URL',
    category: 'environment',
    isPublic: true
  },
  {
    key: 'env_prod_socket_url',
    value: 'wss://apiular.ueu-fasilkom.my.id',
    description: 'Production WebSocket URL',
    category: 'environment',
    isPublic: true
  },
  {
    key: 'env_prod_enabled',
    value: true,
    description: 'Enable production mode',
    category: 'environment',
    isPublic: true
  },
  
  // Staging Environment (optional)
  {
    key: 'env_staging_api_url',
    value: 'https://staging-apiular.ueu-fasilkom.my.id',
    description: 'Staging API base URL',
    category: 'environment',
    isPublic: true
  },
  {
    key: 'env_staging_socket_url',
    value: 'wss://staging-apiular.ueu-fasilkom.my.id',
    description: 'Staging WebSocket URL',
    category: 'environment',
    isPublic: true
  },
  {
    key: 'env_staging_enabled',
    value: false,
    description: 'Enable staging mode',
    category: 'environment',
    isPublic: true
  },
  
  // Active Environment Selector
  {
    key: 'active_environment',
    value: 'production',
    description: 'Currently active environment (development, staging, or production)',
    category: 'environment',
    isPublic: true
  },
  
  // Debug Settings
  {
    key: 'env_debug_mode',
    value: false,
    description: 'Enable debug logging in app',
    category: 'environment',
    isPublic: true
  },
  {
    key: 'env_force_update',
    value: false,
    description: 'Force app to update configurations on startup',
    category: 'environment',
    isPublic: true
  }
];

async function seedEnvironmentConfigs() {
  try {
    console.log('🌱 Seeding environment configurations...');
    
    for (const configData of environmentConfigs) {
      await AppConfig.findOneAndUpdate(
        { key: configData.key },
        configData,
        { upsert: true, new: true }
      );
      console.log(`✅ ${configData.key}`);
    }
    
    console.log('\n✅ Environment configurations seeded successfully!');
    console.log(`Total configs: ${environmentConfigs.length}`);
    
    // Display current active environment
    const activeEnv = await AppConfig.findOne({ key: 'active_environment' });
    console.log(`\n🔧 Active Environment: ${activeEnv.value}`);
    
    const envPrefix = `env_${activeEnv.value}`;
    const apiUrl = await AppConfig.findOne({ key: `${envPrefix}_api_url` });
    const socketUrl = await AppConfig.findOne({ key: `${envPrefix}_socket_url` });
    
    console.log(`📡 API URL: ${apiUrl ? apiUrl.value : 'Not set'}`);
    console.log(`🔌 Socket URL: ${socketUrl ? socketUrl.value : 'Not set'}`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding environment configs:', error);
    process.exit(1);
  }
}

// Run seeding
seedEnvironmentConfigs();
