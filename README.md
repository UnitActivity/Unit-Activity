# 📊 Unit Activity

## 📌 Overview

**Unit Activity** adalah platform manajemen organisasi mahasiswa (UKM) yang dirancang untuk mempermudah administrasi, pemantauan kegiatan, dan sistem absensi digital. Aplikasi ini menghubungkan pengelola (Admin), organisasi (UKM), dan anggota (User) dalam satu ekosistem yang terintegrasi.

Dengan menggunakan Unit Activity, proses pencatatan kehadiran tidak lagi dilakukan secara manual, melainkan melalui sistem **QR Code** yang dinamis dan efisien.

---

## 🚀 Fitur Utama

* **Multi-Role System**: Akses khusus untuk Admin pusat, Pengelola UKM, dan Mahasiswa/User.
* **Dynamic QR Attendance**: Sistem absensi berbasis scan QR Code untuk setiap kegiatan.
* **Information Hub**: Pusat pengumuman dan informasi terkini terkait kegiatan kampus.
* **Document Management**: Manajemen dokumen organisasi yang terorganisir.
* **Push Notifications**: Notifikasi langsung ke perangkat pengguna untuk update kegiatan.
* **Activity History**: Rekam jejak kehadiran dan aktivitas anggota yang transparan.

---

## 🌐 Platform Support

Unit Activity tersedia di berbagai platform untuk fleksibilitas akses:

* 🌍 **Web Version** (Akses Instan melalui Browser)
* 🪟 **Windows** (Aplikasi Desktop)
* 🐧 **Linux** (Ubuntu & Distro populer lainnya)
* 📱 **Android** (Aplikasi Mobile)

---

## 📺 Video Tutorial 

Tersedia panduan visual langkah-demi-langkah untuk proses instalasi.

👉 **[Tonton Video Tutorial Di Sini](https://drive.google.com/file/d/1uAQ7xl8u4GW3FwgIDQHS4eQwA186uXbx/view?usp=drive_link)**

---

## 🔗 Download & Link Akses

| Platform | Link Akses / Download |
| --- | --- |
| 🌍 **Web Version** | [Buka di Browser](https://unit-activity.vercel.app/) |
| 🪟 **Windows** | [Download .zip](https://github.com/user-attachments/files/24905993/ua_win64.zip) |
| 🐧 **Linux** | [Download .zip](https://github.com/user-attachments/files/24861587/ua-linux.zip) |
| 📱 **Android** | [Download APK](https://drive.google.com/file/d/1Tbd5avcTV5DnW18nAJL_JlnBD3Awp8vk/view?usp=drive_link) |

---

## 🪟 Panduan Instalasi: Windows

### 1. Persiapan Sistem (Sekali saja)

Pastikan perangkat Anda sudah terinstall komponen berikut:

* **Visual C++ Redistributable 2015-2022**: [Download di sini](https://download.visualstudio.microsoft.com/download/pr/7ebf5fdb-36dc-4145-b0a0-90d3d5990a61/CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B/VC_redist.x64.exe)
* **Microsoft Edge WebView2**: [Download di sini](https://developer.microsoft.com/en-us/microsoft-edge/webview2/?ch=1&form=MA13LH#download)

### 2. Cara Menjalankan

1. Extract file `ua_win64.zip`.
2. Buka folder hasil extract.
3. Cari file **`unit_activity.exe`** (ikon logo aplikasi).
4. Double click untuk menjalankan.

> 💡 **Troubleshooting**: Jika muncul peringatan "Windows protected your PC", klik *More info* -> *Run anyway*.

---

## 🐧 Panduan Instalasi: Linux

### 1. Persiapan Dependencies

Buka terminal dan jalankan perintah sesuai distro Anda:

* **Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build libgtk-3-dev libblkid-dev liblzma-dev libglu1-mesa

```


* **Arch Linux**:
```bash
sudo pacman -Sy clang cmake ninja gtk3 libblkid xz glu

```



### 2. Cara Menjalankan

1. Extract file `ua-linux.zip`.
2. Masuk ke direktori aplikasi: `cd unit_activity_linux`
3. Berikan izin eksekusi: `chmod +x unit_activity`
4. **Jalankan aplikasi** menggunakan script yang tersedia:
```bash
./run.sh

```



---

## 📱 Panduan Instalasi: Android

1. Download file APK dari link di atas.
2. Buka file APK di smartphone Anda.
3. Jika muncul peringatan keamanan, aktifkan izin **"Install dari Sumber Tidak Dikenal"** (Install from Unknown Sources).
4. Selesaikan proses instalasi dan buka aplikasi.

---

## 🧠 Catatan Penting & Tips

* **Koneksi Internet**: Aplikasi ini membutuhkan koneksi internet aktif untuk sinkronisasi data ke database.
* **QR Scanner**: Pastikan memberikan izin akses kamera pada versi Android untuk fitur scan absensi.
* **Login**: Gunakan akun yang telah didaftarkan oleh administrator masing-masing UKM.

---

## ❤️ Credits

Dikembangkan untuk meningkatkan efisiensi kegiatan organisasi mahasiswa.

**Unit Activity** — *Manage your organization with ease.* 🚀
