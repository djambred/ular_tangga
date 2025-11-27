# Ular Tangga Multiplayer Server

Server WebSocket untuk game Ular Tangga multiplayer menggunakan Node.js dan Socket.IO.

## Prerequisites

- Docker
- Docker Compose

## Cara Menjalankan Server

### 1. Build dan Start dengan Docker Compose

```bash
docker compose up --build
```

Server akan berjalan di `http://localhost:3000`

### 2. Jalankan di Background

```bash
docker compose up -d
```

### 3. Stop Server

```bash
docker compose down
```

### 4. Lihat Logs

```bash
docker compose logs -f socket-server
```

## Alternatif: Jalankan Tanpa Docker

Jika ingin menjalankan tanpa Docker:

```bash
cd server
npm install
npm start
```

Atau untuk development dengan auto-reload:

```bash
npm run dev
```

## Konfigurasi Client (Flutter)

Di file `lib/main.dart`, update URL server pada `MultiplayerLobbyScreen`:

```dart
String _serverUrl = 'http://YOUR_IP_ADDRESS:3000';
```

**Untuk testing lokal:**
- Android Emulator: `http://10.0.2.2:3000`
- iOS Simulator: `http://localhost:3000`
- Physical Device: `http://YOUR_COMPUTER_IP:3000` (contoh: `http://192.168.1.100:3000`)

## API Events

### Client -> Server

- `create_room` - Buat ruangan baru
- `join_room` - Gabung ke ruangan
- `player_ready` - Toggle status siap
- `start_game` - Mulai game (host only)
- `roll_dice` - Lempar dadu
- `move_player` - Pindahkan pemain
- `quiz_completed` - Selesai menjawab quiz
- `next_turn` - Giliran berikutnya
- `player_won` - Pemain menang
- `leave_room` - Keluar dari ruangan

### Server -> Client

- `room_created` - Ruangan berhasil dibuat
- `player_joined` - Pemain bergabung
- `room_updated` - Update status ruangan
- `game_started` - Game dimulai
- `dice_rolled` - Hasil lemparan dadu
- `player_moved` - Pemain berpindah
- `quiz_update` - Update quiz yang diselesaikan
- `turn_changed` - Giliran berubah
- `game_ended` - Game selesai
- `player_left` - Pemain keluar
- `error` - Error message

## Port Configuration

Default port: `3000`

Untuk mengubah port, edit `docker compose.yml`:

```yaml
ports:
  - "8080:3000"  # HOST:CONTAINER
```

Dan update di server `index.js` jika perlu.
