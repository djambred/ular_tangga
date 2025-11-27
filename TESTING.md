# 🧪 Testing Guide - Game Ular Tangga Edukasi TBC

This guide will help you test all features of the system end-to-end.

## Prerequisites

Make sure you have run the setup:
```bash
./setup.sh
```

Or manually:
```bash
docker compose up -d --build
docker compose exec socket-server node seed.js
flutter pub get
```

## 1. Backend API Testing

### 1.1 Test Server Health
```bash
curl http://localhost:3000/
```
Expected: `{"message":"Ular Tangga API Server"}`

### 1.2 Test Authentication

**Register a new user:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "test123",
    "fullName": "Test User"
  }'
```

Expected: JWT token in response

**Login:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "test123"
  }'
```

Save the token from response for next requests.

### 1.3 Test Board Configuration

**Get board config for level 1:**
```bash
curl http://localhost:3000/api/board/1
```

Expected: JSON with snakes, ladders, quizPositions

**Get all board configs:**
```bash
curl http://localhost:3000/api/board
```

Expected: Array of 10 board configurations

### 1.4 Test Quizzes

**Get all quizzes:**
```bash
curl http://localhost:3000/api/quiz
```

Expected: Array of quiz questions

### 1.5 Test Game History (Requires Auth)

**Save game history:**
```bash
curl -X POST http://localhost:3000/api/game/history \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "gameMode": "single",
    "level": 1,
    "players": [{
      "username": "testuser",
      "finalPosition": 100,
      "quizzesAnswered": 5,
      "quizzesCorrect": 4,
      "isWinner": true,
      "playTime": 120
    }],
    "quizzes": [],
    "duration": 120
  }'
```

**Get leaderboard:**
```bash
curl http://localhost:3000/api/game/leaderboard
```

Expected: Array of top players

## 2. Admin Dashboard Testing

### 2.1 Access Dashboard
1. Open browser: `http://localhost:8080`
2. Login with:
   - Username: `admin`
   - Password: `admin123`

### 2.2 Test Overview Page
- ✅ Check total users count
- ✅ Check total games count
- ✅ Check total quizzes count
- ✅ View recent games table
- ✅ View recent users table

### 2.3 Test Users Management
1. Navigate to "Users" page
2. ✅ Search for user "testuser"
3. ✅ Filter by role (admin/user)
4. ✅ Toggle user active status
5. ✅ Pagination works correctly

### 2.4 Test Quizzes CRUD
1. Navigate to "Quizzes" page

**Create Quiz:**
2. Click "Tambah Pertanyaan Baru"
3. Fill in:
   - Question: "Test question?"
   - Options: A, B, C, D
   - Correct Answer: 0
   - Explanation: "Test explanation"
   - Category: "Prevention"
   - Difficulty: "easy"
4. ✅ Click "Simpan" - Quiz should appear in table

**Edit Quiz:**
5. Click "Edit" on any quiz
6. Modify the question
7. ✅ Click "Simpan" - Changes should be saved

**Delete Quiz:**
8. Click "Hapus" on test quiz
9. ✅ Confirm deletion - Quiz should be removed

### 2.5 Test Game History
1. Navigate to "Games" page
2. ✅ Filter by mode (single/multiplayer)
3. ✅ Filter by level (1-10)
4. ✅ Pagination works
5. ✅ View game details

### 2.6 Test Leaderboard
1. Navigate to "Leaderboard" page
2. ✅ Switch between tabs (Wins, Games, Quizzes)
3. ✅ Verify sorting works
4. ✅ Check player statistics

## 3. Flutter App Testing

### 3.1 Start Flutter App
```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web (Chrome)
flutter run -d chrome
```

**Note:** If using real device, update API URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://YOUR_IP:3000/api';
```

### 3.2 Test Authentication Flow

**Test Registration:**
1. Launch app
2. On AuthScreen, click "Daftar"
3. Fill in:
   - Username: `testplayer`
   - Email: `player@test.com`
   - Password: `test123`
   - Full Name: `Test Player`
4. ✅ Click "DAFTAR" - Should navigate to Instructions screen
5. ✅ Verify token is saved (auto-login on next launch)

**Test Login:**
1. Close and reopen app
2. ✅ Should auto-login and go to Instructions screen
3. ✅ Click logout (if available)
4. On AuthScreen, switch to "Masuk"
5. Enter username and password
6. ✅ Click "MASUK" - Should navigate to Instructions screen

**Test Skip (Guest Mode):**
1. On AuthScreen, click "Skip (Main sebagai Guest)"
2. ✅ Should navigate to Instructions screen without login

### 3.3 Test Single Player Game

**Test Board Loading:**
1. Click "MULAI PERMAINAN"
2. Select level 1-10
3. Click "Single Player"
4. ✅ Verify loading indicator appears
5. ✅ Verify board loads from backend (not random)
6. ✅ Verify 10 snakes, 10 ladders, 10 quiz positions shown

**Test Game Mechanics:**
7. ✅ Click "LEMPAR DADU" - Dice animation should show
8. ✅ Player piece moves correctly
9. ✅ Hit snake - should slide down
10. ✅ Hit ladder - should climb up
11. ✅ Hit quiz position - quiz dialog appears
12. ✅ Answer quiz correctly - piece continues
13. ✅ Timer counts down correctly

**Test Win Condition:**
14. Play until reaching position 100 OR completing required quizzes
15. ✅ Win dialog appears with statistics
16. ✅ If logged in, verify game history is saved
17. ✅ Click "MAIN LAGI" - Game resets

**Test Time Up:**
18. Start new game and wait for timer to reach 0
19. ✅ Time up dialog appears
20. ✅ Shows quizzes completed count
21. ✅ If logged in, verify game history is saved

### 3.4 Test Multiplayer Game

**Create Room (Player 1):**
1. Select level and click "Multiplayer"
2. Click "Buat Ruangan"
3. Enter name: "Player1"
4. Click "Buat Ruangan Baru"
5. ✅ Room code appears
6. ✅ Share room code with another device

**Join Room (Player 2):**
7. On second device, select same level
8. Click "Multiplayer"
9. Click "Gabung Ruangan"
10. Enter name: "Player2"
11. Enter room code from Player 1
12. Click "Gabung Ruangan"
13. ✅ Verify both players see each other

**Start Game:**
14. Both players click "SIAP"
15. Host clicks "MULAI PERMAINAN"
16. ✅ Game starts for all players
17. ✅ Turns rotate correctly
18. ✅ All players see each other's moves
19. ✅ Quiz answers don't interfere between players
20. ✅ First player to win triggers win dialog

### 3.5 Test Game History Persistence

**Logged In User:**
1. Login as user
2. Play and complete a single player game
3. Open Admin Dashboard
4. Navigate to "Games" page
5. ✅ Verify your game appears in history
6. ✅ Verify statistics are correct (position, quizzes, time)

**Guest User:**
1. Skip login (play as guest)
2. Complete a game
3. Open Admin Dashboard
4. ✅ Verify game is NOT saved (guest games don't persist)

## 4. WebSocket Testing

### 4.1 Test Real-time Updates
1. Open two devices/browsers
2. Both join same multiplayer room
3. Player 1 rolls dice
4. ✅ Player 2 sees the move in real-time
5. Player 2 rolls dice
6. ✅ Player 1 sees the move immediately

### 4.2 Test Connection Handling
1. Start multiplayer game
2. Turn off wifi on one device
3. ✅ Other player should continue
4. Turn wifi back on
5. ✅ Reconnection should work (if implemented)

## 5. Database Verification

### 5.1 Check Database Contents
```bash
# Connect to MongoDB container
docker compose exec mongodb mongosh -u admin -p ulartangga123 --authenticationDatabase admin

# Use the database
use ular_tangga

# Check collections
show collections

# Count documents
db.users.countDocuments()
db.quizzes.countDocuments()
db.boardconfigs.countDocuments()
db.gamehistories.countDocuments()

# View a sample user
db.users.findOne()

# View board config for level 1
db.boardconfigs.findOne({ level: 1 })

# View recent game histories
db.gamehistories.find().sort({ createdAt: -1 }).limit(5)

# Exit
exit
```

### 5.2 Verify Data Integrity
✅ All 10 board configs exist (level 1-10)
✅ Each board has 10 snakes, 10 ladders, 10 quiz positions
✅ Quizzes have all required fields
✅ Users have hashed passwords (not plain text)
✅ Game histories have complete player data

## 6. Performance Testing

### 6.1 API Response Time
```bash
# Test board config endpoint
time curl http://localhost:3000/api/board/1
```
Expected: < 100ms

### 6.2 Board Loading Time
1. Start Flutter app
2. Select level and start single player game
3. ✅ Board should load in < 2 seconds

### 6.3 Multiplayer Latency
1. Start multiplayer game
2. Roll dice
3. ✅ Other player should see move in < 500ms

## 7. Error Handling Testing

### 7.1 Test Invalid Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "invalid", "password": "wrong"}'
```
Expected: 401 Unauthorized

### 7.2 Test Invalid Board Level
```bash
curl http://localhost:3000/api/board/99
```
Expected: 404 Not Found

### 7.3 Test Unauthorized Access
```bash
curl -X POST http://localhost:3000/api/quiz \
  -H "Content-Type: application/json" \
  -d '{"question": "Test"}'
```
Expected: 401 Unauthorized (missing token)

### 7.4 Test Flutter Offline Mode
1. Start Flutter app while backend is running
2. Play single player game
3. ✅ Board loads from API
4. Stop Docker services: `docker compose down`
5. Start new game
6. ✅ Should fallback to random board generation
7. ✅ Game should still be playable

## 8. Checklist Summary

### Backend ✅
- [ ] Server starts without errors
- [ ] MongoDB connection successful
- [ ] Seed script runs successfully
- [ ] All API endpoints respond correctly
- [ ] JWT authentication works
- [ ] Admin endpoints require admin role

### Admin Dashboard ✅
- [ ] Dashboard loads at port 8080
- [ ] Admin login works
- [ ] Overview statistics display correctly
- [ ] User management works
- [ ] Quiz CRUD operations work
- [ ] Game history displays
- [ ] Leaderboard displays and sorts correctly

### Flutter App ✅
- [ ] App launches without errors
- [ ] Authentication flow works (register/login/skip)
- [ ] Board loads from backend
- [ ] Single player game works fully
- [ ] Multiplayer game works fully
- [ ] Game history saves for logged-in users
- [ ] UI is responsive and smooth
- [ ] Timer works correctly
- [ ] Quiz dialogs work
- [ ] Win/lose dialogs work

### Integration ✅
- [ ] Flutter connects to backend API
- [ ] WebSocket connection works
- [ ] Game data persists to database
- [ ] Admin dashboard shows app data
- [ ] Leaderboard updates with new games

## 9. Common Issues & Solutions

### Issue: "Connection refused" from Flutter app
**Solution:** Check API URL in `api_service.dart`:
- Android Emulator: `http://10.0.2.2:3000/api`
- iOS Simulator: `http://localhost:3000/api`
- Real Device: `http://<YOUR_IP>:3000/api`

### Issue: Board config not loading
**Solution:** 
1. Check server logs: `docker compose logs socket-server`
2. Verify seed script ran: `docker compose exec socket-server node seed.js`
3. Check database: Connect to MongoDB and verify boardconfigs collection

### Issue: Admin dashboard can't connect to API
**Solution:** Check nginx.conf proxy settings and restart container:
```bash
docker compose restart admin-dashboard
```

### Issue: Multiplayer not working
**Solution:** 
1. Check WebSocket connection in browser console
2. Verify both players are on same network
3. Check firewall settings (port 3000 should be open)

### Issue: Game history not saving
**Solution:**
1. Verify user is logged in (not guest)
2. Check browser/app storage for JWT token
3. Verify API endpoint: `POST /api/game/history` with auth header

## 10. Logs & Debugging

### View all service logs:
```bash
docker compose logs -f
```

### View specific service logs:
```bash
docker compose logs -f socket-server
docker compose logs -f mongodb
docker compose logs -f admin-dashboard
```

### Flutter logs:
```bash
flutter logs
```

### Check MongoDB directly:
```bash
docker compose exec mongodb mongosh -u admin -p ulartangga123 --authenticationDatabase admin
```

---

## Test Results Template

Copy this template and fill in your test results:

```
## Test Results - [Date]

### Backend API
- [ ] ✅/❌ Server health check
- [ ] ✅/❌ User registration
- [ ] ✅/❌ User login
- [ ] ✅/❌ Board config retrieval
- [ ] ✅/❌ Quiz retrieval
- [ ] ✅/❌ Game history save
- [ ] ✅/❌ Leaderboard retrieval

### Admin Dashboard
- [ ] ✅/❌ Login successful
- [ ] ✅/❌ Overview statistics
- [ ] ✅/❌ User management
- [ ] ✅/❌ Quiz CRUD
- [ ] ✅/❌ Game history view
- [ ] ✅/❌ Leaderboard view

### Flutter App
- [ ] ✅/❌ App launch
- [ ] ✅/❌ Registration flow
- [ ] ✅/❌ Login flow
- [ ] ✅/❌ Board loading
- [ ] ✅/❌ Single player gameplay
- [ ] ✅/❌ Multiplayer gameplay
- [ ] ✅/❌ Game history save
- [ ] ✅/❌ Quiz functionality
- [ ] ✅/❌ Win/lose conditions

### Notes:
[Add any issues, bugs, or observations here]
```
