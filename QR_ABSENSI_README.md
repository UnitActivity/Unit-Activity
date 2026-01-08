# 🚀 QR Absensi Implementation - Quick Start Guide

## 📋 Overview

Implementasi lengkap fitur **QR Scan Absensi** untuk aplikasi Unit Activity dengan Supabase backend. Fitur ini memungkinkan user untuk melakukan absensi event dan pertemuan UKM menggunakan QR Code dinamis.

---

## ✨ Fitur Utama

1. ✅ **QR Scanner Global** - Tersedia di semua halaman user
2. ✅ **Validasi Pendaftaran Event** - User harus terdaftar sebelum absen
3. ✅ **Validasi Anggota UKM** - User harus menjadi anggota untuk absen pertemuan
4. ✅ **Halaman Riwayat Absensi** - Menampilkan history absensi lengkap
5. ✅ **QR Code Dinamis** - Berganti setiap 10 detik untuk keamanan

---

## 🛠️ Setup Database

### Step 1: Run SQL Script

1. Buka **Supabase Dashboard**
2. Navigate ke **SQL Editor**
3. Create new query
4. Copy-paste isi file `supabase_setup.sql`
5. Click **Run**
6. Verifikasi dengan query:

```sql
-- Cek tabel
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('peserta_event', 'absen_event', 'absen_pertemuan');

-- Should return 3 rows
```

### Step 2: Verify RLS Policies

```sql
-- Cek policies
SELECT tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('peserta_event', 'absen_event', 'absen_pertemuan');

-- Should return multiple policies for each table
```

---

## 📱 Testing Guide

### Test 1: Absensi Event (Success Flow)

**Prerequisites:**
- User sudah login
- User sudah terdaftar di event (ada di tabel `peserta_event`)

**Steps:**
1. Buka aplikasi, login sebagai user
2. Klik icon QR Scanner di AppBar (any page)
3. Scan QR Code event
4. ✅ Should show: "Berhasil absen di event [Nama Event]!"
5. Cek di menu **Riwayat Absensi** → Absensi muncul

### Test 2: Absensi Event (Error - Belum Terdaftar)

**Prerequisites:**
- User sudah login
- User BELUM terdaftar di event

**Steps:**
1. Scan QR Code event
2. ❌ Should show: "Anda belum terdaftar di event ini. Silakan daftar terlebih dahulu."

### Test 3: Absensi Pertemuan (Success Flow)

**Prerequisites:**
- User sudah login
- User adalah anggota UKM (ada di tabel `user_halaman_ukm`)

**Steps:**
1. Scan QR Code pertemuan
2. ✅ Should show: "Berhasil absen di pertemuan [Topik]!"
3. Cek di **Riwayat Absensi** → Absensi muncul

### Test 4: Absensi Pertemuan (Error - Bukan Anggota)

**Prerequisites:**
- User sudah login
- User BUKAN anggota UKM

**Steps:**
1. Scan QR Code pertemuan
2. ❌ Should show: "Anda bukan anggota UKM ini. Hanya anggota yang dapat absen."

### Test 5: QR Code Expired

**Steps:**
1. Tunggu QR Code lebih dari 15 detik
2. Scan QR Code lama
3. ❌ Should show: "QR Code sudah kadaluarsa. Silakan scan QR Code yang baru."

---

## 🗂️ Struktur File

### File Baru
```
lib/user/attendance_history.dart  ← Halaman Riwayat Absensi
IMPLEMENTATION_DOCS.md            ← Dokumentasi lengkap
supabase_setup.sql                ← SQL setup script
QR_ABSENSI_README.md             ← Quick start guide (file ini)
```

### File Modified
```
lib/services/attendance_service.dart   ← Validasi pendaftaran event
lib/widgets/user_sidebar.dart          ← Menu Riwayat Absensi
lib/user/dashboard_user.dart           ← Navigation handler
lib/user/event.dart                    ← Navigation handler
lib/user/ukm.dart                      ← Navigation handler
lib/user/history.dart                  ← Navigation handler
lib/user/profile.dart                  ← Navigation handler
lib/user/notifikasi_user.dart          ← Navigation handler
```

---

## 🔑 Key Components

### 1. AttendanceService
Location: `lib/services/attendance_service.dart`

**Methods:**
- `recordEventAttendance()` - Record absensi event
- `recordPertemuanAttendance()` - Record absensi pertemuan
- `processQRCodeAttendance()` - Process QR scan
- `getUserAttendanceHistory()` - Get user history

### 2. QRScannerMixin
Location: `lib/widgets/qr_scanner_mixin.dart`

**Methods:**
- `openQRScannerDialog()` - Open QR scanner
- `buildQRScannerButton()` - Create QR button

### 3. DynamicQRService
Location: `lib/services/dynamic_qr_service.dart`

**Methods:**
- `generateDynamicQR()` - Generate QR code
- `validateDynamicQR()` - Validate QR code

---

## 🎯 QR Code Format

```
Format: TYPE:ID:TIMESTAMP:SIGNATURE

Example Event:
EVENT:550e8400-e29b-41d4-a716-446655440000:1704672000:a1b2c3d4...

Example Pertemuan:
PERTEMUAN:660f9511-f3ac-52e5-b827-557766551111:1704672015:e5f6g7h8...
```

**Components:**
- `TYPE`: EVENT or PERTEMUAN
- `ID`: UUID of event/pertemuan
- `TIMESTAMP`: Unix timestamp (seconds)
- `SIGNATURE`: HMAC-SHA256 hash

---

## 🔒 Security Features

1. **Dynamic QR Code**
   - Changes every 10 seconds
   - 5 second grace period
   - Total validity: 15 seconds

2. **Signature Validation**
   - HMAC-SHA256 with secret key
   - Prevents QR code tampering

3. **Row Level Security (RLS)**
   - Users can only see their own data
   - Admin/UKM can see their organization data

4. **Validation Rules**
   - Event: Must be registered (peserta_event)
   - Pertemuan: Must be UKM member (user_halaman_ukm)
   - No duplicate attendance

---

## 📊 Database Schema

### peserta_event
```
id_peserta    UUID PRIMARY KEY
id_event      UUID → events(id_events)
id_user       UUID → users(id_user)
status        VARCHAR(20)
registered_at TIMESTAMPTZ
```

### absen_event
```
id_absen      UUID PRIMARY KEY
id_event      UUID → events(id_events)
id_user       UUID → users(id_user)
jam           VARCHAR(5)
status        VARCHAR(20)
created_at    TIMESTAMPTZ
```

### absen_pertemuan
```
id_absen      UUID PRIMARY KEY
id_pertemuan  UUID → pertemuan(id_pertemuan)
id_user       UUID → users(id_user)
jam           VARCHAR(5)
status        VARCHAR(20)
created_at    TIMESTAMPTZ
```

---

## 🧪 Manual Testing Data

### Insert Test User Registration
```sql
-- Register user to event
INSERT INTO peserta_event (id_event, id_user, status)
VALUES (
  'your-event-uuid',
  'your-user-uuid',
  'terdaftar'
);
```

### Insert Test UKM Membership
```sql
-- Add user as UKM member
INSERT INTO user_halaman_ukm (id_ukm, id_user, status)
VALUES (
  'your-ukm-uuid',
  'your-user-uuid',
  'aktif'
);
```

### Query User Attendance
```sql
-- Get all user attendance
SELECT * FROM view_user_event_attendance 
WHERE id_user = 'your-user-uuid';

SELECT * FROM view_user_pertemuan_attendance 
WHERE id_user = 'your-user-uuid';
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: "Table peserta_event does not exist"
**Solution:**
```sql
-- Run the SQL setup script first
-- File: supabase_setup.sql
```

### Issue 2: "User not registered" even though registered
**Solution:**
```sql
-- Check registration
SELECT * FROM peserta_event 
WHERE id_user = 'your-user-uuid' 
AND id_event = 'event-uuid';

-- If empty, insert registration
INSERT INTO peserta_event (id_event, id_user, status)
VALUES ('event-uuid', 'user-uuid', 'terdaftar');
```

### Issue 3: QR Scanner not working
**Solution:**
- Check camera permissions
- Verify mobile_scanner package installed
- Check Flutter version compatibility

### Issue 4: Navigation to Attendance History not working
**Solution:**
- Verify import statement in all user files:
```dart
import 'package:unit_activity/user/attendance_history.dart';
```

---

## 📞 Support Checklist

Before asking for help, check:
- [ ] SQL setup script executed successfully
- [ ] All tables exist (peserta_event, absen_event, absen_pertemuan)
- [ ] RLS policies are enabled
- [ ] User is logged in
- [ ] User is registered/member (depending on type)
- [ ] QR Code is not expired
- [ ] No duplicate attendance

---

## 🚀 Deployment Checklist

- [ ] Run SQL setup script in production Supabase
- [ ] Verify all tables created
- [ ] Verify RLS policies enabled
- [ ] Test QR scanning on physical device
- [ ] Test all error scenarios
- [ ] Test navigation to Attendance History
- [ ] Verify data appears in history page
- [ ] Check performance with multiple users

---

## 📈 Analytics Queries

### Total Attendance by Event
```sql
SELECT 
  e.nama_event,
  COUNT(*) as total_hadir
FROM absen_event ae
JOIN events e ON ae.id_event = e.id_events
GROUP BY e.nama_event
ORDER BY total_hadir DESC;
```

### User Attendance Summary
```sql
SELECT 
  u.username,
  COUNT(DISTINCT ae.id_event) as total_events,
  COUNT(DISTINCT ap.id_pertemuan) as total_pertemuan
FROM users u
LEFT JOIN absen_event ae ON u.id_user = ae.id_user
LEFT JOIN absen_pertemuan ap ON u.id_user = ap.id_user
GROUP BY u.username
ORDER BY total_events DESC;
```

### Attendance by Date
```sql
SELECT 
  DATE(created_at) as tanggal,
  COUNT(*) as total_absen
FROM absen_event
GROUP BY DATE(created_at)
ORDER BY tanggal DESC;
```

---

## 📚 Additional Resources

- [Full Documentation](IMPLEMENTATION_DOCS.md)
- [Supabase Setup SQL](supabase_setup.sql)
- [Flutter mobile_scanner package](https://pub.dev/packages/mobile_scanner)

---

## ✅ Success Criteria

Implementation is successful if:
- ✅ User can scan QR from any user page
- ✅ Event attendance requires registration
- ✅ Pertemuan attendance requires UKM membership
- ✅ Attendance history displays correctly
- ✅ QR Code expires after 15 seconds
- ✅ No duplicate attendance allowed
- ✅ All navigation works properly
- ✅ No breaking changes to existing features

---

**Version:** 1.0.0  
**Last Updated:** January 8, 2026  
**Status:** ✅ Production Ready
