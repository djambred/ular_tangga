require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const { v4: uuidv4 } = require('uuid');
const mongoose = require('mongoose');
const cors = require('cors');

// Import routes
const authRoutes = require('./routes/auth');
const quizRoutes = require('./routes/quiz');
const gameRoutes = require('./routes/game');
const userRoutes = require('./routes/user');
const boardRoutes = require('./routes/board');
const contentRoutes = require('./routes/content');
const configRoutes = require('./routes/config');

// Initialize Express
const app = express();
const server = http.createServer(app);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/ular_tangga', {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('✅ Connected to MongoDB'))
.catch(err => console.error('❌ MongoDB connection error:', err));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/quiz', quizRoutes);
app.use('/api/game', gameRoutes);
app.use('/api/users', userRoutes);
app.use('/api/board', boardRoutes);
app.use('/api/content', contentRoutes);
app.use('/api/config', configRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
    credentials: true
  },
  path: '/socket.io/',
  transports: ['websocket', 'polling'],
  allowEIO3: true,
  pingTimeout: 60000,
  pingInterval: 25000
});

// Store active rooms
const rooms = new Map();

// Store connected players
const players = new Map();

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🎮 Ular Tangga Server running on port ${PORT}`);
});

io.on("connection", (socket) => {
  console.log(`✅ Player connected: ${socket.id}`);

  // Create a new room
  socket.on("create_room", (data) => {
    const roomCode = generateRoomCode();
    const room = {
      code: roomCode,
      host: socket.id,
      players: [{
        id: socket.id,
        name: data.playerName,
        color: 'blue',
        position: 0,
        completedQuizzes: [],
        isReady: false
      }],
      level: data.level,
      maxPlayers: data.maxPlayers || 4,
      status: 'waiting', // waiting, playing, finished
      gameState: null
    };
    
    rooms.set(roomCode, room);
    socket.join(roomCode);
    players.set(socket.id, { roomCode, playerName: data.playerName });
    
    socket.emit("room_created", { roomCode, room });
    console.log(`🏠 Room created: ${roomCode} by ${data.playerName}`);
  });

  // Join existing room
  socket.on("join_room", (data) => {
    const { roomCode, playerName } = data;
    const room = rooms.get(roomCode);
    
    if (!room) {
      socket.emit("error", { message: "Room not found" });
      return;
    }
    
    if (room.status !== 'waiting') {
      socket.emit("error", { message: "Game already started" });
      return;
    }
    
    if (room.players.length >= room.maxPlayers) {
      socket.emit("error", { message: "Room is full" });
      return;
    }
    
    const colors = ['blue', 'red', 'green', 'yellow'];
    const usedColors = room.players.map(p => p.color);
    const availableColor = colors.find(c => !usedColors.includes(c));
    
    const player = {
      id: socket.id,
      name: playerName,
      color: availableColor,
      position: 0,
      completedQuizzes: [],
      isReady: false
    };
    
    room.players.push(player);
    socket.join(roomCode);
    players.set(socket.id, { roomCode, playerName });
    
    io.to(roomCode).emit("player_joined", { player, room });
    console.log(`👤 ${playerName} joined room ${roomCode}`);
  });

  // Player ready
  socket.on("player_ready", () => {
    const playerData = players.get(socket.id);
    if (!playerData) return;
    
    const room = rooms.get(playerData.roomCode);
    if (!room) return;
    
    const player = room.players.find(p => p.id === socket.id);
    if (player) {
      player.isReady = !player.isReady;
      io.to(playerData.roomCode).emit("room_updated", room);
    }
  });

  // Start game (host only)
  socket.on("start_game", () => {
    const playerData = players.get(socket.id);
    if (!playerData) return;
    
    const room = rooms.get(playerData.roomCode);
    if (!room || room.host !== socket.id) return;
    
    // Check if all players are ready
    const allReady = room.players.every(p => p.isReady || p.id === room.host);
    if (!allReady) {
      socket.emit("error", { message: "Not all players are ready" });
      return;
    }
    
    // Generate game state
    room.gameState = generateGameState(room.level);
    room.status = 'playing';
    room.currentTurn = room.players[0].id;
    
    io.to(playerData.roomCode).emit("game_started", { room });
    console.log(`🎮 Game started in room ${playerData.roomCode}`);
  });

  // Roll dice
  socket.on("roll_dice", () => {
    const playerData = players.get(socket.id);
    if (!playerData) return;
    
    const room = rooms.get(playerData.roomCode);
    if (!room || room.currentTurn !== socket.id) return;
    
    const diceValue = Math.floor(Math.random() * 3) + 4; // 4-6
    
    io.to(playerData.roomCode).emit("dice_rolled", {
      playerId: socket.id,
      diceValue
    });
  });

  // Move player
  socket.on("move_player", (data) => {
    const playerData = players.get(socket.id);
    if (!playerData) return;
    
    const room = rooms.get(playerData.roomCode);
    if (!room) return;
    
    const player = room.players.find(p => p.id === socket.id);
    if (player) {
      player.position = data.position;
      
      io.to(playerData.roomCode).emit("player_moved", {
        playerId: socket.id,
        position: data.position
      });
    }
  });

  // Quiz completed
  socket.on("quiz_completed", (data) => {
    const playerData = players.get(socket.id);
    if (!playerData) return;
    
    const room = rooms.get(playerData.roomCode);
    if (!room) return;
    
    const player = room.players.find(p => p.id === socket.id);
    if (player && !player.completedQuizzes.includes(data.quizPosition)) {
      player.completedQuizzes.push(data.quizPosition);
      
      io.to(playerData.roomCode).emit("quiz_update", {
        playerId: socket.id,
        completedQuizzes: player.completedQuizzes
      });
    }
  });

  // Next turn
  socket.on("next_turn", () => {
    const playerData = players.get(socket.id);
    if (!playerData) return;
    
    const room = rooms.get(playerData.roomCode);
    if (!room || room.currentTurn !== socket.id) return;
    
    const currentIndex = room.players.findIndex(p => p.id === socket.id);
    const nextIndex = (currentIndex + 1) % room.players.length;
    room.currentTurn = room.players[nextIndex].id;
    
    io.to(playerData.roomCode).emit("turn_changed", {
      currentTurn: room.currentTurn,
      playerName: room.players[nextIndex].name
    });
  });

  // Player wins
  socket.on("player_won", () => {
    const playerData = players.get(socket.id);
    if (!playerData) return;
    
    const room = rooms.get(playerData.roomCode);
    if (!room) return;
    
    room.status = 'finished';
    const player = room.players.find(p => p.id === socket.id);
    
    io.to(playerData.roomCode).emit("game_ended", {
      winner: player
    });
  });

  // Leave room
  socket.on("leave_room", () => {
    handlePlayerLeave(socket);
  });

  // Disconnect
  socket.on("disconnect", () => {
    console.log(`❌ Player disconnected: ${socket.id}`);
    handlePlayerLeave(socket);
  });
});

function handlePlayerLeave(socket) {
  const playerData = players.get(socket.id);
  if (!playerData) return;
  
  const room = rooms.get(playerData.roomCode);
  if (!room) return;
  
  room.players = room.players.filter(p => p.id !== socket.id);
  
  if (room.players.length === 0) {
    rooms.delete(playerData.roomCode);
    console.log(`🗑️  Room ${playerData.roomCode} deleted`);
  } else {
    // If host left, assign new host
    if (room.host === socket.id && room.players.length > 0) {
      room.host = room.players[0].id;
    }
    
    io.to(playerData.roomCode).emit("player_left", {
      playerId: socket.id,
      room
    });
  }
  
  players.delete(socket.id);
}

function generateRoomCode() {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
}

function generateGameState(level) {
  // This will match the client-side generation
  return {
    level,
    startTime: Date.now(),
    duration: 300 + Math.floor(Math.random() * 121) // 5-7 minutes
  };
}
