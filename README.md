# 🎲 Game Ular Tangga Edukasi TBC

Game edukasi interaktif tentang Tuberkulosis (TBC) dengan mekanisme Ular Tangga (Snakes and Ladders). Mendukung mode **Single Player** dan **Multiplayer Online** dengan sistem backend database.

## ✨ Fitur Utama

### Game Features
- 🎯 **10 Level Kesulitan** - Konfigurasi papan berbeda untuk setiap level (dari database)
- ⏱️ **Timer 5-7 Menit** - Durasi permainan acak untuk setiap game
- 📚 **Kuis Edukasi TBC** - Pertanyaan multiple choice dengan penjelasan lengkap
- 🎮 **Single Player** - Main sendiri melawan waktu
- 👥 **Multiplayer Online** - Main bersama teman hingga 4 pemain (via WebSocket)
- 🔒 **Guest Restrictions** - Multiplayer hanya untuk pengguna terdaftar, guest hanya single player
- 🐍 **10 Ular & 10 Tangga** - Posisi dinamis dari backend per level
- 🎨 **UI Modern** - Desain gradient dengan Material Design 3

### Backend Features
- 🔐 **Authentication System** - Register, login dengan JWT token
- 💾 **Database Integration** - MongoDB untuk menyimpan data game, user, quiz
- 📊 **Game History Tracking** - Semua permainan tersimpan dengan statistik lengkap
- 🏆 **Leaderboard System** - Ranking pemain berdasarkan kemenangan
- ⚙️ **Admin Dashboard** - Web-based dashboard untuk manage konten
- 🔄 **RESTful API** - Complete API untuk frontend-backend communication
- 🌐 **WebSocket Server** - Real-time multiplayer dengan Socket.IO

## 🏗️ Arsitektur Sistem

```
┌─────────────────────┐
│   Flutter App       │
│  (Mobile Client)    │
└──────┬──────────────┘
       │
       ├─────── HTTP REST API ────────┐
       │                              │
       └─────── WebSocket ───────┐    │
                                 │    │
                    ┌────────────▼────▼─────┐
                    │   Node.js Server      │
                    │   - Express API       │
                    │   - Socket.IO         │
                    │   - JWT Auth          │
                    └──────────┬────────────┘
                               │
                    ┌──────────▼────────────┐
                    │   MongoDB Database    │
                    │   - Users             │
                    │   - Quizzes           │
                    │   - BoardConfigs      │
                    │   - GameHistory       │
                    └───────────────────────┘

┌─────────────────────┐
│  Admin Dashboard    │
│  (Web Interface)    │
└──────┬──────────────┘
       │
       └─────── HTTP REST API ────────┘
```

## 🐳 Docker Services

System ini menggunakan 3 Docker containers:

1. **mongodb** - Database server (Port 27017)
2. **socket-server** - Backend API + WebSocket (Port 3000)
3. **admin-dashboard** - Admin web interface (Port 8080)

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.8.1+
- Dart 2.19+
- Docker & Docker Compose
- Android Studio / Xcode (untuk mobile development)

### One-Command Setup (Recommended)

```bash
# Clone repository
git clone <repository-url>
cd ular_tangga

# Run automated setup (starts Docker, resets DB, seeds everything, installs deps)
chmod +x setup.sh
./setup.sh
```

✅ Script ini akan otomatis:
1. Setup environment variables (.env)
2. Start semua Docker services (MongoDB, Backend, Admin Dashboard)
3. Menunggu services siap
4. **Reset database (clean slate)**
5. Seed database dengan semua data awal (users, quizzes, content, configs, environment)
6. Install Flutter dependencies

⚠️ **IMPORTANT:** Setup akan reset database setiap kali dijalankan!

**Setelah setup selesai, langsung jalankan:**
```bash
flutter run
```

### Manual Setup (Alternative)

<details>
<summary>Klik untuk melihat langkah manual</summary>

#### 1. Setup Environment & Docker

```bash
# Setup environment variables
cp server/.env.example server/.env
# Edit server/.env and update JWT_SECRET for production!

# Start all Docker services
docker compose up -d --build

# Check services status
docker compose ps
```

Services akan berjalan di:
- Backend API: `http://localhost:3000`
- Admin Dashboard: `http://localhost:8080`
- MongoDB: `localhost:27017`

**⚠️ PENTING:** Edit `server/.env` dan ganti `JWT_SECRET` dengan key yang aman untuk production!

#### 2. Seed Database (First Time Only)

```bash
# Seed initial data (admin user, quizzes, board configs)
docker compose exec socket-server node seed.js
```

Default admin credentials:
- Username: `admin`
- Password: `admin123`

#### 3. Install Flutter Dependencies

```bash
flutter pub get
```

#### 4. Run Flutter App

```bash
# Android emulator
flutter run

# iOS simulator
flutter run -d ios

# Chrome (web)
flutter run -d chrome
```

</details>

**Note:** Update API base URL in `lib/services/api_service.dart` if needed:
- Android Emulator: `http://10.0.2.2:3000/api`
- iOS Simulator: `http://localhost:3000/api`
- Real Device: `http://<YOUR_IP>:3000/api`

## 🎮 Cara Bermain

### Single Player
1. Register/Login atau skip sebagai guest
2. Pilih level (1-10) di layar pemilihan level
3. Pilih mode "Single Player"
4. Lempar dadu dengan menekan tombol
5. Jawab kuis di posisi tertentu
6. Menangkan permainan dengan mencapai kotak 100 atau menyelesaikan kuis wajib

### Multiplayer (Hanya untuk pengguna terdaftar)
1. **Login/Register** (multiplayer tidak tersedia untuk guest)
2. Pilih level (1-10) di layar pemilihan level
3. Pilih mode "Multiplayer"
4. **Buat Ruangan**: Masukkan nama dan tekan "Buat Ruangan Baru"
   - Bagikan kode ruangan ke teman
   - Tunggu pemain lain bergabung
   - Tekan "MULAI PERMAINAN" saat semua siap
5. **Gabung Ruangan**: Masukkan kode ruangan yang dibagikan teman
6. Main bergiliran dengan pemain lain
7. Pemain pertama yang menang atau menyelesaikan kuis wajib adalah pemenang!

## 🔐 Authentication Flow

1. **Register** - Buat akun baru dengan username, email, password
2. **Login** - Masuk dengan username dan password
3. **Skip** - Main sebagai guest tanpa login (game history tidak tersimpan)
4. **Logout** - Keluar dari akun (tersedia di menu)

Game history hanya tersimpan untuk user yang login.

## 🛠️ Admin Dashboard

Akses dashboard di `http://localhost:8080`

### Features:
- **Overview** - Statistik total users, games, quizzes
- **Users Management** - View, activate/deactivate users
- **Quizzes CRUD** - Create, edit, delete quiz questions
- **Game History** - View all games played with filters
- **Leaderboard** - Ranking pemain berdasarkan wins/games/quizzes

### Default Admin:
- Username: `admin`
- Password: `admin123`

**⚠️ PENTING:** Ganti password admin setelah first login!

## 📡 API Endpoints

### Authentication
```
POST   /api/auth/register        - Register user baru
POST   /api/auth/login           - Login user
GET    /api/auth/profile         - Get user profile (auth required)
```

### Board Configuration
```
GET    /api/board                - Get all board configs
GET    /api/board/:level         - Get board config by level
POST   /api/board                - Create board config (admin)
PUT    /api/board/:id            - Update board config (admin)
POST   /api/board/generate       - Generate random board config (admin)
```

### Quizzes
```
GET    /api/quiz                 - Get all quizzes
GET    /api/quiz/:id             - Get quiz by ID
POST   /api/quiz                 - Create quiz (admin)
PUT    /api/quiz/:id             - Update quiz (admin)
DELETE /api/quiz/:id             - Delete quiz (admin)
```

### Game History
```
POST   /api/game/history         - Save game history (auth required)
GET    /api/game/history         - Get user game history (auth required)
GET    /api/game/leaderboard     - Get leaderboard (public)
```

### Users (Admin Only)
```
GET    /api/users                - Get all users
GET    /api/users/:id            - Get user by ID
PUT    /api/users/:id            - Update user
DELETE /api/users/:id            - Delete user
PUT    /api/users/:id/activate   - Activate/deactivate user
```

## ⚙️ Environment Configuration

### Server Environment Variables (`server/.env`)

```env
# Server Configuration
NODE_ENV=production              # Environment: production/development
PORT=3000                        # Server port

# MongoDB Configuration
MONGODB_URI=mongodb://admin:ulartangga123@mongodb:27017/ular_tangga?authSource=admin

# JWT Configuration
JWT_SECRET=your-secret-key       # ⚠️ CHANGE THIS IN PRODUCTION!
JWT_EXPIRES_IN=30d               # Token expiration (30 days)

# CORS Configuration
CORS_ORIGIN=*                    # Allowed origins (* for dev, domain for prod)

# Socket.IO Configuration
SOCKET_CORS_ORIGIN=*             # WebSocket CORS
```

**Setup:**
```bash
# Copy template
cp server/.env.example server/.env

# Edit and customize
nano server/.env  # or use your preferred editor
```

**Security Notes:**
- 🔒 Change `JWT_SECRET` to a strong random string in production
- 🔒 Update `CORS_ORIGIN` to your specific domain in production
- 🔒 Never commit `.env` file to git (already in .gitignore)
- 🔒 Use environment-specific values for different deployments

## 📦 Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.8.1
- **Language**: Dart 2.19
- **State Management**: setState + TickerProviderStateMixin
- **HTTP Client**: http 1.1.0
- **WebSocket**: socket_io_client 2.0.3+1
- **Local Storage**: shared_preferences 2.2.2
- **UI**: Material Design 3

### Backend (Node.js)
- **Runtime**: Node.js 18
- **Framework**: Express 4.18.2
- **WebSocket**: Socket.IO 4.7.2
- **Database**: MongoDB 7.0 with Mongoose ODM
- **Authentication**: JWT (jsonwebtoken 9.0.2) + bcryptjs 2.4.3
- **CORS**: cors 2.8.5

### Admin Dashboard
- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Server**: Nginx Alpine
- **Styling**: Modern gradient design, responsive layout

### DevOps
- **Containerization**: Docker & Docker Compose
- **Orchestration**: docker compose.yml with 3 services
- **Networking**: Bridge network (ular-tangga-network)

## 🗄️ Database Schema

### User Model
```javascript
{
  username: String (unique),
  email: String (unique),
  password: String (hashed with bcrypt),
  fullName: String,
  role: String (user/admin),
  isActive: Boolean,
  createdAt: Date
}
```

### Quiz Model
```javascript
{
  question: String,
  options: [String],
  correctAnswer: Number,
  explanation: String,
  category: String,
  difficulty: String (easy/medium/hard),
  createdAt: Date
}
```

### BoardConfig Model
```javascript
{
  level: Number (1-10, unique),
  snakes: [{ start: Number, end: Number }],
  ladders: [{ start: Number, end: Number }],
  quizPositions: [{ position: Number, quizId: ObjectId }],
  requiredQuizzes: Number,
  boardSize: Number (100),
  isActive: Boolean
}
```

### GameHistory Model
```javascript
{
  gameId: String,
  gameMode: String (single/multiplayer),
  level: Number,
  players: [{
    userId: ObjectId,
    username: String,
    finalPosition: Number,
    quizzesAnswered: Number,
    quizzesCorrect: Number,
    isWinner: Boolean,
    playTime: Number
  }],
  quizzes: [ObjectId],
  startedAt: Date,
  endedAt: Date,
  duration: Number
}
```
4. **Gabung Ruangan**: Masukkan nama dan kode ruangan, tekan "Gabung Ruangan"
   - Tekan tombol "SIAP" saat sudah siap
   - Tunggu host memulai permainan
5. Bermain bergantian dengan pemain lain
6. Pemain pertama yang mencapai kotak 100 dengan menyelesaikan kuis wajib adalah pemenangnya!

## 🔧 Konfigurasi Server

### Untuk Testing di Emulator/Simulator

Di aplikasi, klik ikon **⚙️ Settings** di Multiplayer Lobby, lalu masukkan:

- **Android Emulator**: `http://10.0.2.2:3000`
- **iOS Simulator**: `http://localhost:3000`
- **Physical Device**: `http://[YOUR_COMPUTER_IP]:3000`
  
  Contoh: `http://192.168.1.100:3000`

### Cara Mendapatkan IP Komputer

**Windows:**
```bash
ipconfig
```
Cari "IPv4 Address" di bagian WiFi/Ethernet

**Mac/Linux:**
```bash
ifconfig
```
atau
```bash
ip addr show
```

### Mengubah Port Server

Edit `docker compose.yml`:
```yaml
ports:
  - "8080:3000"  # Ubah 8080 ke port yang diinginkan
```

## 📁 Struktur Project

```
lib/
├── main.dart ✅
├── models/
│   └── player.dart ✅
├── screens/
│   ├── splash_screen.dart ✅
│   ├── auth_screen.dart ✅
│   ├── instructions_screen.dart ✅
│   ├── level_selection_screen.dart ✅
│   ├── mode_selection_screen.dart ✅
│   ├── game_screen.dart ✅
│   └── multiplayer/
│       ├── lobby_screen.dart ✅
│       └── waiting_room_screen.dart ✅
└── services/
    ├── api_service.dart
    └── socket_service.dart
```

## 🛠️ Tech Stack

### Frontend (Flutter)
- **Flutter 3.8.1** - UI Framework
- **Material Design 3** - Design System
- **socket_io_client** - WebSocket client untuk multiplayer
- **uuid** - Generate unique IDs

### Backend (Node.js)
- **Node.js 18** - Runtime environment
- **Socket.IO 4.7.2** - Real-time bidirectional communication
- **Express** - (Optional) HTTP server
- **Docker** - Containerization

## 📱 Screenshots

(Tambahkan screenshots aplikasi Anda di sini)

## 🎯 Game Mechanics

### Dice Roll
- Hanya keluar angka 4-6 (untuk mempercepat permainan)
- Popup dialog menampilkan hasil
- Klik "JALANKAN" untuk memulai pergerakan

### Timer System
- Durasi acak 5-7 menit (300-420 detik)
- Countdown ditampilkan di header
- Warna merah saat < 60 detik
- Game berakhir saat waktu habis

### Level System
- Level 1: Wajib selesaikan 1 kuis dari 10
- Level 2: Wajib selesaikan 2 kuis dari 10
- ...
- Level 10: Wajib selesaikan 10 kuis dari 10

### Win Condition (Single Player)
- Capai kotak 100
- Selesaikan jumlah kuis sesuai level
- Sebelum waktu habis

### Win Condition (Multiplayer)
- Pemain pertama yang capai kotak 100
- Dengan menyelesaikan jumlah kuis sesuai level

## 🐛 Troubleshooting

### Server tidak bisa terhubung
- Pastikan Docker Compose sudah running: `docker compose ps`
- Cek logs: `docker compose logs -f socket-server`
- Pastikan port 3000 tidak digunakan aplikasi lain
- Pastikan firewall tidak memblokir port 3000

### Koneksi timeout di device
- Pastikan device dan komputer di jaringan WiFi yang sama
- Cek IP address komputer: `ipconfig` (Windows) atau `ifconfig` (Mac/Linux)
- Update URL di Settings aplikasi dengan IP yang benar
- Pastikan firewall tidak memblokir koneksi

### Build error
```bash
flutter clean
flutter pub get
flutter run
```

## 📝 Development Notes

### Menjalankan Server untuk Development

```bash
cd server
npm install
npm run dev  # with nodemon auto-reload
```

### Testing

```bash
flutter test
```

## 🚀 Production Deployment

Untuk deploy aplikasi ke VPS/server production dengan domain sendiri, lihat dokumentasi lengkap:

📘 **[PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)**

**Domain Setup:**
- `api.yourdomain.com` → Backend API + Socket.IO
- `admin.yourdomain.com` → Admin Dashboard

**Includes:**
- Nginx configuration
- SSL/HTTPS setup dengan Let's Encrypt
- Docker Compose production config
- Security checklist
- Monitoring & backup strategies

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author Jefry Sunupurwa Asri

Dibuat untuk edukasi tentang Tuberkulosis (TBC) di Indonesia.

## 🙏 Acknowledgments

- Flutter Team
- Socket.IO Team
- Ikon dari Material Icons
