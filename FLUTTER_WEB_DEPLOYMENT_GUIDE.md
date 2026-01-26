# Panduan Deploy Flutter Web ke Vercel

## Perbedaan Backend vs Frontend

Anda sekarang memiliki **DUA aplikasi** yang perlu dideploy terpisah:

1. **Backend (API Server)** → Sudah dideploy di `unit-activity-xv2b.vercel.app`
   - Untuk handle email service, reset password, dll
   - Berupa Node.js/Express server
   
2. **Frontend (Flutter Web App)** → Belum dideploy
   - Untuk tampilan aplikasi (UI) yang akan dilihat user
   - Berupa HTML, CSS, JavaScript hasil build Flutter

---

## Cara Deploy Flutter Web ke Vercel

### Opsi 1: Deploy ke Vercel (Recommended untuk Static Web)

#### Langkah 1: Build Flutter Web

```bash
flutter build web --release
```

Hasil build akan ada di folder `build/web/`

#### Langkah 2: Deploy Build Folder ke Vercel

**Via Vercel CLI:**

```bash
# Install Vercel CLI jika belum
npm install -g vercel

# Login
vercel login

# Deploy dari folder build/web
cd build/web
vercel

# Untuk production
vercel --prod
```

**Via Vercel Dashboard:**

1. Login ke [vercel.com](https://vercel.com)
2. Klik "Add New" → "Project"
3. Drag & drop folder `build/web` atau upload manual
4. Klik "Deploy"

**Via GitHub (Auto-deploy):**

1. Buat file `vercel.json` di **root project** (bukan di backend):

```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "installCommand": "curl -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz && tar xf flutter.tar.xz && export PATH=\"$PATH:`pwd`/flutter/bin\" && flutter doctor"
}
```

**CATATAN**: Deploy Flutter web via Vercel dengan auto-build agak rumit. Lebih mudah build lokal dulu, lalu deploy folder `build/web`.

#### Langkah 3: Update Environment (Jika Perlu)

Jika aplikasi Flutter Anda perlu environment variables (seperti API URL):

1. Di Vercel Dashboard → Settings → Environment Variables
2. Tambahkan variable yang diperlukan
3. Redeploy

---

### Opsi 2: Deploy ke Firebase Hosting (Lebih Mudah untuk Flutter)

Firebase Hosting lebih optimal untuk Flutter web.

#### Langkah 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

#### Langkah 2: Login Firebase

```bash
firebase login
```

#### Langkah 3: Initialize Firebase di Project

```bash
# Di root project Flutter
firebase init hosting

# Pilihan:
# - Use existing project atau create new
# - Public directory: build/web
# - Single-page app: Yes
# - Set up automatic builds: No
```

#### Langkah 4: Build dan Deploy

```bash
# Build Flutter web
flutter build web --release

# Deploy ke Firebase
firebase deploy --only hosting
```

Setelah deploy, Anda akan dapat URL seperti: `https://your-project.web.app`

---

### Opsi 3: Deploy ke GitHub Pages (Gratis)

#### Langkah 1: Build Flutter Web

```bash
flutter build web --release --base-href "/nama-repo/"
```

#### Langkah 2: Deploy ke GitHub Pages

```bash
# Copy hasil build ke branch gh-pages
cd build/web
git init
git add .
git commit -m "Deploy Flutter web"
git branch -M gh-pages
git remote add origin https://github.com/username/nama-repo.git
git push -f origin gh-pages
```

#### Langkah 3: Enable GitHub Pages

1. Buka repository di GitHub
2. Settings → Pages
3. Source: Deploy from branch `gh-pages`
4. Folder: / (root)
5. Save

Aplikasi akan tersedia di: `https://username.github.io/nama-repo/`

---

## Struktur Project Setelah Deploy

Setelah deploy, Anda akan memiliki:

```
Frontend (Flutter Web)
├── URL: https://unit-activity.vercel.app (atau domain lain)
└── Berisi: UI aplikasi (HTML, CSS, JS)

Backend (API Server)  
├── URL: https://unit-activity-xv2b.vercel.app
└── Berisi: API endpoints (/api/health, /api/send-email, dll)
```

---

## Update Base URL di Flutter App

Setelah backend dan frontend dideploy, update base URL API di aplikasi Flutter:

**Sebelum** (`lib/services/api_service.dart` atau sejenis):
```dart
const String baseUrl = 'http://localhost:3000';
```

**Sesudah**:
```dart
const String baseUrl = 'https://unit-activity-xv2b.vercel.app';
```

Kemudian rebuild dan redeploy Flutter web:
```bash
flutter build web --release
# Deploy ulang ke Vercel/Firebase/GitHub Pages
```

---

## Troubleshooting

### Flutter build error di Vercel

**Penyebab**: Vercel tidak memiliki Flutter SDK secara default

**Solusi**: Build lokal (`flutter build web`) lalu deploy folder `build/web` saja

### CORS error saat call API

**Penyebab**: Backend tidak allow origin dari frontend

**Solusi**: Update CORS di `backend/server.js`:
```javascript
app.use(cors({
  origin: [
    'https://unit-activity.vercel.app',  // URL frontend
    'http://localhost:3000'  // Untuk development
  ],
  methods: ['GET', 'POST'],
  credentials: true
}));
```

### Assets tidak muncul (gambar, font, dll)

**Penyebab**: Base href salah

**Solusi**: Build dengan base href yang benar:
```bash
# Untuk root domain
flutter build web --release --base-href="/"

# Untuk subdomain/path
flutter build web --release --base-href="/app/"
```

---

## Rekomendasi

Untuk Flutter Web, saya rekomendasikan:

1. **Firebase Hosting** - Paling mudah dan optimal untuk Flutter
2. **Vercel** - Bagus untuk static site, tapi perlu build lokal
3. **GitHub Pages** - Gratis, tapi lebih lambat

Untuk Backend API, tetap pakai **Vercel** (sudah bagus sekarang).

---

## Quick Start (Cara Tercepat)

### Metode 1: Via Vercel CLI (Recommended)

```bash
# 1. Build Flutter web (SUDAH SELESAI ✓)
flutter build web --release

# 2. Login ke Vercel (hanya sekali)
vercel login
# Ikuti instruksi di browser untuk login

# 3. Deploy dari folder build/web
cd build/web
vercel --prod

# 4. Ikuti prompt:
# - Set up and deploy? → Y
# - Project name? → unit-activity-web (atau nama lain)
# - Which scope? → Pilih akun Anda
# - Link to existing project? → N (untuk project baru)

# 5. Selesai! Copy URL deployment yang muncul
```

### Metode 2: Via Vercel Dashboard (Paling Mudah)

1. **Build Flutter web** (sudah selesai ✓)
   ```bash
   flutter build web --release
   ```

2. **Login ke Vercel Dashboard**
   - Buka https://vercel.com/login
   - Login dengan GitHub/GitLab/Email

3. **Deploy Manual**
   - Klik "Add New" → "Project"
   - Klik "Browse" atau drag & drop folder `build/web`
   - Project Name: `unit-activity-web`
   - Framework Preset: **Other** (atau None)
   - Root Directory: `.` (default)
   - Klik "Deploy"

4. **Tunggu deployment selesai** (~1-2 menit)

5. **Copy URL deployment**
   - Contoh: `https://unit-activity-web.vercel.app`

### Metode 3: Via GitHub Pages (Gratis, Tanpa Akun Tambahan)

```bash
# 1. Build Flutter web (sudah selesai ✓)
flutter build web --release

# 2. Buat repository baru atau gunakan yang ada
cd build/web

# 3. Initialize git dan push ke branch gh-pages
git init
git add .
git commit -m "Deploy Flutter web"
git branch -M gh-pages
git remote add origin https://github.com/UnitActivity/Unit-Activity-Web.git
git push -f origin gh-pages

# 4. Enable GitHub Pages di repository settings
# Settings → Pages → Source: gh-pages → Save

# 5. Aplikasi akan tersedia di:
# https://unitactivity.github.io/Unit-Activity-Web/
```

---

## Setelah Deployment Berhasil

### Update API Base URL di Flutter

Setelah frontend dideploy, update base URL agar menunjuk ke backend:

**Cari file yang berisi API base URL** (biasanya di `lib/services/` atau `lib/config/`):

```dart
// SEBELUM (local)
const String baseUrl = 'http://localhost:3000';

// SESUDAH (production)
const String baseUrl = 'https://unit-activity-xv2b.vercel.app';
```

**Rebuild dan redeploy:**
```bash
flutter build web --release
cd build/web
vercel --prod
```

### Update CORS di Backend

Update `backend/server.js` untuk allow origin dari frontend:

```javascript
app.use(cors({
  origin: [
    'https://unit-activity-web.vercel.app',  // Ganti dengan URL frontend Anda
    'http://localhost:3000'  // Untuk development
  ],
  methods: ['GET', 'POST'],
  credentials: true
}));
```

---

**Selesai! Frontend dan backend Anda sekarang sudah live di internet 🚀**

## Struktur Final

```
✅ Backend API: https://unit-activity-xv2b.vercel.app
✅ Frontend Web: https://unit-activity-web.vercel.app (setelah deploy)
```
