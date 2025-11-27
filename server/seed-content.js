const mongoose = require('mongoose');
const Content = require('./models/Content');
const AppConfig = require('./models/AppConfig');
require('dotenv').config();

// Sample snake messages
const snakeMessages = [
  'Lupa minum obat TBC, bisa bikin kuman makin kuat!',
  'Meludah sembarangan, nanti kumannya terbang ke orang lain!',
  'Batuk tanpa menutup mulut, teman bisa ikut sakit.',
  'Berhenti minum obat sebelum waktunya, itu berbahaya!',
  'Percaya mitos aneh kalau TBC tidak bisa sembuh.',
  'Pinjam-pinjam alat makan dengan pasien TBC aktif.',
  'Tidak memakai masker di ruangan ramai.',
  'Membiarkan kamar gelap dan pengap setiap hari.',
  'Mengabaikan batuk lama dan tidak cerita ke orang tua.',
  'Tidak mau ikut periksa padahal tinggal serumah dengan pasien TBC.',
];

// Sample ladder messages
const ladderMessages = [
  'Segera periksa kalau batuknya tidak sembuh-sembuh!',
  'Minum obat TBC tiap hari sampai selesai, biar cepat sembuh!',
  'Buka jendela rumah supaya udara segar masuk.',
  'Menutup mulut saat batuk dengan tisu atau siku.',
  'Ajak keluarga untuk periksa bila ada yang sakit TBC.',
  'Rajin menjemur kasur biar kuman kabur.',
  'Membersihkan rumah dari debu setiap hari.',
  'Pakai masker saat ada yang sedang sakit.',
  'Mendukung teman atau keluarga yang sedang berobat.',
  'Suka belajar hal baru tentang kesehatan!',
];

// Sample facts
const tbFacts = [
  'TBC adalah penyakit yang bisa disembuhkan, asal minum obat teratur.',
  'Kuman TBC menyebar lewat udara saat orang batuk atau bersin.',
  'Kalau batuk lebih dari 2 minggu, segera bilang ke orang tua.',
  'Obat TBC diberikan gratis di Puskesmas.',
  'Kalau obatnya berhenti diminum, kumannya bisa jadi lebih kuat.',
  'Sinar matahari bisa membantu membunuh kuman TBC.',
  'Anak juga bisa kena TBC, apalagi kalau sering dekat pasien TBC.',
  'Masker membantu mencegah penularan TBC.',
  'Rumah yang sering dibuka jendelanya lebih sehat.',
  'TBC bukan penyakit kutukan atau turunan.',
  'TBC tidak menular lewat pelukan atau jabat tangan.',
  'Makan makanan bergizi membantu tubuh melawan penyakit.',
  'Imunisasi BCG melindungi bayi dari TBC berat.',
  'Kalau ada keluarga sakit TBC, sebaiknya ikut periksa juga.',
  'Debu dan rumah pengap bisa membuat kuman lebih betah.',
  'Pasien TBC harus kontrol rutin ke fasilitas kesehatan.',
  'TBC bisa menyerang paru-paru dan bagian tubuh lain.',
  'Jangan malu kalau harus periksa kesehatan, itu tanda peduli diri!',
  'Etika batuk yang benar membantu melindungi orang lain.',
  'Dengan pengobatan yang tepat, TBC pasti bisa sembuh!',
];

// Default app configurations
const defaultConfigs = [
  {
    key: 'api_base_url',
    value: 'https://apiular.ueu-fasilkom.my.id',
    description: 'Base URL for API endpoints',
    category: 'api',
    isPublic: true
  },
  {
    key: 'socket_url',
    value: 'https://apiular.ueu-fasilkom.my.id',
    description: 'Socket.IO server URL',
    category: 'api',
    isPublic: true
  },
  {
    key: 'api_timeout',
    value: 15000,
    description: 'API request timeout in milliseconds',
    category: 'api',
    isPublic: true
  },
  {
    key: 'socket_timeout',
    value: 15000,
    description: 'Socket.IO connection timeout in milliseconds',
    category: 'api',
    isPublic: true
  },
  {
    key: 'game_min_duration',
    value: 300,
    description: 'Minimum game duration in seconds',
    category: 'game',
    isPublic: true
  },
  {
    key: 'game_max_duration',
    value: 420,
    description: 'Maximum game duration in seconds',
    category: 'game',
    isPublic: true
  },
  {
    key: 'enable_multiplayer',
    value: true,
    description: 'Enable multiplayer mode',
    category: 'feature',
    isPublic: true
  },
  {
    key: 'enable_guest_mode',
    value: true,
    description: 'Allow guest users to play',
    category: 'feature',
    isPublic: true
  },
  {
    key: 'min_quiz_required_level1',
    value: 3,
    description: 'Minimum quiz required for level 1',
    category: 'game',
    isPublic: true
  },
  {
    key: 'min_quiz_required_level2',
    value: 5,
    description: 'Minimum quiz required for level 2',
    category: 'game',
    isPublic: true
  },
  {
    key: 'min_quiz_required_level3',
    value: 7,
    description: 'Minimum quiz required for level 3',
    category: 'game',
    isPublic: true
  },
  {
    key: 'app_version',
    value: '1.0.0',
    description: 'Current app version',
    category: 'other',
    isPublic: true
  },
  {
    key: 'maintenance_mode',
    value: false,
    description: 'Enable maintenance mode',
    category: 'feature',
    isPublic: true
  },
  {
    key: 'maintenance_message',
    value: 'Aplikasi sedang dalam maintenance. Silakan coba lagi nanti.',
    description: 'Message to display during maintenance',
    category: 'ui',
    isPublic: true
  }
];

async function seedContentAndConfig() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/ular_tangga', {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('✅ Connected to MongoDB');
    
    // Create a default admin user ID (you should replace this with actual admin ID)
    // For now, we'll just use a dummy ObjectId
    const adminId = new mongoose.Types.ObjectId();
    
    // Clear existing data
    await Content.deleteMany({});
    await AppConfig.deleteMany({});
    console.log('🗑️  Cleared existing content and configs');
    
    // Seed snake messages
    const snakeContents = snakeMessages.map(message => ({
      type: 'snake_message',
      message,
      createdBy: adminId,
      isActive: true
    }));
    
    // Seed ladder messages
    const ladderContents = ladderMessages.map(message => ({
      type: 'ladder_message',
      message,
      createdBy: adminId,
      isActive: true
    }));
    
    // Seed facts
    const factContents = tbFacts.map(message => ({
      type: 'fact',
      message,
      createdBy: adminId,
      isActive: true
    }));
    
    // Insert all contents
    const allContents = [...snakeContents, ...ladderContents, ...factContents];
    await Content.insertMany(allContents);
    console.log(`✅ Seeded ${allContents.length} content items`);
    
    // Seed app configurations
    await AppConfig.insertMany(defaultConfigs);
    console.log(`✅ Seeded ${defaultConfigs.length} configurations`);
    
    console.log('\n🎉 Content and configuration seeding completed successfully!');
    console.log('\n📝 Summary:');
    console.log(`  - Snake messages: ${snakeMessages.length}`);
    console.log(`  - Ladder messages: ${ladderMessages.length}`);
    console.log(`  - Facts: ${tbFacts.length}`);
    console.log(`  - Configurations: ${defaultConfigs.length}`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding data:', error);
    process.exit(1);
  }
}

// Run seeding
seedContentAndConfig();
