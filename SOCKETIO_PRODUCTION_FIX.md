# Socket.IO Production Connection Issue - Fix Guide

## Problem
- ✅ Local (localhost:3000) - Socket.IO works perfectly
- ❌ Production (https://apiular.ueu-fasilkom.my.id) - Socket.IO timeout
- ✅ REST API works on production (config fetch successful)
- ❌ WebSocket upgrade fails

## Root Causes

### 1. **Nginx WebSocket Configuration Missing**
Production server needs proper nginx config for WebSocket upgrade on `/socket.io/` path.

### 2. **Transport Order Issue with HTTPS**
Socket.IO client tries `polling` first for HTTPS, but server might not handle it properly.

### 3. **CORS and Path Configuration**
Production environment needs explicit path and CORS settings.

## Solutions Applied

### Backend Changes (server/index.js)
```javascript
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
```

**Why these changes:**
- `path: '/socket.io/'` - Explicit path for nginx routing
- `transports: ['websocket', 'polling']` - Prefer websocket first
- `allowEIO3: true` - Backward compatibility
- `pingTimeout/pingInterval` - Prevent premature disconnections

## Required Nginx Configuration

### For `apiular.ueu-fasilkom.my.id`

```nginx
server {
    listen 443 ssl http2;
    server_name apiular.ueu-fasilkom.my.id;

    # SSL certificates (make sure they exist)
    ssl_certificate /etc/letsencrypt/live/apiular.ueu-fasilkom.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/apiular.ueu-fasilkom.my.id/privkey.pem;

    # Critical: Socket.IO specific location
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # WebSocket upgrade headers (CRITICAL)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Standard headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts for long connections
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Disable buffering for real-time
        proxy_buffering off;
        proxy_cache off;
    }

    # REST API (other routes)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name apiular.ueu-fasilkom.my.id;
    return 301 https://$host$request_uri;
}
```

## Deployment Steps

### 1. Update Backend Code
```bash
cd /root/project/ular_tangga/server
# Code already updated
```

### 2. Rebuild Docker Image
```bash
cd /root/project/ular_tangga
docker compose build socket-server
docker compose up -d socket-server
```

### 3. Check Nginx on Production Server
```bash
# SSH to production server
ssh user@apiular.ueu-fasilkom.my.id

# Check current nginx config
sudo nano /etc/nginx/sites-available/apiular.conf

# Test nginx config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

### 4. Verify SSL Certificate
```bash
# Check certificate
sudo certbot certificates

# Renew if needed
sudo certbot renew --dry-run
```

### 5. Test Connection
```bash
# Test REST API
curl https://apiular.ueu-fasilkom.my.id/health

# Test Socket.IO handshake
curl -k -v https://apiular.ueu-fasilkom.my.id/socket.io/?EIO=4&transport=polling
```

## Debugging Commands

### Check if server is listening
```bash
netstat -tlnp | grep :3000
```

### Check nginx error logs
```bash
sudo tail -f /var/log/nginx/error.log
```

### Check backend logs
```bash
docker compose logs -f socket-server
```

### Test WebSocket upgrade
```bash
curl -i -N -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Version: 13" \
     -H "Sec-WebSocket-Key: test" \
     https://apiular.ueu-fasilkom.my.id/socket.io/
```

## Common Issues

### Issue 1: 502 Bad Gateway
**Cause:** Backend not running or nginx can't reach it
**Fix:**
```bash
docker compose ps  # Check if container running
docker compose up -d socket-server  # Restart if needed
```

### Issue 2: 400 Bad Request on WebSocket
**Cause:** Missing Upgrade headers in nginx
**Fix:** Add the WebSocket headers shown in nginx config above

### Issue 3: Connection timeout
**Cause:** Firewall blocking WebSocket
**Fix:**
```bash
# Check firewall
sudo ufw status
# Allow if needed
sudo ufw allow 443/tcp
```

### Issue 4: SSL Certificate Error
**Cause:** Certificate expired or not properly configured
**Fix:**
```bash
sudo certbot renew
sudo systemctl reload nginx
```

## Client-Side Workaround

If production still doesn't work, users can manually switch to localhost for development:

1. Click Settings (⚙️) in lobby screen
2. Select "Localhost" preset
3. Click "Simpan & Hubungkan"

## Verification Checklist

After applying fixes, verify:
- [ ] Backend container running: `docker compose ps`
- [ ] Nginx config valid: `sudo nginx -t`
- [ ] SSL certificate valid: `sudo certbot certificates`
- [ ] Port 443 open: `sudo netstat -tlnp | grep :443`
- [ ] REST API works: `curl https://apiular.ueu-fasilkom.my.id/health`
- [ ] Socket.IO handshake works: Test with curl command above
- [ ] Flutter app connects to production URL
- [ ] Can create room successfully
- [ ] Multiple clients can join same room

## Notes

- **Why local works:** No SSL, no nginx, direct connection to Node.js server
- **Why production fails:** HTTPS + nginx requires proper WebSocket configuration
- **Transport priority:** WebSocket is faster, polling is fallback
- **Path importance:** `/socket.io/` must be explicitly routed by nginx

## Contact

If issues persist after applying all fixes, check:
1. Server logs: `docker compose logs socket-server`
2. Nginx logs: `sudo tail -f /var/log/nginx/error.log`
3. Client logs: Flutter console output
4. Network tab in browser DevTools (for web testing)
