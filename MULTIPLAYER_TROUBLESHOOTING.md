# 🎮 Multiplayer Troubleshooting Guide

## Masalah Umum dan Solusi

### 1. "Gagal terhubung ke server"

#### Cek 1: Pastikan Docker Server Berjalan
```bash
# Check status semua container
docker compose ps

# Jika tidak ada container yang running, start:
docker compose up -d

# Check logs untuk error
docker compose logs socket-server
```

**Expected output `docker compose ps`:**
```
NAME                   STATUS    PORTS
ular-tangga-mongodb    Up        0.0.0.0:27017->27017/tcp
ular-tangga-server     Up        0.0.0.0:3000->3000/tcp
ular-tangga-admin      Up        0.0.0.0:8080->80/tcp
```

#### Cek 2: Test Backend API
```bash
# Test health endpoint
curl http://localhost:3000/health

# Expected response:
# {"status":"OK","message":"Server is running","timestamp":"..."}
```

#### Cek 3: Gunakan URL yang Benar

**Android Emulator:**
```
http://10.0.2.2:3000
```
> Catatan: `10.0.2.2` adalah special IP untuk mengakses `localhost` host machine dari Android Emulator

**iOS Simulator:**
```
http://localhost:3000
```

**Device Fisik (via WiFi):**
```
http://192.168.x.x:3000
```
> Ganti `192.168.x.x` dengan IP komputer Anda

**Cara cek IP komputer:**
```bash
# Linux/Mac
ifconfig | grep "inet "
hostname -I

# Windows
ipconfig
```

#### Cek 4: Firewall/Antivirus
Pastikan port 3000 tidak diblokir:

**Linux:**
```bash
sudo ufw allow 3000
sudo firewall-cmd --add-port=3000/tcp --permanent
```

**Mac:**
System Preferences → Security & Privacy → Firewall → Allow incoming connections

**Windows:**
Windows Defender Firewall → Allow app through firewall → Add port 3000

---

### 2. Koneksi Terputus Saat Bermain

#### Solusi:
1. **Periksa koneksi WiFi/Internet**
   - Pastikan device terhubung ke jaringan yang sama dengan server

2. **Restart Socket.IO connection**
   - Di Flutter app, tekan tombol Settings (⚙️)
   - Klik "Reconnect" atau tutup dan buka ulang lobby

3. **Check server logs**
   ```bash
   docker compose logs -f socket-server
   ```
   Look for disconnection messages or errors

---

### 3. Room Code Tidak Valid

#### Penyebab:
- Room sudah penuh (max 4 players)
- Room sudah dimulai atau selesai
- Typo pada room code

#### Solusi:
1. Minta host membuat room baru
2. Pastikan room code benar (case-sensitive)
3. Cek di server logs:
   ```bash
   docker compose logs socket-server | grep "Room"
   ```

---

### 4. Player Tidak Muncul di Lobby

#### Debug Steps:
1. **Check connection status**
   - Lihat indikator "Terhubung ke server" (hijau) di app

2. **Restart app**
   - Close dan reopen Flutter app
   - Server akan cleanup stale connections

3. **Check server active rooms**
   ```bash
   # Connect to MongoDB
   docker compose exec mongodb mongosh -u admin -p ulartangga123 --authenticationDatabase admin
   
   # No persistent room storage, rooms are in-memory
   # Check server logs instead:
   docker compose logs socket-server | grep "Player connected"
   ```

---

### 5. Game Tidak Dimulai Setelah Semua Ready

#### Checklist:
- [ ] Semua player sudah klik "SIAP" (ready)
- [ ] Host sudah klik "MULAI PERMAINAN"
- [ ] Minimum 2 players dalam room

#### Debug:
```bash
# Check Socket.IO events in server logs
docker compose logs -f socket-server

# Look for: "start_game" event
```

---

### 6. Lag/Delay Saat Bermain

#### Penyebab:
- Koneksi internet lambat
- Server overload
- Terlalu banyak players (>4)

#### Optimasi:
1. **Gunakan koneksi WiFi stabil** (bukan cellular data)
2. **Pastikan server tidak overload:**
   ```bash
   docker stats ular-tangga-server
   ```
3. **Restart containers:**
   ```bash
   docker compose restart
   ```

---

### 7. Error "Transport Error"

#### Penyebab:
WebSocket connection gagal, fallback ke polling gagal juga

#### Solusi:
1. **Update Socket.IO configuration** (sudah auto handle di code)
2. **Check nginx/proxy settings** jika menggunakan reverse proxy
3. **Gunakan HTTP bukan HTTPS** untuk development

---

## Testing Koneksi Manual

### Test 1: Ping Server
```bash
ping <SERVER_IP>
```

### Test 2: Test Port
```bash
# Linux/Mac
nc -zv <SERVER_IP> 3000

# Windows (PowerShell)
Test-NetConnection -ComputerName <SERVER_IP> -Port 3000
```

### Test 3: Test Socket.IO Endpoint
```bash
curl http://<SERVER_IP>:3000/socket.io/?transport=polling
```

Expected: Binary data response (berarti Socket.IO server running)

---

## Debug Mode di Flutter

### Enable Verbose Logging:

Edit `lib/services/socket_service.dart`, tambahkan:
```dart
_socket = IO.io(serverUrl, IO.OptionBuilder()
  .enableForceNew()
  .setTransports(['websocket', 'polling'])
  .enableReconnection()
  .build()
);

// Add this for debug
_socket!.on('*', (data) {
  print('🔍 Socket.IO event: $data');
});
```

Run dengan logs:
```bash
flutter run -v
```

---

## Network Configuration

### Allowed Ports
- **3000**: Backend API + Socket.IO
- **27017**: MongoDB (optional, hanya untuk akses database langsung)
- **8080**: Admin Dashboard (optional)

### CORS Configuration
Server sudah di-set dengan `CORS: *` untuk allow all origins.

Check di `server/.env`:
```env
CORS_ORIGIN=*
SOCKET_CORS_ORIGIN=*
```

---

## Quick Fix Checklist

Jika multiplayer tidak berfungsi, coba langkah ini secara berurutan:

1. [ ] `docker compose ps` - Pastikan server running
2. [ ] `docker compose logs socket-server` - Cek error di logs
3. [ ] `curl http://localhost:3000/health` - Test API endpoint
4. [ ] Gunakan URL yang benar sesuai platform (emulator/simulator/device)
5. [ ] Tekan ⚙️ di app → Ubah Server URL → Reconnect
6. [ ] Restart Flutter app
7. [ ] `docker compose restart socket-server`
8. [ ] Check firewall/antivirus settings
9. [ ] Pastikan di jaringan WiFi yang sama (untuk device fisik)
10. [ ] `docker compose down && docker compose up -d` (nuclear option)

---

## Logging untuk Bug Report

Jika masih ada masalah, kumpulkan logs ini:

```bash
# Server logs
docker compose logs socket-server > server-logs.txt

# App logs
flutter logs > flutter-logs.txt

# Network test
ping <SERVER_IP> > network-test.txt
curl -v http://<SERVER_IP>:3000/health >> network-test.txt
```

---

## Common Error Messages

### "Connection timeout"
→ Server tidak bisa diakses. Cek firewall dan IP address.

### "Connection refused"
→ Server tidak running. Jalankan `docker compose up -d`.

### "Transport error"
→ WebSocket blocked. Cek proxy/VPN settings.

### "Room not found"
→ Room code salah atau room sudah selesai.

### "Room is full"
→ Room sudah 4 players. Buat room baru.

---

## Contact Support

Jika semua solusi di atas tidak berhasil:

1. Check GitHub Issues: [Repository URL]
2. Buat issue baru dengan:
   - Platform (Android/iOS/Web)
   - Server logs
   - Flutter logs
   - Network configuration
   - Steps to reproduce

---

**Last Updated:** November 27, 2025  
**Version:** 1.0.0
