# API Documentation - Ular Tangga

## Base URL
- Production: `https://apiular.ueu-fasilkom.my.id/api`
- Development: `http://localhost:3000/api`

## Authentication
Most endpoints require JWT token in header:
```
Authorization: Bearer <token>
```

---

## 📚 Content Management Endpoints

### Get Content by Type (Public)
```http
GET /content/:type
```

**Parameters:**
- `type` (path): `snake_message`, `ladder_message`, or `fact`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "...",
      "type": "snake_message",
      "message": "Turun karena tidak memakai masker!",
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

### Get All Contents (Admin)
```http
GET /content
Authorization: Bearer <admin_token>
```

**Query Parameters:**
- `type` (optional): Filter by type
- `isActive` (optional): Filter by active status

### Create Content (Admin)
```http
POST /content
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "type": "snake_message",
  "message": "Tidak cuci tangan setelah batuk!",
  "isActive": true
}
```

### Update Content (Admin)
```http
PUT /content/:id
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "message": "Updated message",
  "isActive": false
}
```

### Delete Content (Admin)
```http
DELETE /content/:id
Authorization: Bearer <admin_token>
```

---

## ⚙️ Configuration Endpoints

### Get Public Configurations
```http
GET /config/public
```

**Response:**
```json
{
  "success": true,
  "data": {
    "api_base_url": "https://apiular.ueu-fasilkom.my.id",
    "enable_multiplayer": true,
    "max_board_size": 100,
    "quiz_time_limit": 30,
    "enable_sound": true
  }
}
```

### Get All Configurations (Admin)
```http
GET /config
Authorization: Bearer <admin_token>
```

**Query Parameters:**
- `category` (optional): Filter by category (api, game, feature, ui, other)
- `isPublic` (optional): Filter by public visibility

### Upsert Configuration (Admin)
```http
POST /config
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "key": "enable_multiplayer",
  "value": true,
  "description": "Enable/disable multiplayer mode",
  "category": "feature",
  "isPublic": true
}
```

### Delete Configuration (Admin)
```http
DELETE /config/:key
Authorization: Bearer <admin_token>
```

---

## 🎮 Game Endpoints

### Save Game History
```http
POST /game/history
Authorization: Bearer <token>
Content-Type: application/json

{
  "gameMode": "single",
  "level": 1,
  "duration": 300,
  "players": [
    {
      "userId": "user_id_here",
      "username": "player1",
      "position": 100,
      "isWinner": true,
      "quizzesAnswered": 10,
      "quizzesCorrect": 8,
      "playTime": 300
    }
  ]
}
```

### Get User Game History
```http
GET /game/history
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Number of results (default: 20)
- `page` (optional): Page number (default: 1)

### Get Leaderboard (Public)
```http
GET /game/leaderboard
```

**Query Parameters:**
- `sortBy` (optional): `wins`, `games`, or `quizzes` (default: wins)
- `limit` (optional): Number of results (default: 10)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "...",
      "username": "player1",
      "fullName": "John Doe",
      "avatar": "avatar1.png",
      "statistics": {
        "totalGames": 50,
        "totalWins": 35,
        "totalLosses": 15,
        "totalQuizzesAnswered": 200,
        "totalQuizzesCorrect": 160,
        "totalPlayTime": 15000,
        "highestLevel": 5
      }
    }
  ]
}
```

### Get Dashboard Statistics (NEW)
```http
GET /game/dashboard
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "username": "player1",
      "fullName": "John Doe",
      "avatar": "avatar1.png"
    },
    "statistics": {
      "totalGames": 50,
      "totalWins": 35,
      "totalLosses": 15,
      "totalQuizzesAnswered": 200,
      "totalQuizzesCorrect": 160,
      "totalPlayTime": 15000,
      "highestLevel": 5,
      "winRate": 70.0,
      "quizAccuracy": 80.0,
      "rank": 5
    },
    "recentGames": [
      {
        "gameMode": "single",
        "level": 3,
        "duration": 450,
        "createdAt": "2024-01-15T10:30:00.000Z",
        "isWinner": true
      }
    ]
  }
}
```

### Get Game Analytics (NEW)
```http
GET /game/analytics
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "gamesByLevel": [
      {
        "_id": 1,
        "totalGames": 20,
        "wins": 15
      },
      {
        "_id": 2,
        "totalGames": 15,
        "wins": 10
      }
    ],
    "gamesByMode": [
      {
        "_id": "single",
        "count": 30
      },
      {
        "_id": "multiplayer",
        "count": 20
      }
    ],
    "performanceOverTime": [
      {
        "_id": "2024-01-14",
        "games": 5,
        "wins": 3
      },
      {
        "_id": "2024-01-15",
        "games": 7,
        "wins": 5
      }
    ]
  }
}
```

---

## 👤 User/Auth Endpoints

### Register
```http
POST /auth/register
Content-Type: application/json

{
  "username": "player1",
  "email": "player1@example.com",
  "password": "password123",
  "fullName": "John Doe"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "_id": "...",
      "username": "player1",
      "email": "player1@example.com",
      "fullName": "John Doe",
      "role": "player",
      "avatar": "default.png",
      "statistics": {
        "totalGames": 0,
        "totalWins": 0,
        "totalLosses": 0,
        "totalQuizzesAnswered": 0,
        "totalQuizzesCorrect": 0,
        "totalPlayTime": 0,
        "highestLevel": 0
      }
    }
  }
}
```

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "username": "player1",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "_id": "...",
      "username": "player1",
      "fullName": "John Doe",
      "email": "player1@example.com",
      "role": "player",
      "avatar": "default.png",
      "statistics": {
        "totalGames": 50,
        "totalWins": 35,
        "totalLosses": 15,
        "totalQuizzesAnswered": 200,
        "totalQuizzesCorrect": 160,
        "totalPlayTime": 15000,
        "highestLevel": 5
      }
    }
  }
}
```

### Get Profile
```http
GET /auth/profile
Authorization: Bearer <token>
```

### Update Profile
```http
PUT /auth/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "fullName": "John Updated",
  "avatar": "new_avatar.png"
}
```

### Change Password
```http
PUT /auth/change-password
Authorization: Bearer <token>
Content-Type: application/json

{
  "currentPassword": "old_password",
  "newPassword": "new_password"
}
```

---

## 📊 Statistics Response Structure

### User Statistics Object
```json
{
  "totalGames": 50,           // Total games played
  "totalWins": 35,            // Total games won
  "totalLosses": 15,          // Total games lost
  "totalQuizzesAnswered": 200, // Total quiz questions answered
  "totalQuizzesCorrect": 160,  // Total quiz questions correct
  "totalPlayTime": 15000,      // Total playtime in seconds
  "highestLevel": 5            // Highest level reached
}
```

**Calculated Fields (Dashboard API):**
- `winRate`: `(totalWins / totalGames) * 100` (percentage)
- `quizAccuracy`: `(totalQuizzesCorrect / totalQuizzesAnswered) * 100` (percentage)
- `rank`: User's position in global leaderboard

---

## 🔒 Admin Endpoints

### Get All Users (Admin)
```http
GET /users
Authorization: Bearer <admin_token>
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Results per page (default: 20)
- `role` (optional): Filter by role (player, admin)
- `search` (optional): Search by username, email, or fullName

### Get User Statistics (Admin)
```http
GET /users/statistics
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total": 150,
    "players": 145,
    "admins": 5,
    "active": 140,
    "inactive": 10,
    "recentUsers": [...]
  }
}
```

### Get All Game History (Admin)
```http
GET /game/history/all
Authorization: Bearer <admin_token>
```

### Get Game Statistics (Admin)
```http
GET /game/statistics
Authorization: Bearer <admin_token>
```

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "success": false,
  "message": "Error message here"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

---

## Rate Limiting

Currently no rate limiting is implemented. Consider adding rate limiting for production use.

---

## WebSocket Events (Multiplayer)

Socket.IO connection endpoint: `wss://apiular.ueu-fasilkom.my.id`

### Events

**Client → Server:**
- `create_room` - Create new game room
- `join_room` - Join existing room
- `leave_room` - Leave current room
- `start_game` - Start game (host only)
- `player_move` - Send player movement
- `answer_quiz` - Submit quiz answer
- `game_over` - End game

**Server → Client:**
- `room_created` - Room created successfully
- `player_joined` - New player joined
- `player_left` - Player left room
- `game_started` - Game started
- `player_moved` - Player movement update
- `quiz_result` - Quiz answer result
- `game_ended` - Game ended
- `error` - Error occurred

---

## Flutter Integration Examples

### Initialize ApiService
```dart
final apiService = ApiService();

// Load configurations on app start
await apiService.applyConfigs();

// Check if user is logged in
bool isLoggedIn = await apiService.isLoggedIn();
```

### Login
```dart
try {
  final result = await apiService.login(
    username: 'player1',
    password: 'password123',
  );
  
  if (result['success']) {
    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
  }
} catch (e) {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString())),
  );
}
```

### Get Dashboard Stats
```dart
try {
  final result = await apiService.getDashboardStats();
  
  if (result['success']) {
    final stats = result['data']['statistics'];
    print('Total Wins: ${stats['totalWins']}');
    print('Win Rate: ${stats['winRate']}%');
    print('Rank: #${stats['rank']}');
  }
} catch (e) {
  print('Error: $e');
}
```

### Get Leaderboard
```dart
try {
  final result = await apiService.getLeaderboard(
    sortBy: 'wins',
    limit: 50,
  );
  
  if (result['success']) {
    List players = result['data'];
    // Display leaderboard
  }
} catch (e) {
  print('Error: $e');
}
```

### Load Content
```dart
final contentService = ContentService();

// Load all content types
await contentService.loadContent();

// Get snake messages
List<String> snakeMessages = contentService.snakeMessages;

// Get ladder messages
List<String> ladderMessages = contentService.ladderMessages;

// Get TBC facts
List<String> facts = contentService.facts;

// Refresh content (force reload from API)
await contentService.refreshContent();
```

---

## Testing with cURL

### Test public endpoints
```bash
# Get content
curl https://apiular.ueu-fasilkom.my.id/api/content/snake_message

# Get public configs
curl https://apiular.ueu-fasilkom.my.id/api/config/public

# Get leaderboard
curl "https://apiular.ueu-fasilkom.my.id/api/game/leaderboard?sortBy=wins&limit=10"
```

### Test authenticated endpoints
```bash
# Login first
TOKEN=$(curl -X POST https://apiular.ueu-fasilkom.my.id/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"player1","password":"password123"}' \
  | jq -r '.data.token')

# Get dashboard stats
curl https://apiular.ueu-fasilkom.my.id/api/game/dashboard \
  -H "Authorization: Bearer $TOKEN"

# Get analytics
curl https://apiular.ueu-fasilkom.my.id/api/game/analytics \
  -H "Authorization: Bearer $TOKEN"

# Get profile
curl https://apiular.ueu-fasilkom.my.id/api/auth/profile \
  -H "Authorization: Bearer $TOKEN"
```

---

## Notes

1. **Security**: All passwords are hashed using bcrypt
2. **JWT Expiration**: Tokens expire after 30 days (configurable in server config)
3. **CORS**: Enabled for all origins in production (consider restricting in production)
4. **HTTPS**: Production API uses SSL/TLS encryption
5. **Database**: MongoDB with indexes on frequently queried fields
6. **Caching**: Client-side caching (24 hours) for content and configs
7. **Guest Mode**: Users can play without authentication but with limited features

---

## Version History

- **v1.0** - Initial API release
- **v1.1** - Added content management endpoints
- **v1.2** - Added configuration management endpoints
- **v1.3** - Added dashboard and analytics endpoints (current)

---

**Last Updated:** January 2024
**Maintained by:** Development Team
