# 🔧 Fix SSL untuk API Domain

## Masalah
- ✅ Admin: https://adminular.ueu-fasilkom.my.id/ - **BERFUNGSI**
- ❌ API: https://apiular.ueu-fasilkom.my.id/ - **ERROR: SSL tidak terdeteksi**

Error: `ERR_SSL_UNRECOGNIZED_NAME_ALERT (-159)`

---

## Solusi: Generate SSL Certificate untuk API

Login ke VPS Anda dan jalankan perintah berikut:

### 1. Cek Status Nginx Configuration

```bash
# Cek apakah apiular.ueu-fasilkom.my.id sudah ada di Nginx config
sudo nginx -T | grep apiular.ueu-fasilkom.my.id

# Cek file konfigurasi
sudo cat /etc/nginx/sites-available/ular-tangga
# atau
sudo cat /etc/nginx/conf.d/ular-tangga.conf
```

### 2. Pastikan Domain Sudah Terkonfigurasi di Nginx

File Nginx harus memiliki block untuk `apiular.ueu-fasilkom.my.id`:

```nginx
server {
    listen 80;
    server_name apiular.ueu-fasilkom.my.id;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Jika belum ada**, tambahkan dulu:

```bash
sudo nano /etc/nginx/sites-available/ular-tangga
```

Lalu reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Generate SSL Certificate dengan Certbot

```bash
# Generate SSL untuk domain API
sudo certbot --nginx -d apiular.ueu-fasilkom.my.id

# Ikuti prompt:
# - Masukkan email Anda
# - Setuju dengan Terms of Service
# - Pilih untuk redirect HTTP ke HTTPS (recommended)
```

**Certbot akan otomatis:**
- Generate SSL certificate dari Let's Encrypt
- Modifikasi Nginx config untuk enable HTTPS
- Setup auto-renewal

### 4. Verifikasi SSL Berhasil

```bash
# Cek certificate
sudo certbot certificates

# Test Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Cek status
sudo systemctl status nginx
```

### 5. Test API Endpoint

```bash
# Test HTTP (harus redirect ke HTTPS)
curl -I http://apiular.ueu-fasilkom.my.id/

# Test HTTPS
curl -I https://apiular.ueu-fasilkom.my.id/

# Test API endpoint
curl https://apiular.ueu-fasilkom.my.id/api/health
```

---

## Kemungkinan Masalah Lain

### A. Domain Belum Pointing ke VPS

```bash
# Cek DNS resolution
nslookup apiular.ueu-fasilkom.my.id
dig apiular.ueu-fasilkom.my.id

# Pastikan IP yang muncul adalah IP VPS Anda
```

Jika belum, tambahkan A Record di DNS:
```
Type: A
Name: apiular
Value: [IP_VPS_ANDA]
TTL: 300
```

### B. Firewall Blocking Port

```bash
# Cek firewall
sudo ufw status

# Pastikan port 80 dan 443 terbuka
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

### C. Backend Container Tidak Berjalan

```bash
# Cek status Docker containers
cd /opt/ular_tangga
docker compose ps

# Pastikan socket-server RUNNING
# Jika tidak, restart:
docker compose restart socket-server

# Cek logs
docker compose logs socket-server --tail=50
```

### D. Port 3000 Tidak Listening

```bash
# Cek port
sudo netstat -tulpn | grep :3000
# atau
sudo ss -tulpn | grep :3000

# Jika tidak ada, restart backend:
docker compose restart socket-server
```

---

## Quick Fix Command (All-in-One)

Jalankan ini di VPS untuk fix semua sekaligus:

```bash
# 1. Cek & restart backend
cd /opt/ular_tangga
docker compose restart socket-server

# 2. Generate SSL jika belum ada
sudo certbot --nginx -d apiular.ueu-fasilkom.my.id --non-interactive --agree-tos -m your@email.com

# 3. Reload Nginx
sudo nginx -t && sudo systemctl reload nginx

# 4. Test
curl -I https://apiular.ueu-fasilkom.my.id/
```

---

## Expected Result

Setelah berhasil:

```bash
$ curl -I https://apiular.ueu-fasilkom.my.id/
HTTP/2 200 
server: nginx
date: Thu, 28 Nov 2024 ...
content-type: text/html; charset=utf-8
```

Dan di browser:
- ✅ https://apiular.ueu-fasilkom.my.id/ → Shows API response (tidak error SSL)
- ✅ https://adminular.ueu-fasilkom.my.id/ → Admin dashboard works

---

## Auto-Renewal SSL

Certbot sudah setup auto-renewal. Cek dengan:

```bash
# Test renewal
sudo certbot renew --dry-run

# Cek cron job
sudo systemctl status certbot.timer
```

---

## Troubleshooting

### Error: "Challenge failed"

Berarti Certbot tidak bisa verify domain ownership.

**Fix:**
1. Pastikan Nginx sudah running: `sudo systemctl status nginx`
2. Pastikan domain pointing ke VPS: `dig apiular.ueu-fasilkom.my.id`
3. Pastikan port 80 terbuka: `sudo ufw status`
4. Test Nginx config: `sudo nginx -t`

### Error: "Too many certificates"

Let's Encrypt limit: 5 certificates per domain per week.

**Fix:**
Tunggu 1 minggu atau gunakan staging:
```bash
sudo certbot --nginx -d apiular.ueu-fasilkom.my.id --staging
```

### Error: "Connection refused"

Backend tidak berjalan.

**Fix:**
```bash
cd /opt/ular_tangga
docker compose ps
docker compose up -d socket-server
docker compose logs socket-server
```

---

## Kontak

Jika masih error, kirim output dari:

```bash
# 1. Nginx config
sudo nginx -T | grep -A 50 apiular

# 2. SSL certificates
sudo certbot certificates

# 3. Docker status
docker compose ps

# 4. Curl test
curl -v https://apiular.ueu-fasilkom.my.id/

# 5. DNS check
dig apiular.ueu-fasilkom.my.id
```
