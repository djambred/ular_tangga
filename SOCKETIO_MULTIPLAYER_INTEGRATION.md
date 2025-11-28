# Socket.IO Multiplayer Integration

## Overview
The `MultiplayerGameScreen` now supports both **static 4-player educational mode** and **real-time socket.io multiplayer**.

## Integration Details

### 1. MultiplayerGameScreen Updates
**File**: `lib/screens/multiplayer_game_screen.dart`

**New Parameters**:
- `roomData` - Socket.io room data containing players, game state
- `isSocketBased` - Boolean flag to enable socket.io mode (default: false)

**Key Features**:
- Dual mode support (static vs. real-time)
- Socket service integration for multiplayer events
- Turn-based gameplay with server synchronization
- Real-time dice rolls from server
- Player position synchronization
- Quiz completion tracking across players
- Game end detection and winner announcement

### 2. Socket Event Handlers

**Listening Events**:
- `dice_rolled` - Server sends dice result to all players
- `player_moved` - Player position update from server
- `turn_changed` - Next player's turn notification
- `quiz_update` - Quiz completion status
- `game_ended` - Winner announcement
- `player_left` - Player disconnect notification
- `error` - Error messages from server

**Emitting Events**:
- `roll_dice` - Request to roll dice (only on player's turn)
- `move_player` - Player movement update
- `quiz_completed` - Quiz completion notification
- `leave_room` - Exit game

### 3. Multiplayer Flow

```
Lobby Screen (create/join room)
    ↓
Waiting Room (ready up, host starts)
    ↓
MultiplayerGameScreen (isSocketBased: true)
    ↓ (on game end)
Results/Navigate back
```

### 4. Static Educational Mode Flow

```
Level Selection Screen
    ↓ (Multiplayer button - login required)
MultiplayerGameScreen (isSocketBased: false)
    ↓
Static 4-player turn-based local game
```

## Server Events Expected

The backend should implement these socket.io events:

### Client → Server
```javascript
// Roll dice
socket.emit('roll_dice');

// Move player
socket.emit('move_player', { position: number });

// Quiz completed
socket.emit('quiz_completed', { quizPosition: number });

// Leave room
socket.emit('leave_room');
```

### Server → Client
```javascript
// Dice rolled result
socket.emit('dice_rolled', { dice: number, playerIndex: number });

// Player moved
socket.emit('player_moved', { playerIndex: number, position: number });

// Turn changed
socket.emit('turn_changed', { currentPlayerIndex: number });

// Quiz update
socket.emit('quiz_update', { quizPosition: number });

// Game ended
socket.emit('game_ended', { winnerIndex: number });

// Player left
socket.emit('player_left', { playerName: string });

// Error
socket.emit('error', { message: string });
```

## Usage Examples

### Static Mode (Educational)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MultiplayerGameScreen(
      requiredQuizzes: 5,
      level: 1,
      isSocketBased: false,
    ),
  ),
);
```

### Socket.io Mode (Real-time)
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => MultiplayerGameScreen(
      requiredQuizzes: widget.selectedLevel,
      level: widget.selectedLevel,
      roomData: socketRoomData,
      isSocketBased: true,
    ),
  ),
);
```

## Turn Management

In socket mode:
- Only the current player can roll the dice
- Turn validation happens on server-side
- Client shows "Bukan giliran Anda!" if attempting to roll on wrong turn
- Turn indicator updated via `turn_changed` event

## Testing

1. **Static Mode**: Test from Level Selection → Multiplayer button
2. **Socket Mode**: Test from Home → Multiplayer → Create/Join room → Start game
3. **Verify**:
   - Dice rolls synchronized
   - Player movements visible to all
   - Turn rotation works correctly
   - Quiz completions shared
   - Winner announced properly

## Backend Requirements

Ensure the backend supports:
- Room creation and joining
- Turn management
- Dice roll randomization on server
- Position validation
- Quiz tracking per room
- Win condition detection
- Player disconnect handling

## Future Enhancements

- [ ] Add chat functionality during game
- [ ] Implement reconnection logic
- [ ] Add spectator mode
- [ ] Support variable player counts (2-4)
- [ ] Add game replay/history
- [ ] Implement matchmaking system
