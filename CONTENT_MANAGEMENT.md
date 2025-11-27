# Content Management System

Sistem untuk mengelola konten edukatif dan konfigurasi aplikasi dari admin dashboard tanpa perlu rebuild APK.

## 🎯 Fitur

### 1. Konten Edukatif yang Dapat Dikelola
- **Pesan Ular (Snake Messages)**: Pesan untuk perilaku buruk terkait TBC
- **Pesan Tangga (Ladder Messages)**: Pesan untuk perilaku baik terkait TBC
- **Fakta TBC**: Informasi edukatif tentang TBC

### 2. Konfigurasi Aplikasi Dinamis
- **API Settings**: Base URL, timeout, dll
- **Game Settings**: Durasi game, jumlah kuis per level
- **Feature Flags**: Enable/disable fitur seperti multiplayer, guest mode
- **UI Settings**: Maintenance mode, pesan maintenance

## 🏗️ Arsitektur

```
┌─────────────────────┐
│  Admin Dashboard    │
│  (Web Interface)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Backend API       │
│   /api/content      │
│   /api/config       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   MongoDB           │
│   - Content         │
│   - AppConfig       │
└─────────────────────┘

┌─────────────────────┐
│   Flutter App       │
│   ├─ ContentService │
│   ├─ Local Cache    │
│   └─ Fallback Data  │
└─────────────────────┘
```

## 📡 API Endpoints

### Content Management

#### GET /api/content/:type
Mengambil konten berdasarkan tipe (public)
- **Types**: `snake_message`, `ladder_message`, `fact`
- **Response**: `{ success: true, data: ["message1", "message2"] }`

#### GET /api/content (Admin)
Mengambil semua konten dengan filter

#### POST /api/content (Admin)
Membuat konten baru
```json
{
  "type": "snake_message",
  "message": "Lupa minum obat TBC...",
  "isActive": true
}
```

#### PUT /api/content/:id (Admin)
Update konten

#### DELETE /api/content/:id (Admin)
Hapus konten

### Config Management

#### GET /api/config/public
Mengambil semua konfigurasi public (untuk client app)
- **Response**: 
```json
{
  "success": true,
  "data": {
    "api_base_url": "https://apiular.ueu-fasilkom.my.id",
    "api_timeout": 15000,
    "game_min_duration": 300,
    "enable_multiplayer": true
  }
}
```

#### GET /api/config (Admin)
Mengambil semua konfigurasi dengan filter

#### POST /api/config (Admin)
Buat atau update konfigurasi
```json
{
  "key": "api_timeout",
  "value": 15000,
  "description": "API request timeout in milliseconds",
  "category": "api",
  "isPublic": true
}
```

#### DELETE /api/config/:key (Admin)
Hapus konfigurasi

## 🚀 Setup & Installation

### 1. Backend Setup

```bash
cd server

# Install dependencies (jika belum)
npm install

# Seed initial content dan config
node seed-content.js
```

**Output yang diharapkan:**
```
✅ Connected to MongoDB
🗑️  Cleared existing content and configs
✅ Seeded 30 content items
✅ Seeded 14 configurations

📝 Summary:
  - Snake messages: 10
  - Ladder messages: 10
  - Facts: 20
  - Configurations: 14
```

### 2. Restart Backend

```bash
# Development
npm run dev

# Production
docker compose restart socket-server
```

### 3. Verify API

```bash
# Test content endpoint
curl https://apiular.ueu-fasilkom.my.id/api/content/snake_message

# Test config endpoint
curl https://apiular.ueu-fasilkom.my.id/api/config/public
```

## 📱 Flutter App Integration

### ContentService

Service untuk load dan cache konten edukatif:

```dart
import 'package:your_app/services/content_service.dart';

final contentService = ContentService();

// Load content (otomatis dari cache atau API)
await contentService.loadContent();

// Gunakan content
List<String> snakeMessages = contentService.snakeMessages;
List<String> ladderMessages = contentService.ladderMessages;
List<String> facts = contentService.facts;

// Refresh dari API
await contentService.refreshContent();

// Clear cache
await contentService.clearCache();
```

### Caching Strategy

1. **First Load**: Fetch dari API, simpan ke cache
2. **Next Loads**: Load dari cache jika masih valid (24 jam)
3. **Force Refresh**: Bisa dipaksa reload dari API
4. **Fallback**: Jika API dan cache gagal, gunakan default hardcoded

### Config Loading

Config dimuat otomatis saat app start di `SplashScreen`:

```dart
// Di initState
await apiService.applyConfigs();

// Baca config value
final timeout = await apiService.getConfigValue('api_timeout', defaultValue: 15000);
```

## 🎨 Admin Dashboard Usage

### Mengelola Konten

1. **Login** ke admin dashboard
2. **Navigasi** ke menu "📚 Konten Edukatif"
3. **Pilih Tab**:
   - 🐍 Pesan Ular
   - 🪜 Pesan Tangga
   - 💡 Fakta TBC
4. **Tambah/Edit/Hapus** konten sesuai kebutuhan

**Tips:**
- Pesan ular: Fokus pada perilaku buruk yang harus dihindari
- Pesan tangga: Fokus pada perilaku baik yang harus dilakukan
- Fakta: Informasi edukatif yang mendidik pemain

### Mengelola Konfigurasi

1. **Navigasi** ke menu "⚙️ Konfigurasi App"
2. **Pilih Kategori**:
   - 🔌 API: Base URL, timeout
   - 🎮 Game: Durasi, jumlah quiz
   - ✨ Feature: Feature flags
   - 🎨 UI: Appearance settings
3. **Edit** nilai konfigurasi

**Konfigurasi Penting:**

| Key | Value | Deskripsi |
|-----|-------|-----------|
| `api_base_url` | `https://apiular...` | Base URL untuk API |
| `socket_url` | `https://apiular...` | Socket.IO server URL |
| `api_timeout` | `15000` | Timeout dalam ms |
| `game_min_duration` | `300` | Min durasi game (detik) |
| `game_max_duration` | `420` | Max durasi game (detik) |
| `enable_multiplayer` | `true` | Enable/disable multiplayer |
| `enable_guest_mode` | `true` | Allow guest users |
| `maintenance_mode` | `false` | Maintenance mode |
| `min_quiz_required_level1` | `3` | Quiz wajib level 1 |
| `min_quiz_required_level2` | `5` | Quiz wajib level 2 |
| `min_quiz_required_level3` | `7` | Quiz wajib level 3 |

## 🔄 Update Workflow

### Scenario 1: Update Konten Edukatif

1. Admin update konten di dashboard
2. Flutter app akan:
   - Menggunakan cache sampai expired (24 jam)
   - Atau force refresh jika user pull-to-refresh
   - Atau auto-refresh saat app restart

**No rebuild APK needed! ✅**

### Scenario 2: Update API URL

1. Admin update `api_base_url` di config
2. User close & reopen app
3. App load config baru dari `/api/config/public`
4. API calls menggunakan URL baru

**No rebuild APK needed! ✅**

### Scenario 3: Update Game Settings

1. Admin update `game_min_duration` atau `min_quiz_required_level1`
2. User close & reopen app
3. Game menggunakan settings baru

**No rebuild APK needed! ✅**

### Scenario 4: Enable Maintenance Mode

1. Admin set `maintenance_mode = true`
2. Admin set `maintenance_message`
3. User yang membuka app akan melihat maintenance screen

**No rebuild APK needed! ✅**

## 🛡️ Fallback & Error Handling

### Level 1: API Available
- Load dari API
- Save to cache
- Use fresh data

### Level 2: Cache Available
- API error/timeout
- Load from cache
- Use cached data (max 24 jam)

### Level 3: Default Hardcoded
- API error
- Cache expired/tidak ada
- Use default hardcoded values
- App tetap berfungsi normal

## 📊 Monitoring

### Check Content Status

```bash
# Via API
curl https://apiular.ueu-fasilkom.my.id/api/content/snake_message

# Via MongoDB
docker compose exec mongodb mongosh ular_tangga
> db.contents.find({type: "snake_message"}).pretty()
```

### Check Config Status

```bash
# Via API
curl https://apiular.ueu-fasilkom.my.id/api/config/public

# Via MongoDB
> db.appconfigs.find().pretty()
```

### App Logs

```bash
# Android
adb logcat | grep -E "📚|⚙️|ContentService|ConfigService"

# Flutter console
# Look for:
# - 📚 Loading educational content...
# - ⚙️ Loading app configurations...
# - ✅ Content loaded from API
# - 📦 Loading content from cache
```

## 🚨 Troubleshooting

### Content tidak update di app

1. **Check cache**: App menggunakan cache 24 jam
   - Solution: Clear app data atau tunggu 24 jam
   
2. **Check API**: Pastikan API berjalan
   ```bash
   curl https://apiular.ueu-fasilkom.my.id/api/content/fact
   ```

3. **Check logs**: Lihat app logs untuk error

### Config tidak apply

1. **Check isPublic**: Pastikan config `isPublic = true`
2. **Check category**: Pastikan category sesuai
3. **Restart app**: Config hanya dimuat saat app start

### API error

1. **Check backend**: `docker compose logs socket-server`
2. **Check database**: Pastikan MongoDB running
3. **Check network**: Test dengan curl

## 📝 Best Practices

### Content Guidelines

✅ **DO:**
- Gunakan bahasa sederhana untuk anak-anak
- Pesan singkat dan jelas (max 100 karakter)
- Gunakan kata-kata positif untuk tangga
- Gunakan kata-kata edukatif untuk fakta

❌ **DON'T:**
- Jangan gunakan bahasa medis yang rumit
- Jangan buat pesan terlalu panjang
- Jangan gunakan kata-kata menakutkan

### Config Guidelines

✅ **DO:**
- Set `isPublic = true` untuk config yang dibutuhkan client
- Gunakan `description` yang jelas
- Test config sebelum deploy ke production
- Backup config sebelum perubahan besar

❌ **DON'T:**
- Jangan expose sensitive data (passwords, secrets)
- Jangan set `isPublic = true` untuk internal config
- Jangan ubah config production tanpa testing

## 🎓 Examples

### Example: Add New Snake Message

```javascript
// Via API
POST https://apiular.ueu-fasilkom.my.id/api/content
Authorization: Bearer <admin_token>

{
  "type": "snake_message",
  "message": "Tidak cuci tangan sebelum makan, kuman bisa masuk!",
  "isActive": true
}
```

### Example: Update API Timeout

```javascript
// Via API
POST https://apiular.ueu-fasilkom.my.id/api/config
Authorization: Bearer <admin_token>

{
  "key": "api_timeout",
  "value": 20000,
  "description": "API timeout increased to 20 seconds",
  "category": "api",
  "isPublic": true
}
```

### Example: Enable Maintenance Mode

```javascript
// Step 1: Enable maintenance
POST /api/config
{
  "key": "maintenance_mode",
  "value": true
}

// Step 2: Set message
POST /api/config
{
  "key": "maintenance_message",
  "value": "Aplikasi sedang maintenance untuk update konten. Akan kembali dalam 10 menit."
}
```

## 🔗 Related Files

### Backend
- `/server/models/Content.js` - Content model
- `/server/models/AppConfig.js` - Config model
- `/server/controllers/contentController.js` - Content controller
- `/server/controllers/configController.js` - Config controller
- `/server/routes/content.js` - Content routes
- `/server/routes/config.js` - Config routes
- `/server/seed-content.js` - Seeding script

### Frontend
- `/lib/services/content_service.dart` - Content service dengan caching
- `/lib/services/api_service.dart` - API service dengan config loading
- `/lib/screens/game_screen.dart` - Game screen menggunakan dynamic content
- `/lib/screens/splash_screen.dart` - Load configs saat app start

### Admin Dashboard
- `/admin-dashboard/index.html` - UI dengan content & config pages
- `/admin-dashboard/app.js` - Logic untuk manage content & config

## 📞 Support

Jika ada masalah:
1. Check logs di app dan backend
2. Verify API endpoints dengan curl
3. Check MongoDB data
4. Review konfigurasi di admin dashboard

**Happy Managing! 🎉**
