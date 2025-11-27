require('dotenv').config();
const mongoose = require('mongoose');
const Quiz = require('./models/Quiz');
const User = require('./models/User');
const BoardConfig = require('./models/BoardConfig');

const quizzes = [
  {
    question: "Apa itu TBC (Tuberkulosis)?",
    options: [
      "Penyakit yang disebabkan oleh virus",
      "Penyakit yang disebabkan oleh bakteri Mycobacterium tuberculosis",
      "Penyakit yang disebabkan oleh jamur",
      "Penyakit keturunan"
    ],
    correctAnswer: 1,
    explanation: "TBC (Tuberkulosis) adalah penyakit menular yang disebabkan oleh bakteri Mycobacterium tuberculosis. Bakteri ini biasanya menyerang paru-paru, tetapi juga bisa menyerang bagian tubuh lainnya.",
    category: "pengenalan",
    difficulty: "easy"
  },
  {
    question: "Bagaimana TBC menular dari satu orang ke orang lain?",
    options: [
      "Melalui sentuhan kulit",
      "Melalui makanan dan minuman",
      "Melalui udara saat penderita batuk atau bersin",
      "Melalui gigitan nyamuk"
    ],
    correctAnswer: 2,
    explanation: "TBC menular melalui udara. Ketika penderita TBC batuk, bersin, atau berbicara, mereka mengeluarkan bakteri ke udara yang kemudian dapat terhirup oleh orang lain. Penularan terjadi melalui droplet (percikan ludah) di udara.",
    category: "penularan",
    difficulty: "easy"
  },
  {
    question: "Apa gejala utama TBC paru-paru?",
    options: [
      "Demam tinggi mendadak",
      "Batuk berdahak lebih dari 2 minggu",
      "Sakit kepala hebat",
      "Diare berkepanjangan"
    ],
    correctAnswer: 1,
    explanation: "Gejala utama TBC paru adalah batuk berdahak yang berlangsung lebih dari 2 minggu. Gejala lain meliputi batuk darah, demam (terutama sore/malam), keringat malam, penurunan berat badan, dan nafsu makan berkurang.",
    category: "gejala",
    difficulty: "easy"
  },
  {
    question: "Berapa lama pengobatan TBC yang harus dijalani?",
    options: [
      "1-2 minggu",
      "1 bulan",
      "Minimal 6 bulan",
      "1 tahun"
    ],
    correctAnswer: 2,
    explanation: "Pengobatan TBC harus dijalani minimal 6 bulan secara rutin dan tidak boleh putus. Pengobatan yang tidak tuntas dapat menyebabkan bakteri TBC menjadi kebal terhadap obat (resisten), sehingga lebih sulit disembuhkan.",
    category: "pengobatan",
    difficulty: "medium"
  },
  {
    question: "Apa yang dimaksud dengan TBC MDR (Multi Drug Resistant)?",
    options: [
      "TBC yang mudah disembuhkan",
      "TBC yang kebal terhadap obat standar",
      "TBC yang hanya menyerang anak-anak",
      "TBC yang tidak menular"
    ],
    correctAnswer: 1,
    explanation: "TBC MDR adalah TBC yang kebal terhadap setidaknya dua obat anti-TBC utama (Rifampisin dan Isoniazid). TBC MDR terjadi karena pengobatan yang tidak tuntas atau tidak teratur. Pengobatan TBC MDR lebih lama (18-24 bulan) dan lebih mahal.",
    category: "pengobatan",
    difficulty: "hard"
  },
  {
    question: "Siapa yang paling berisiko tertular TBC?",
    options: [
      "Orang dengan sistem kekebalan tubuh lemah",
      "Hanya anak-anak",
      "Hanya orang tua",
      "Orang yang sering berolahraga"
    ],
    correctAnswer: 0,
    explanation: "Orang dengan sistem kekebalan tubuh lemah paling berisiko, termasuk penderita HIV/AIDS, diabetes, malnutrisi, perokok, dan orang yang tinggal berdekatan dengan penderita TBC. Bayi dan lansia juga lebih rentan.",
    category: "penularan",
    difficulty: "medium"
  },
  {
    question: "Bagaimana cara mencegah penularan TBC?",
    options: [
      "Memakai masker saat sakit, ventilasi baik, imunisasi BCG",
      "Hanya minum obat saja",
      "Menghindari matahari",
      "Makan makanan pedas"
    ],
    correctAnswer: 0,
    explanation: "Pencegahan TBC meliputi: menutup mulut saat batuk/bersin, memakai masker jika sakit, menjaga ventilasi rumah agar udara bersirkulasi, imunisasi BCG pada bayi, menjalani pengobatan tuntas, dan menerapkan perilaku hidup bersih dan sehat (PHBS).",
    category: "pencegahan",
    difficulty: "medium"
  },
  {
    question: "Apa fungsi imunisasi BCG?",
    options: [
      "Mencegah semua jenis TBC 100%",
      "Mencegah TBC berat pada anak seperti TBC otak",
      "Mengobati TBC",
      "Tidak ada manfaatnya"
    ],
    correctAnswer: 1,
    explanation: "Imunisasi BCG diberikan pada bayi untuk mencegah TBC berat seperti TBC milier dan TBC meningitis (TBC otak) yang dapat berakibat fatal pada anak. BCG tidak mencegah infeksi TBC 100%, tetapi sangat efektif mencegah bentuk TBC yang berat.",
    category: "pencegahan",
    difficulty: "medium"
  },
  {
    question: "Apa yang harus dilakukan jika ada anggota keluarga menderita TBC?",
    options: [
      "Mengusir dari rumah",
      "Memisahkan semua barang-barangnya",
      "Mendukung pengobatan dan periksa anggota keluarga lain",
      "Tidak perlu melakukan apa-apa"
    ],
    correctAnswer: 2,
    explanation: "Yang harus dilakukan: mendukung penderita menjalani pengobatan tuntas, pastikan penderita menutup mulut saat batuk, periksa kesehatan anggota keluarga lain (terutama anak dan lansia), jaga ventilasi rumah, dan terapkan pola hidup sehat. Jangan mengucilkan penderita.",
    category: "pengobatan",
    difficulty: "medium"
  },
  {
    question: "Apakah TBC bisa disembuhkan?",
    options: [
      "Tidak, TBC tidak bisa disembuhkan",
      "Ya, TBC bisa disembuhkan dengan pengobatan yang tuntas dan teratur",
      "Hanya bisa dikurangi gejalanya",
      "Sembuh dengan sendirinya tanpa obat"
    ],
    correctAnswer: 1,
    explanation: "TBC bisa disembuhkan total dengan pengobatan yang tuntas dan teratur minimal 6 bulan. Obat TBC disediakan gratis oleh pemerintah di puskesmas dan rumah sakit. Yang penting adalah tidak putus obat dan minum obat sesuai anjuran dokter sampai dinyatakan sembuh.",
    category: "pengobatan",
    difficulty: "easy"
  }
];

const adminUser = {
  username: 'admin',
  email: 'admin@ulartangga.com',
  password: 'admin123',
  fullName: 'Administrator',
  role: 'admin'
};

async function seedDatabase() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/ular_tangga', {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });

    console.log('✅ Connected to MongoDB');

    // Clear existing data
    await Quiz.deleteMany({});
    await User.deleteMany({ role: 'admin' });
    await BoardConfig.deleteMany({});

    // Insert quizzes
    const insertedQuizzes = await Quiz.insertMany(quizzes);
    console.log(`✅ Inserted ${insertedQuizzes.length} quizzes`);

    // Create admin user
    const admin = new User(adminUser);
    await admin.save();
    console.log(`✅ Created admin user (username: admin, password: admin123)`);

    // Generate board configs for all 10 levels
    console.log('\n📋 Generating board configurations...');
    
    for (let level = 1; level <= 10; level++) {
      const usedPositions = new Set();
      
      // Generate snakes
      const snakes = [];
      for (let i = 0; i < 10; i++) {
        let start, end;
        do {
          start = Math.floor(Math.random() * 60) + 21; // 21-80
          end = Math.floor(Math.random() * (start - 10)) + 5;
        } while (usedPositions.has(start) || usedPositions.has(end));
        
        snakes.push({ start, end });
        usedPositions.add(start);
        usedPositions.add(end);
      }

      // Generate ladders
      const ladders = [];
      for (let i = 0; i < 10; i++) {
        let start, end;
        do {
          start = Math.floor(Math.random() * 70) + 1; // 1-70
          end = Math.min(start + Math.floor(Math.random() * 20) + 5, 95);
        } while (usedPositions.has(start) || usedPositions.has(end));
        
        ladders.push({ start, end });
        usedPositions.add(start);
        usedPositions.add(end);
      }

      // Assign quizzes to positions
      const quizPositions = [];
      const shuffledQuizzes = [...insertedQuizzes].sort(() => Math.random() - 0.5);
      
      for (let i = 0; i < 10; i++) {
        let position;
        do {
          position = Math.floor(Math.random() * 71) + 10; // 10-80
        } while (usedPositions.has(position));
        
        quizPositions.push({
          position,
          quizId: shuffledQuizzes[i]._id
        });
        usedPositions.add(position);
      }

      const boardConfig = new BoardConfig({
        level,
        snakes,
        ladders,
        quizPositions,
        requiredQuizzes: level,
        boardSize: 100
      });

      await boardConfig.save();
      console.log(`   ✅ Level ${level} - ${snakes.length} snakes, ${ladders.length} ladders, ${quizPositions.length} quizzes`);
    }

    console.log('\n🎉 Database seeded successfully!');
    console.log('\n📝 Admin credentials:');
    console.log('   Username: admin');
    console.log('   Email: admin@ulartangga.com');
    console.log('   Password: admin123');
    console.log('\n⚠️  Please change the admin password after first login!');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
}

seedDatabase();
