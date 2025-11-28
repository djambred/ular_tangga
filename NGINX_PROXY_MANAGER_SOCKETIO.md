# Socket.IO Configuration for Nginx Proxy Manager

## Current Setup
- Domain: `apiular.ueu-fasilkom.my.id`
- Forward to: `10.2.0.4:3000`
- WebSockets Support: ✅ Enabled (GOOD!)
- SSL: ✅ Force SSL enabled

## Problem
WebSockets toggle saja tidak cukup untuk Socket.IO. Perlu custom configuration khusus untuk path `/socket.io/`.

## Solution: Add Custom Nginx Configuration

### Step 1: Edit Proxy Host `apiular.ueu-fasilkom.my.id`

Di Nginx Proxy Manager:

1. Klik pada proxy host `apiular.ueu-fasilkom.my.id`
2. Pergi ke tab **"Advanced"**
3. Tambahkan konfigurasi berikut di **"Custom Nginx Configuration"** box:

```nginx
# Socket.IO specific configuration
location /socket.io/ {
    proxy_pass http://10.2.0.4:3000;
    proxy_http_version 1.1;
    
    # WebSocket upgrade headers
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    
    # Standard proxy headers
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    
    # Important: Timeouts for long-polling and WebSocket
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    
    # Disable buffering for real-time data
    proxy_buffering off;
    proxy_cache off;
    
    # Additional Socket.IO compatibility
    proxy_redirect off;
}
```

4. Klik **"Save"**

### Step 2: Verify Configuration

Test Socket.IO endpoints:

```bash
# Test REST API
curl https://apiular.ueu-fasilkom.my.id/health

# Test Socket.IO polling handshake
curl "https://apiular.ueu-fasilkom.my.id/socket.io/?EIO=4&transport=polling"

# Should return something like:
# 0{"sid":"xxxxx","upgrades":["websocket"],...}
```

### Alternative: Simpler Configuration (If Above Doesn't Work)

Jika konfigurasi di atas conflict, coba yang lebih sederhana:

```nginx
# Increase timeouts for Socket.IO
proxy_connect_timeout 300s;
proxy_send_timeout 300s;
proxy_read_timeout 300s;

# Disable buffering
proxy_buffering off;
proxy_cache off;

# Additional headers for Socket.IO
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port $server_port;
```

Pastikan **WebSockets Support toggle tetap ON** di tab Details.

## Why This Works

1. **WebSockets Support toggle**: Menambahkan headers `Upgrade` dan `Connection` untuk root path
2. **Custom location `/socket.io/`**: Memberikan konfigurasi khusus untuk path Socket.IO
3. **Timeouts**: Mencegah koneksi putus saat idle (polling/long-polling)
4. **No buffering**: Real-time data tidak di-buffer oleh nginx

## Testing After Configuration

### Test 1: Check Nginx Config Applied
```bash
# Check if proxy returns socket.io handshake
curl -v "https://apiular.ueu-fasilkom.my.id/socket.io/?EIO=4&transport=polling"
```

Expected: `200 OK` with session data

### Test 2: Try WebSocket Upgrade
```bash
curl -v -H "Upgrade: websocket" \
     -H "Connection: Upgrade" \
     -H "Sec-WebSocket-Version: 13" \
     -H "Sec-WebSocket-Key: test" \
     "https://apiular.ueu-fasilkom.my.id/socket.io/?EIO=4&transport=websocket"
```

Expected: `101 Switching Protocols` (bukan 400 Bad Request)

### Test 3: Flutter App Connection

1. Hot reload/restart Flutter app
2. Masuk ke Multiplayer Lobby
3. Klik Settings (⚙️)
4. Pilih preset "Production" 
5. Klik "Simpan & Hubungkan"
6. Status harus: ✅ "Terhubung ke server"

## Troubleshooting

### Issue: Still getting 400 Bad Request on WebSocket
**Solution**: Pastikan custom config di tab Advanced benar-benar tersave. Coba reload nginx proxy manager.

### Issue: Connection timeout
**Solution**: 
- Cek firewall di server: `sudo ufw status`
- Pastikan port 3000 accessible dari nginx container
- Test langsung: `curl http://10.2.0.4:3000/health`

### Issue: Config doesn't apply
**Solution**:
1. Simpan proxy host
2. Tunggu beberapa detik
3. Test lagi dengan curl
4. Atau restart nginx proxy manager container

### Issue: 502 Bad Gateway
**Solution**: Backend tidak running atau tidak reachable
```bash
# Check backend container
docker ps | grep ular-tangga-server

# Check if reachable from host
curl http://10.2.0.4:3000/health
```

## Expected Behavior After Fix

- ✅ REST API works: `/health`, `/api/*`
- ✅ Socket.IO polling works: Handshake successful
- ✅ Socket.IO WebSocket upgrade works: 101 Switching Protocols
- ✅ Flutter app connects to production
- ✅ Multiplayer room creation works
- ✅ Real-time updates work

## Notes

- **Polling mode sudah works** di current setup, jadi multiplayer tetap bisa jalan (sedikit lebih lambat)
- **WebSocket upgrade** akan membuat connection lebih efficient dan real-time
- Nginx Proxy Manager secara default sudah handle SSL termination dengan baik
- Custom location config tidak mengganggu route lain (REST API tetap works)

## Quick Reference

### Nginx Proxy Manager Structure
```
Proxy Host: apiular.ueu-fasilkom.my.id
├── Details Tab
│   ├── Scheme: http
│   ├── Forward Hostname/IP: 10.2.0.4
│   ├── Forward Port: 3000
│   └── ✅ WebSockets Support: ON
├── SSL Tab
│   └── ✅ Force SSL: ON
└── Advanced Tab
    └── Custom Nginx Configuration: [Socket.IO config]
```

### Backend Server Info
- Container IP: `10.2.0.4`
- Port: `3000`
- Socket.IO Path: `/socket.io/`
- Transports: `['polling', 'websocket']`

## Contact

Jika masih ada masalah setelah apply config:
1. Screenshot error di Flutter console
2. Check nginx access log di Nginx Proxy Manager
3. Check backend logs: `docker compose logs -f socket-server`
