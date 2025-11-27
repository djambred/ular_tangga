# 🚀 Konfigurasi Production - Flutter App

## URL Production yang Sudah Dikonfigurasi

- **API Backend**: `https://apiular.ueu-fasilkom.my.id`
- **Admin Dashboard**: `https://adminular.ueu-fasilkom.my.id`

---

## File yang Sudah Diupdate

### 1. API Service (`lib/services/api_service.dart`)
```dart
String _baseUrl = 'https://apiular.ueu-fasilkom.my.id/api';
```

Endpoints yang tersedia:
- `POST /api/auth/register` - Register user baru
- `POST /api/auth/login` - Login user
- `GET /api/users/me` - Get user profile
- `GET /api/board-configs` - Get board configurations
- `GET /api/quizzes` - Get quiz questions

### 2. Socket.IO Service (`lib/screens/multiplayer/lobby_screen.dart`)
```dart
String _serverUrl = 'https://apiular.ueu-fasilkom.my.id';
```

WebSocket endpoints:
- `wss://apiular.ueu-fasilkom.my.id/socket.io/` - Multiplayer real-time

---

## Build Production APK

### Build Release APK
```bash
cd /root/project/ular_tangga
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build Split APKs (Smaller size)
```bash
flutter build apk --split-per-abi --release
```

Output:
- `app-armeabi-v7a-release.apk` (ARM 32-bit)
- `app-arm64-v8a-release.apk` (ARM 64-bit) - **Recommended**
- `app-x86_64-release.apk` (x86 64-bit)

---

## Testing Production

### 1. Test API Connection
```bash
# Test health endpoint
curl https://apiular.ueu-fasilkom.my.id/api/health

# Test register (should return validation error karena tanpa data)
curl -X POST https://apiular.ueu-fasilkom.my.id/api/auth/register

# Test dengan data lengkap
curl -X POST https://apiular.ueu-fasilkom.my.id/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"test123","fullName":"Test User"}'
```

### 2. Test Socket.IO Connection
```bash
# Install socket.io-client for testing
npm install -g socket.io-client

# Test connection
node -e "
const io = require('socket.io-client');
const socket = io('https://apiular.ueu-fasilkom.my.id', {
  transports: ['websocket', 'polling']
});
socket.on('connect', () => {
  console.log('✅ Socket.IO connected!');
  process.exit(0);
});
socket.on('connect_error', (err) => {
  console.log('❌ Connection error:', err.message);
  process.exit(1);
});
"
```

### 3. Test dari Flutter App

Install APK di device dan test:
- ✅ Splash screen
- ✅ Login/Register
- ✅ Single player game
- ✅ Multiplayer lobby (connect to server)
- ✅ Create/join room
- ✅ Play multiplayer game

---

## Switching Between Environments

Jika perlu switch antara development dan production:

### Option 1: Environment Variables
Buat file `lib/config/environment.dart`:

```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://apiular.ueu-fasilkom.my.id/api',
  );
  
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://apiular.ueu-fasilkom.my.id',
  );
}
```

Build dengan environment:
```bash
# Development
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:3000/api

# Production
flutter build apk --dart-define=API_BASE_URL=https://apiular.ueu-fasilkom.my.id/api
```

### Option 2: Flavor-based Configuration
Untuk setup yang lebih advance dengan multiple environments (dev, staging, prod).

---

## Troubleshooting

### Error: "Connection timeout"
**Penyebab:** Backend tidak berjalan atau SSL issue

**Fix:**
```bash
# Di VPS, cek status
docker compose ps
docker compose logs socket-server --tail=50

# Restart jika perlu
docker compose restart socket-server
```

### Error: "SSL handshake failed"
**Penyebab:** Certificate issue

**Fix:**
```bash
# Di VPS, cek certificate
sudo certbot certificates

# Renew jika expired
sudo certbot renew

# Reload nginx
sudo nginx -t && sudo systemctl reload nginx
```

### Error: "Network unreachable"
**Penyebab:** Device tidak terhubung internet atau firewall

**Fix:**
- Pastikan device terhubung internet
- Cek firewall VPS: `sudo ufw status`
- Test dengan curl dari device: `curl https://apiular.ueu-fasilkom.my.id/`

### Multiplayer: "Tidak terhubung ke server"
**Penyebab:** WebSocket blocked atau server down

**Fix:**
```bash
# Test WebSocket di VPS
curl -I https://apiular.ueu-fasilkom.my.id/socket.io/

# Harus return: HTTP/2 200
# Cek logs
docker compose logs socket-server | grep socket.io
```

---

## Deploy APK ke Play Store

### 1. Generate Signing Key
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### 2. Configure Signing
Edit `android/key.properties`:
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

### 3. Build App Bundle
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 4. Upload ke Play Console
- Buka https://play.google.com/console
- Upload `app-release.aab`
- Isi metadata, screenshot, dll
- Submit for review

---

## Security Checklist

- ✅ HTTPS enabled untuk API
- ✅ HTTPS enabled untuk Admin
- ✅ JWT token dengan expiration
- ✅ Password di-hash dengan bcrypt
- ✅ CORS configured properly
- ✅ Rate limiting (jika ada)
- ✅ Input validation di backend
- ✅ SQL injection prevention (MongoDB)
- ✅ XSS protection headers

---

## Monitoring

### Backend Logs
```bash
# Real-time logs
docker compose logs -f socket-server

# Last 100 lines
docker compose logs socket-server --tail=100

# Error logs only
docker compose logs socket-server | grep ERROR
```

### Nginx Logs
```bash
# Access logs
sudo tail -f /var/log/nginx/access.log

# Error logs
sudo tail -f /var/log/nginx/error.log
```

### Database Logs
```bash
docker compose logs -f mongodb
```

---

## Backup

### Database Backup
```bash
# Manual backup
docker compose exec mongodb mongodump \
  --username=admin \
  --password=ulartangga123 \
  --authenticationDatabase=admin \
  --db=ular_tangga \
  --out=/data/backup

# Copy ke host
docker cp ular-tangga-mongodb:/data/backup ./mongodb-backup-$(date +%Y%m%d)
```

### Restore Database
```bash
docker compose exec mongodb mongorestore \
  --username=admin \
  --password=ulartangga123 \
  --authenticationDatabase=admin \
  --db=ular_tangga \
  /data/backup/ular_tangga
```

---

## Update Production

### Update Backend Code
```bash
# Di VPS
cd /opt/ular_tangga
git pull origin main

# Rebuild & restart
docker compose down
docker compose up -d --build

# Cek logs
docker compose logs -f socket-server
```

### Update Flutter App
```bash
# Build APK baru
flutter build apk --release

# Distribute APK atau upload ke Play Store
```

---

## Performance Tips

### Backend
- Enable MongoDB indexing untuk queries
- Use Redis untuk caching (optional)
- Enable compression di Nginx
- Monitor memory usage: `docker stats`

### Flutter
- Use `--release` mode untuk production
- Enable code obfuscation: `flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols`
- Optimize images dengan `flutter pub run flutter_native_splash:create`
- Remove unused resources

---

## Support

Jika ada masalah, kirim:

1. **Backend logs:**
   ```bash
   docker compose logs socket-server --tail=100
   ```

2. **Nginx logs:**
   ```bash
   sudo tail -100 /var/log/nginx/error.log
   ```

3. **Flutter error:**
   Screenshot dari app atau logcat output

4. **System info:**
   ```bash
   docker compose ps
   curl -I https://apiular.ueu-fasilkom.my.id/
   ```
