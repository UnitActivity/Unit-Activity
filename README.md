# 🏢 Unit Activity

## 📌 Overview

**Unit Activity** adalah aplikasi desktop lintas platform untuk mengelola dan memantau aktivitas unit dalam organisasi atau perusahaan. Dibangun dengan teknologi modern, aplikasi ini menyediakan antarmuka yang intuitif dan fitur lengkap untuk meningkatkan efisiensi pengelolaan aktivitas harian.

Aplikasi ini mendukung berbagai sistem operasi utama, memungkinkan pengguna dari berbagai platform untuk mengakses dan menggunakan aplikasi dengan pengalaman yang konsisten.

---

## 🚀 Cara Memulai

1. Lihat bagian **Releases** untuk mendapatkan versi terbaru
2. Unduh aplikasi sesuai sistem operasi Anda
3. Ikuti panduan instalasi di bawah

---

## 📺 Video Tutorial

Untuk panduan visual lengkap, tonton video tutorial berikut:

👉 [Tonton Video Tutorial](https://drive.google.com/file/d/1uAQ7xl8u4GW3FwgIDQHS4eQwA186uXbx/view?usp=drive_link)

Video ini mencakup :
- Proses instalasi di platform Windows dan Linux

---

## 🪟 Instalasi Windows

### 📥 Download
Unduh aplikasi untuk Windows:
👉 [Download ua_win64.zip](https://github.com/user-attachments/files/24905993/ua_win64.zip)

### 📋 Persyaratan Sistem
Sebelum menjalankan aplikasi, pastikan sistem Windows Anda memiliki:
- **Visual C++ Redistributable 2015-2022**
  - Jika muncul error "msvcp140.dll undefined", download dan install dari:
  👉 [Download VC Redist](https://download.visualstudio.microsoft.com/download/pr/7ebf5fdb-36dc-4145-b0a0-90d3d5990a61/CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B/VC_redist.x64.exe)

- **Microsoft Edge WebView2**
  - Download dan install dari:
  👉 [Download WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/?ch=1&form=MA13LH#download)

### 🛠️ Langkah Instalasi
1. **Extract file ZIP**
   - Extract file `ua_win64.zip` yang telah didownload
   - **Penting**: Jangan jalankan aplikasi langsung dari dalam ZIP

2. **Buka folder hasil extract**
   - Navigasi ke folder yang telah diextract
   - Cari file `unit_activity.exe` (ikon logo aplikasi)

3. **Jalankan aplikasi**
   - Double-click `unit_activity.exe`
   - Jika Windows Defender memblokir, klik "More info" → "Run anyway"

### 🔧 Troubleshooting
- **Aplikasi tidak terbuka/tutup**: Periksa koneksi internet (dibutuhkan untuk database)
- **Windows Defender blokir**: Klik "More info" → "Run anyway"
- **Antivirus mendeteksi virus**: Ini adalah false positive umum pada aplikasi Flutter. Tambahkan ke whitelist jika perlu

---

## 🐧 Instalasi Linux

### 📥 Download
Unduh aplikasi untuk Linux:
👉 [Download ua-linux.zip](https://github.com/user-attachments/files/24861587/ua-linux.zip)

### 📋 Persyaratan Sistem
Berikut dependencies yang diperlukan untuk distro Linux populer:

**Ubuntu/Debian/Pop!_OS/Linux Mint/Zorin OS:**
```bash
sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  ninja-build \
  libgtk-3-dev \
  libblkid-dev \
  liblzma-dev \
  libglu1-mesa
```

**Arch Linux/Manjaro:**
```bash
sudo pacman -Sy \
  clang \
  cmake \
  ninja \
  gtk3 \
  libblkid \
  xz \
  glu
```

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install -y \
  clang \
  cmake \
  ninja-build \
  gtk3-devel \
  libblkid-devel \
  xz-devel \
  mesa-libGLU
```

**Distro lainnya:**
- Sesuaikan dengan package manager distro Anda
- Pastikan package berikut terinstall: clang, cmake, ninja, GTK3, libblkid, xz, GLU

### 🛠️ Langkah Instalasi
1. **Extract file**
   ```bash
   unzip ua-linux.zip
   cd ua-linux
   ```

2. **Berikan izin eksekusi**
   ```bash
   chmod +x run.sh
   chmod +x unit_activity
   ```

3. **Jalankan aplikasi**
   ```bash
   ./run.sh
   ```
   File `run.sh` berisi:
   ```bash
   #!/usr/bin/sh
   LD_LIBRARY_PATH="./lib" ./unit_activity
   ```

### 🔧 Troubleshooting
- **Permission denied**: Jalankan `chmod +x run.sh unit_activity`
- **Missing libraries**: Install dependencies sesuai distro Anda
- **Tidak bisa connect**: Pastikan koneksi internet aktif
- **Aplikasi crash**: Jalankan dari terminal untuk melihat error: `./run.sh 2>&1 | tee app.log`

---

## 📱 Instalasi Android

### 📥 Download
Unduh aplikasi untuk Android:
👉 [Download Unit Activity APK](https://drive.google.com/file/d/1Tbd5avcTV5DnW18nAJL_JlnBD3Awp8vk/view?usp=drive_link)

### 🛠️ Langkah Instalasi
1. **Download APK**
   - Buka link di atas di perangkat Android
   - Download file APK

2. **Aktifkan instalasi dari sumber tidak dikenal**
   - Buka Settings → Security
   - Aktifkan "Unknown Sources" atau "Install unknown apps"
   - Izinkan browser atau file manager Anda untuk menginstal APK

3. **Instal aplikasi**
   - Buka file APK yang didownload
   - Ikuti petunjuk instalasi
   - Buka aplikasi setelah instalasi selesai

### 🔧 Troubleshooting
- **Tidak bisa install**: Pastikan "Unknown Sources" diaktifkan
- **Aplikasi tidak terbuka**: Restart perangkat dan coba lagi
- **Permission ditolak**: Berikan semua permission yang diminta

---

## 💻 System Requirements

### Minimum Requirements
- **Windows**: Windows 7+, 2GB RAM, 500MB storage
- **Linux**: Ubuntu 20.04+ atau equivalent, 2GB RAM, 500MB storage
- **Android**: Android 8.0+, 2GB RAM
- **Internet**: Koneksi internet stabil diperlukan

### Recommended
- **Windows**: Windows 10+, 4GB RAM, SSD
- **Linux**: Ubuntu 22.04+, 4GB RAM, SSD
- **Android**: Android 10+, 4GB RAM
- **Internet**: Koneksi broadband

---

## 🔧 Advanced Configuration

### Linux Desktop Shortcut (Optional)
Buat shortcut desktop untuk akses mudah:

1. Buat file desktop:
   ```bash
   nano ~/.local/share/applications/unit-activity.desktop
   ```

2. Isi dengan konten berikut (sesuaikan path):
   ```ini
   [Desktop Entry]
   Version=1.0
   Type=Application
   Name=Unit Activity
   Comment=Aplikasi Manajemen Aktivitas Unit
   Exec=/path/to/ua-linux/run.sh
   Icon=/path/to/ua-linux/icon.png
   Terminal=false
   Categories=Utility;Office;
   ```

3. Berikan izin eksekusi:
   ```bash
   chmod +x ~/.local/share/applications/unit-activity.desktop
   ```

### HiDPI/4K Display (Linux)
Untuk layar resolusi tinggi:
```bash
export GDK_SCALE=2
./run.sh
```

Atau untuk scaling fraksional:
```bash
export GDK_DPI_SCALE=0.5
./run.sh
```

---

## ❓ Frequently Asked Questions

**Q: Apakah aplikasi ini gratis?**  
A: Ya, aplikasi ini sepenuhnya gratis dan open source.

**Q: Data saya disimpan di mana?**  
A: Data disimpan di database cloud yang aman dengan koneksi terenkripsi.

**Q: Bisakah digunakan offline?**  
A: Sebagian fitur memerlukan koneksi internet untuk sinkronisasi data.

**Q: Bagaimana cara update aplikasi?**  
A: Download versi terbaru dari Releases dan ikuti panduan instalasi.

---

## 📞 Support & Feedback

Jika Anda mengalami masalah atau memiliki saran:
1. Cek troubleshooting di atas
2. Tonton video tutorial
3. Buat issue di GitHub repository

---

## 🏗️ Development

Aplikasi ini dibangun menggunakan:
- **Framework**: Flutter
- **Backend**: Java Script / Cloud Services
- **Database**: Supabase
- **Platform**: Windows, Linux, Android

---

## 📄 License

Aplikasi ini dilisensikan di bawah MIT License. Lihat file LICENSE untuk detail lengkap.

---

## ❤️ Credits

Dikembangkan oleh **UnitActivity Team**  
Dengan teknologi Flutter untuk pengalaman lintas platform yang optimal.

© 2024 Unit Activity. Semua hak dilindungi.
