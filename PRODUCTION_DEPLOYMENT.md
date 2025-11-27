# 🚀 Production Deployment Guide - VPS

## Persiapan Domain

### Subdomain yang Diperlukan

**Minimal 2 subdomain:**

1. **api.yourdomain.com** 
   - Untuk: Backend REST API + Socket.IO WebSocket
   - Port internal: 3000
   - Fungsi: Semua API calls dan multiplayer real-time

2. **admin.yourdomain.com**
   - Untuk: Admin Dashboard
   - Port internal: 8080
   - Fungsi: Manajemen konten (users, quizzes, board configs)

**Catatan Penting:**
- ❌ **TIDAK** perlu subdomain terpisah untuk Socket.IO
- ✅ Socket.IO sudah terintegrasi di backend API (port 3000)
- ✅ Socket.IO berjalan di `api.yourdomain.com` dengan path `/socket.io/`

### DNS Configuration

Tambahkan A Records di DNS provider Anda:

```
Type    Name     Value              TTL
A       api      YOUR_VPS_IP        300
A       admin    YOUR_VPS_IP        300
```

Contoh jika IP VPS: `203.0.113.50`
```
api.yourdomain.com   → 203.0.113.50
admin.yourdomain.com → 203.0.113.50
```

---

## Setup VPS

### 1. Prerequisites

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker & Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install docker-compose-plugin -y

# Install Nginx
sudo apt install nginx -y

# Install Certbot (for SSL)
sudo apt install certbot python3-certbot-nginx -y
```

### 2. Clone Project

```bash
# Clone repository
cd /opt
sudo git clone <your-repository-url> ular_tangga
cd ular_tangga

# Set permissions
sudo chown -R $USER:$USER /opt/ular_tangga
```

### 3. Configure Environment

```bash
# Copy environment template
cp server/.env.example server/.env

# Edit environment file
nano server/.env
```

**Important settings in `.env`:**

```env
# PRODUCTION MODE
NODE_ENV=production

# Server
PORT=3000

# Database (internal docker network)
MONGODB_URI=mongodb://admin:ulartangga123@mongodb:27017/ular_tangga?authSource=admin

# Security - CHANGE THESE!
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
JWT_EXPIRES_IN=30d

# CORS - Set to your domains
CORS_ORIGIN=https://api.yourdomain.com,https://admin.yourdomain.com

# Socket.IO CORS
SOCKET_CORS_ORIGIN=https://api.yourdomain.com
```

### 4. Configure Docker Compose for Production

Edit `docker-compose.yml`:

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: ular_tangga_mongo
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ulartangga123
    volumes:
      - mongodb_data:/data/db
    networks:
      - ular_tangga_network
    # Remove port exposure for security
    # ports:
    #   - "27017:27017"

  socket-server:
    build: ./server
    container_name: ular_tangga_backend
    restart: unless-stopped
    env_file: ./server/.env
    depends_on:
      - mongodb
    # Only expose internally
    expose:
      - "3000"
    networks:
      - ular_tangga_network
    # For Nginx to access
    ports:
      - "127.0.0.1:3000:3000"

  admin-dashboard:
    build: ./admin-dashboard
    container_name: ular_tangga_admin
    restart: unless-stopped
    expose:
      - "80"
    networks:
      - ular_tangga_network
    # For Nginx to access
    ports:
      - "127.0.0.1:8080:80"

volumes:
  mongodb_data:

networks:
  ular_tangga_network:
    driver: bridge
```

### 5. Setup Nginx

```bash
# Copy nginx config
sudo cp nginx-production.conf /etc/nginx/sites-available/ular-tangga

# Edit with your domain
sudo nano /etc/nginx/sites-available/ular-tangga
# Replace 'yourdomain.com' with your actual domain

# Enable site
sudo ln -s /etc/nginx/sites-available/ular-tangga /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### 6. Setup SSL Certificate (HTTPS)

```bash
# Get SSL certificates for both subdomains
sudo certbot --nginx -d api.yourdomain.com -d admin.yourdomain.com

# Auto-renewal test
sudo certbot renew --dry-run
```

Certbot akan otomatis:
- Generate SSL certificates
- Update Nginx config
- Setup auto-renewal

### 7. Start Application

```bash
cd /opt/ular_tangga

# Start all services
docker compose up -d --build

# Wait for MongoDB to be ready (15 seconds)
sleep 15

# Seed database
docker compose exec -T socket-server node seed.js

# Check status
docker compose ps
```

### 8. Verify Deployment

```bash
# Check backend API
curl https://api.yourdomain.com/health

# Check admin dashboard
curl https://admin.yourdomain.com

# Check Docker logs
docker compose logs -f socket-server

# Check Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## Update Flutter App Configuration

### Update API Base URL

Edit `lib/services/api_service.dart`:

```dart
class ApiService {
  // Production URL
  static const String baseUrl = 'https://api.yourdomain.com/api';
  
  // ... rest of code
}
```

### Update Socket.IO URL

Edit `lib/main.dart` di `MultiplayerLobbyScreen`:

```dart
// Default server URL for production
String _serverUrl = 'https://api.yourdomain.com';
```

### Rebuild Flutter App

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release

# For Web
flutter build web --release
```

---

## Firewall Configuration

```bash
# Allow HTTP & HTTPS
sudo ufw allow 'Nginx Full'

# Allow SSH (if not already)
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

**Ports yang HARUS terbuka:**
- ✅ 80 (HTTP) - akan redirect ke HTTPS
- ✅ 443 (HTTPS) - untuk semua traffic
- ✅ 22 (SSH) - untuk remote access

**Ports yang TIDAK perlu dibuka:**
- ❌ 3000 (Backend) - hanya internal via Nginx
- ❌ 8080 (Admin) - hanya internal via Nginx
- ❌ 27017 (MongoDB) - hanya internal Docker network

---

## Monitoring & Maintenance

### Check Application Status

```bash
# Docker containers
docker compose ps
docker compose logs -f

# Nginx status
sudo systemctl status nginx

# Disk usage
df -h

# Check SSL certificate expiry
sudo certbot certificates
```

### Backup Database

```bash
# Backup MongoDB
docker compose exec mongodb mongodump \
  -u admin -p ulartangga123 \
  --authenticationDatabase admin \
  -d ular_tangga \
  -o /backup

# Copy backup to host
docker compose cp mongodb:/backup ./mongodb-backup-$(date +%Y%m%d)

# Compress backup
tar -czf mongodb-backup-$(date +%Y%m%d).tar.gz mongodb-backup-$(date +%Y%m%d)
```

### Restore Database

```bash
# Upload backup to server
scp mongodb-backup.tar.gz user@vps:/opt/ular_tangga/

# Extract
tar -xzf mongodb-backup.tar.gz

# Restore
docker compose exec -T mongodb mongorestore \
  -u admin -p ulartangga123 \
  --authenticationDatabase admin \
  -d ular_tangga \
  /backup/ular_tangga
```

### Update Application

```bash
cd /opt/ular_tangga

# Pull latest code
git pull

# Rebuild and restart
docker compose down
docker compose up -d --build

# Check logs
docker compose logs -f
```

---

## Troubleshooting

### Issue: API tidak bisa diakses

```bash
# Check Nginx config
sudo nginx -t

# Check Nginx error log
sudo tail -f /var/log/nginx/error.log

# Check backend logs
docker compose logs socket-server

# Restart Nginx
sudo systemctl restart nginx
```

### Issue: Socket.IO connection failed

**Kemungkinan penyebab:**
1. CORS settings salah di `.env`
2. Nginx tidak configure WebSocket dengan benar

**Solusi:**
```bash
# Pastikan di server/.env
SOCKET_CORS_ORIGIN=https://api.yourdomain.com

# Pastikan di Nginx config ada:
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

### Issue: SSL certificate error

```bash
# Renew certificate manually
sudo certbot renew

# Force renew
sudo certbot renew --force-renewal

# Check certificate
sudo certbot certificates
```

### Issue: MongoDB connection failed

```bash
# Check MongoDB logs
docker compose logs mongodb

# Check MongoDB is running
docker compose ps mongodb

# Test connection
docker compose exec mongodb mongosh \
  -u admin -p ulartangga123 \
  --authenticationDatabase admin
```

---

## Security Checklist

- [ ] Change `JWT_SECRET` in `.env`
- [ ] Change default admin password after first login
- [ ] Enable UFW firewall
- [ ] Setup SSL certificates (HTTPS)
- [ ] Configure proper CORS origins
- [ ] MongoDB only accessible from Docker network
- [ ] Regular backups scheduled
- [ ] Keep system packages updated
- [ ] Monitor logs regularly
- [ ] Setup fail2ban for SSH protection (optional)

---

## Performance Optimization

### Enable Nginx Caching

Add to Nginx config:

```nginx
# Cache static assets
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Enable Gzip Compression

Add to `/etc/nginx/nginx.conf`:

```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript 
           application/json application/javascript application/xml+rss;
```

### MongoDB Indexes

```bash
# Connect to MongoDB
docker compose exec mongodb mongosh \
  -u admin -p ulartangga123 \
  --authenticationDatabase admin \
  ular_tangga

# Create indexes
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ username: 1 }, { unique: true });
db.gamehistories.createIndex({ userId: 1, createdAt: -1 });
db.boardconfigs.createIndex({ level: 1 }, { unique: true });
```

---

## Cost Estimation

**VPS Requirements:**
- **Minimal**: 1 vCPU, 2GB RAM, 20GB SSD (~$5-10/month)
- **Recommended**: 2 vCPU, 4GB RAM, 40GB SSD (~$12-20/month)

**Domain:**
- ~$10-15/year

**SSL Certificate:**
- FREE (Let's Encrypt)

**Total:** ~$70-250/year

**VPS Providers:**
- DigitalOcean (Droplet)
- Vultr
- Linode
- AWS Lightsail
- Google Cloud (e2-small)
- Hetzner Cloud

---

## Quick Commands Reference

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart backend only
docker compose restart socket-server

# Backup database
docker compose exec mongodb mongodump -u admin -p ulartangga123 --authenticationDatabase admin -d ular_tangga -o /backup

# Check SSL expiry
sudo certbot certificates

# Renew SSL
sudo certbot renew

# Update app
git pull && docker compose up -d --build
```

---

## Summary

**Domain Setup:**
```
api.yourdomain.com    → Backend API + Socket.IO (port 3000)
admin.yourdomain.com  → Admin Dashboard (port 8080)
```

**Why no separate socket subdomain?**
- Socket.IO is part of the backend server
- Uses same port (3000) as REST API
- WebSocket connections go to same domain as API
- Nginx handles WebSocket upgrade automatically

**Architecture:**
```
User/Flutter App
      ↓ HTTPS
api.yourdomain.com (Nginx)
      ↓ HTTP
localhost:3000 (Backend + Socket.IO)
      ↓
MongoDB (Docker internal)
```

**Next Steps:**
1. Setup DNS records
2. Configure VPS
3. Run deployment
4. Update Flutter app URLs
5. Test everything!
