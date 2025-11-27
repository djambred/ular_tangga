# 🚀 Quick Reference Guide

## Essential Commands

### Setup & Start (One Command)
```bash
# Automated setup - starts everything!
chmod +x setup.sh
./setup.sh
```

**✅ Script otomatis menjalankan:**
- Setup environment (.env)
- Start Docker services (MongoDB, Backend, Admin Dashboard)
- Wait for services to be ready
- Seed database with initial data
- Install Flutter dependencies

### Manual Setup (Alternative)
```bash
docker compose up -d --build
docker compose exec socket-server node seed.js
flutter pub get
```

### Run Application
```bash
# Flutter
flutter run                    # Default device
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios             # iOS

# Backend only
docker compose up -d
```

### Stop Services
```bash
docker compose down            # Stop all containers
docker compose down -v         # Stop and remove volumes
```

### View Logs
```bash
docker compose logs -f                    # All services
docker compose logs -f socket-server     # Backend only
docker compose logs -f mongodb           # Database only
flutter logs                             # Flutter logs
```

---

## Quick Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Backend API | http://localhost:3000 | - |
| Admin Dashboard | http://localhost:8080 | admin / admin123 |
| MongoDB | mongodb://localhost:27017 | admin / ulartangga123 |

---

## API Base URLs

### Android Emulator
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

### iOS Simulator
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

### Real Device
```dart
static const String baseUrl = 'http://YOUR_IP_ADDRESS:3000/api';
```

**File to edit:** `lib/services/api_service.dart`

---

## Common API Endpoints

### Authentication
```bash
# Register
POST /api/auth/register
Body: { username, email, password, fullName }

# Login
POST /api/auth/login
Body: { username, password }

# Get Profile (Auth Required)
GET /api/auth/profile
Header: Authorization: Bearer TOKEN
```

### Board Configuration
```bash
# Get board for specific level
GET /api/board/1          # Replace 1 with level 1-10

# Get all boards
GET /api/board
```

### Game History
```bash
# Save game (Auth Required)
POST /api/game/history
Header: Authorization: Bearer TOKEN
Body: { gameMode, level, players, quizzes, duration }

# Get leaderboard
GET /api/game/leaderboard
```

---

## Database Quick Access

### Connect to MongoDB
```bash
docker compose exec mongodb mongosh -u admin -p ulartangga123 --authenticationDatabase admin
```

### Common MongoDB Commands
```javascript
// Use database
use ular_tangga

// View collections
show collections

// Count documents
db.users.countDocuments()
db.quizzes.countDocuments()
db.boardconfigs.countDocuments()

// Find documents
db.users.find().pretty()
db.boardconfigs.findOne({ level: 1 })

// Exit
exit
```

---

## Flutter Commands

### Build
```bash
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle
flutter build ios              # iOS build
flutter build web              # Web build
```

### Clean & Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### Analysis
```bash
flutter analyze                # Check for issues
flutter test                   # Run tests
```

---

## Docker Commands

### Container Management
```bash
docker compose ps              # List containers
docker compose restart         # Restart all
docker compose restart socket-server  # Restart specific

docker compose exec socket-server sh  # Shell into container
docker compose exec mongodb bash      # Shell into MongoDB
```

### Database Management
```bash
# Backup database
docker compose exec mongodb mongodump -u admin -p ulartangga123 --authenticationDatabase admin -d ular_tangga -o /backup

# Restore database
docker compose exec mongodb mongorestore -u admin -p ulartangga123 --authenticationDatabase admin /backup

# Reset database
docker compose down -v
docker compose up -d
docker compose exec socket-server node seed.js
```

---

## Testing Endpoints

### Test Backend Health
```bash
curl http://localhost:3000/
# Expected: {"message":"Ular Tangga API Server"}
```

### Test Authentication
```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"test123","fullName":"Test User"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'
```

### Test Board Config
```bash
curl http://localhost:3000/api/board/1
```

---

## File Locations

### Key Flutter Files
```
lib/
├── main.dart                  # Main application
└── services/
    ├── api_service.dart       # REST API client
    └── socket_service.dart    # WebSocket client
```

### Key Backend Files
```
server/
├── index.js                   # Main server
├── seed.js                    # Database seed script
├── models/                    # Database schemas
├── controllers/               # Business logic
├── routes/                    # API routes
└── middleware/                # Auth middleware
```

### Admin Dashboard
```
admin-dashboard/
├── index.html                 # UI structure
├── app.js                     # Functionality
├── style.css                  # Styling
└── nginx.conf                 # Nginx config
```

---

## Environment Variables

### Backend (.env or docker compose.yml)
```env
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb://admin:ulartangga123@mongodb:27017/ular_tangga?authSource=admin
JWT_SECRET=your-secret-key-change-this-in-production
```

### Flutter (api_service.dart)
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

---

## Default Credentials

### Admin Dashboard
- **Username:** admin
- **Password:** admin123
- **⚠️ Change after first login!**

### MongoDB
- **Username:** admin
- **Password:** ulartangga123
- **Database:** ular_tangga

---

## Troubleshooting

### Issue: "Connection refused" from Flutter
**Solution:** Check API URL based on platform
```dart
// Android Emulator
'http://10.0.2.2:3000/api'

// iOS Simulator or Web
'http://localhost:3000/api'

// Real Device
'http://YOUR_IP:3000/api'
```

### Issue: Board config not loading
**Solution:**
```bash
# Check if seed ran
docker compose exec socket-server node seed.js

# Verify in database
docker compose exec mongodb mongosh -u admin -p ulartangga123 --authenticationDatabase admin
use ular_tangga
db.boardconfigs.countDocuments()  # Should be 10
```

### Issue: Admin dashboard can't connect
**Solution:**
```bash
# Check server logs
docker compose logs socket-server

# Restart containers
docker compose restart
```

### Issue: MongoDB connection failed
**Solution:**
```bash
# Check MongoDB logs
docker compose logs mongodb

# Ensure volume is healthy
docker volume inspect ular_tangga_mongodb_data

# Recreate if needed
docker compose down -v
docker compose up -d
```

---

## Port Reference

| Port | Service | Protocol |
|------|---------|----------|
| 3000 | Backend API + Socket.IO | HTTP + WS |
| 8080 | Admin Dashboard | HTTP |
| 27017 | MongoDB | TCP |

**Firewall:** Ensure these ports are open for local development.

---

## Git Commands (If using version control)

```bash
# Initial commit
git init
git add .
git commit -m "Initial commit: Complete Ular Tangga TBC game"

# Ignore sensitive files
echo ".env" >> .gitignore
echo "*.log" >> .gitignore
git add .gitignore
git commit -m "Add gitignore"
```

---

## Performance Benchmarks

### Expected Response Times
- API Health Check: < 50ms
- Board Config Load: < 100ms
- Game History Save: < 200ms
- Login/Register: < 300ms

### Expected Loading Times
- Flutter App Launch: < 3s
- Board Loading: < 2s
- Game Start: < 1s

---

## Development Tips

### Hot Reload (Flutter)
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Auto-restart Backend
```bash
# Install nodemon (development)
npm install -g nodemon

# Run with auto-restart
cd server
nodemon index.js
```

### Debug Mode
```bash
# Flutter
flutter run --debug
flutter run --profile
flutter run --release

# Backend (shows more logs)
NODE_ENV=development docker compose up
```

---

## Quick Testing Checklist

### Pre-deployment Tests
- [ ] `./setup.sh` runs without errors
- [ ] All 3 Docker containers running
- [ ] Admin dashboard loads at localhost:8080
- [ ] Backend API responds at localhost:3000
- [ ] Flutter app connects to backend
- [ ] User can register and login
- [ ] Single player game works
- [ ] Game history saves
- [ ] Admin can create/edit quizzes

### Before Committing Code
- [ ] `flutter analyze` passes
- [ ] No console errors in Flutter
- [ ] Backend logs show no errors
- [ ] All API endpoints return correct data
- [ ] Database has correct seed data

---

## User Access Control

### Guest Users (Skip Login)
- ✅ Can play Single Player mode
- ❌ Cannot access Multiplayer mode
- 💡 Shown login prompt when trying multiplayer
- 🎯 Encouraged to register for full features

### Registered Users
- ✅ Full access to Single Player
- ✅ Full access to Multiplayer
- ✅ Game history saved to profile
- ✅ Leaderboard participation

**See:** `GUEST_USER_RESTRICTIONS.md` for technical details

---

## Support Resources

### Documentation
- **README.md** - Project overview and setup
- **TESTING.md** - Comprehensive testing guide
- **COMPLETION_SUMMARY.md** - Feature completion status
- **GUEST_USER_RESTRICTIONS.md** - Guest user access control
- **MULTIPLAYER_TROUBLESHOOTING.md** - Fix connection issues
- **This file** - Quick reference

### Logs Location
```bash
# Backend logs
docker compose logs socket-server > backend.log

# Flutter logs
flutter logs > flutter.log

# MongoDB logs
docker compose logs mongodb > mongodb.log
```

---

## Useful Aliases (Optional)

Add to your `~/.zshrc` or `~/.bashrc`:
```bash
# Docker shortcuts
alias dc='docker compose'
alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dclogs='docker compose logs -f'

# Flutter shortcuts
alias fr='flutter run'
alias fa='flutter analyze'
alias fc='flutter clean'

# Project shortcuts
alias ular='cd /root/project/ular_tangga'
```

Then run: `source ~/.zshrc`

---

**Last Updated:** [Current Date]  
**Quick Reference Version:** 1.0.0
