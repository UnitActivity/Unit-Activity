# Panduan Deploy Backend ke Vercel

Panduan lengkap untuk mendeploy backend Node.js (Email Service) Unit Activity ke Vercel.

## Prasyarat

1. **Akun Vercel**
   - Daftar di [vercel.com](https://vercel.com) (gratis)
   - Login menggunakan GitHub, GitLab, atau Bitbucket

2. **Git Repository**
   - Push kode backend ke GitHub/GitLab/Bitbucket
   - Atau siapkan untuk upload manual

3. **Environment Variables**
   - Siapkan semua credential (Supabase, Email SMTP, dll)

## Langkah 1: Persiapan Kode Backend

### 1.1 Buat file `vercel.json` di folder `backend/`

Buat file baru `backend/vercel.json` dengan isi:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/server.js"
    }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
```

### 1.2 Update `package.json`

Pastikan `backend/package.json` sudah memiliki:

```json
{
  "name": "unit-activity-email-service",
  "version": "1.0.0",
  "description": "Email service backend for Unit Activity app using Nodemailer",
  "main": "server.js",
  "engines": {
    "node": "24.x"
  },
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.84.0",
    "bcrypt": "^6.0.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "nodemailer": "^6.9.7"
  }
}
```

**Catatan**: Bagian `engines` penting untuk menentukan versi Node.js yang digunakan Vercel.

### 1.3 Modifikasi `server.js` (Optional - untuk export handler)

Tambahkan di akhir file `server.js`:

```javascript
// Export untuk Vercel serverless
module.exports = app;
```

## Langkah 2: Deploy ke Vercel

### Opsi A: Deploy via GitHub (Recommended)

1. **Push kode ke GitHub**
   ```bash
   cd backend
   git init
   git add .
   git commit -m "Initial commit for backend"
   git branch -M main
   git remote add origin https://github.com/username/unit-activity-backend.git
   git push -u origin main
   ```

2. **Import Project ke Vercel**
   - Login ke [vercel.com](https://vercel.com)
   - Klik "Add New" → "Project"
   - Import repository GitHub yang baru dibuat
   - Pilih framework preset: **Other**
   - Root Directory: `backend` (jika mono-repo) atau `.` (jika backend sendiri)
   - Klik "Deploy"

### Opsi B: Deploy via Vercel CLI

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Login ke Vercel**
   ```bash
   vercel login
   ```

3. **Deploy dari folder backend**
   ```bash
   cd backend
   vercel
   ```

4. **Ikuti prompt**
   - Set up and deploy? → **Y**
   - Which scope? → Pilih akun Anda
   - Link to existing project? → **N**
   - Project name? → `unit-activity-backend`
   - In which directory? → `./` (karena sudah di folder backend)
   - Override settings? → **N**

5. **Deploy ke production**
   ```bash
   vercel --prod
   ```

### Opsi C: Deploy Manual (Drag & Drop)

1. Login ke [vercel.com](https://vercel.com)
2. Klik "Add New" → "Project"
3. Pilih tab "Import Third-Party Git Repository" atau drag folder `backend` langsung
4. Configure project settings
5. Klik "Deploy"

## Langkah 3: Konfigurasi Environment Variables

1. **Buka Dashboard Vercel**
   - Pilih project yang baru dibuat
   - Klik tab "Settings"
   - Klik "Environment Variables"

2. **Tambahkan semua environment variables:**

   | Name | Value | Environment |
   |------|-------|-------------|
   | `SUPABASE_URL` | https://xxx.supabase.co | Production, Preview, Development |
   | `SUPABASE_ANON_KEY` | eyJhbGc... | Production, Preview, Development |
   | `SUPABASE_SERVICE_ROLE_KEY` | eyJhbGc... | Production, Preview, Development |
   | `EMAIL_HOST` | smtp.gmail.com | Production, Preview, Development |
   | `EMAIL_PORT` | 587 | Production, Preview, Development |
   | `EMAIL_USER` | your-email@gmail.com | Production, Preview, Development |
   | `EMAIL_PASS` | your-app-password | Production, Preview, Development |
   | `EMAIL_FROM` | your-email@gmail.com | Production, Preview, Development |
   | `EMAIL_FROM_NAME` | Unit Activity UKDC | Production, Preview, Development |
   | `PORT` | 3000 | Production, Preview, Development |

3. **Klik "Save"** untuk setiap variable

4. **Redeploy aplikasi**
   - Klik tab "Deployments"
   - Klik tombol "Redeploy" pada deployment terakhir
   - Atau push commit baru ke GitHub (akan auto-deploy)

## Langkah 4: Testing Deployment

### 4.1 Cek Health Endpoint

Setelah deployment selesai, Vercel akan memberikan URL deployment, contoh:
```
https://unit-activity-backend.vercel.app
```

Test health endpoint:
```bash
curl https://unit-activity-backend.vercel.app/api/health
```

Response yang diharapkan:
```json
{
  "success": true,
  "message": "Email service is running",
  "timestamp": "2026-01-26T..."
}
```

### 4.2 Test Send Email (Postman/cURL)

**Send Verification Email:**
```bash
curl -X POST https://unit-activity-backend.vercel.app/api/send-verification-email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "code": "123456"
  }'
```

**Send Password Reset Email:**
```bash
curl -X POST https://unit-activity-backend.vercel.app/api/send-password-reset-email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "code": "654321"
  }'
```

### 4.3 Update URL di Aplikasi Flutter

Update base URL di aplikasi Flutter Anda untuk menunjuk ke URL Vercel:

```dart
// Sebelum (local)
const String baseUrl = 'http://localhost:3000';

// Sesudah (production)
const String baseUrl = 'https://unit-activity-backend.vercel.app';
```

## Langkah 5: Setup Custom Domain (Optional)

1. **Buka Settings → Domains** di dashboard Vercel
2. **Add Domain**: Masukkan domain custom Anda (contoh: `api.unitactivity.com`)
3. **Configure DNS**:
   - Jika domain di Vercel: Otomatis
   - Jika domain di tempat lain: Tambahkan CNAME record
     ```
     Type: CNAME
     Name: api (atau subdomain lain)
     Value: cname.vercel-dns.com
     ```
4. **Tunggu DNS propagation** (1-48 jam)
5. **SSL Certificate** akan otomatis di-generate oleh Vercel

## Troubleshooting

### Error: "Module not found"

**Penyebab**: Dependencies tidak terinstall

**Solusi**:
- Pastikan `package.json` lengkap
- Hapus `node_modules` dan `package-lock.json` lalu commit ulang
- Redeploy

### Error: "Environment variable not found"

**Penyebab**: Environment variables belum di-set

**Solusi**:
- Cek di Settings → Environment Variables
- Pastikan semua variable sudah ditambahkan untuk environment "Production"
- Redeploy setelah menambahkan variable

### Email tidak terkirim

**Penyebab**: SMTP credentials salah atau Gmail memblokir

**Solusi**:
1. **Untuk Gmail**: Gunakan App Password, bukan password biasa
   - Buka Google Account → Security
   - Enable 2-Step Verification
   - Generate App Password
   - Gunakan App Password sebagai `EMAIL_PASS`

2. **Cek email provider**: Beberapa provider memblokir SMTP dari serverless
   - Alternatif: Gunakan SendGrid, Mailgun, atau AWS SES

### Vercel Function Timeout

**Penyebab**: Free plan Vercel memiliki limit 10 detik untuk serverless functions

**Solusi**:
- Optimasi kode untuk lebih cepat
- Upgrade ke Vercel Pro jika butuh timeout lebih lama
- Untuk background jobs, pertimbangkan alternatif seperti Railway atau Render

### CORS Error saat akses dari Flutter

**Penyebab**: CORS policy

**Solusi**: Pastikan `server.js` sudah menggunakan CORS middleware dengan konfigurasi yang benar:

```javascript
const cors = require('cors');

// Untuk development (allow all)
app.use(cors());

// Atau untuk production (specific origin)
app.use(cors({
  origin: ['https://yourdomain.com', 'https://www.yourdomain.com'],
  methods: ['GET', 'POST'],
  credentials: true
}));
```

## Best Practices

1. **Environment Variables**
   - Jangan pernah commit `.env` ke Git
   - Gunakan `.env.example` sebagai template
   - Simpan credentials di password manager

2. **Logging**
   - Gunakan Vercel logs untuk debugging
   - Akses via: Dashboard → Deployments → klik deployment → Function Logs
   - Atau via CLI: `vercel logs [deployment-url]`

3. **Monitoring**
   - Setup monitoring di Vercel Analytics
   - Monitor API usage untuk menghindari limit
   - Free plan: 100 GB bandwidth/bulan, 100,000 function invocations/bulan

4. **Security**
   - Tambahkan rate limiting untuk mencegah spam
   - Validasi input dengan ketat
   - Gunakan HTTPS untuk semua request
   - Pertimbangkan menambahkan API key authentication

5. **Deployment Workflow**
   - Gunakan branch `main` untuk production
   - Gunakan branch `develop` untuk preview deployments
   - Test di preview URL sebelum merge ke main

## Vercel Limits (Free Plan)

- **Function Execution**: 10 detik timeout
- **Bandwidth**: 100 GB/bulan
- **Invocations**: 100,000/bulan
- **Deployments**: Unlimited
- **Team Members**: 1

Untuk kebutuhan lebih besar, upgrade ke **Vercel Pro** ($20/bulan).

## Alternatif Platform Deployment

Jika Vercel tidak cocok, pertimbangkan:

1. **Railway** - Similar serverless, generous free tier
2. **Render** - Free tier dengan always-on instance (tapi slow cold start)
3. **Fly.io** - Global deployment, Dockerfile support
4. **Heroku** - Classic PaaS (berbayar mulai Nov 2022)
5. **AWS Lambda + API Gateway** - Fully customizable
6. **Google Cloud Run** - Container-based serverless

## Support & Resources

- **Vercel Documentation**: https://vercel.com/docs
- **Vercel CLI Docs**: https://vercel.com/docs/cli
- **Support**: https://vercel.com/support
- **Community**: https://github.com/vercel/vercel/discussions

---

**Selamat! Backend Anda sekarang sudah deployed di Vercel 🚀**
