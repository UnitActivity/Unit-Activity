# 🔧 CARA MEMPERBAIKI MASALAH NOTIFIKASI

## Masalah yang Dilaporkan

❌ User tidak bisa menerima notifikasi dari admin
❌ Notifikasi tidak tersimpan di database
❌ Setelah logout → admin kirim notif → login lagi → tidak ada notifikasi

## Penyebab Masalah

1. **Tabel notifikasi belum ada/struktur salah** → Admin kirim ke tabel yang salah
2. **Admin mengirim ke tabel lama** (`notification_preference`) → Harus ke `notifikasi`
3. **Push notification belum di-setup** → FCM tokens belum ter-register

## Solusi: 3 Langkah

### ✅ STEP 1: Run Database Migrations

**WAJIB dilakukan terlebih dahulu!**

1. Buka Supabase Dashboard → SQL Editor
2. Run migrations **DALAM URUTAN INI:**

```sql
-- PERTAMA: Create tabel notifikasi
-- Copy & paste isi file: database/migrations/create_notifikasi_table.sql
-- Klik RUN

-- KEDUA: Create tabel device_tokens  
-- Copy & paste isi file: database/migrations/create_device_tokens_table.sql
-- Klik RUN

-- KETIGA: Create tabel notifikasi_anonymous
-- Copy & paste isi file: database/migrations/create_notifikasi_anonymous_table.sql
-- Klik RUN
```

3. **Verifikasi berhasil:**
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('notifikasi', 'device_tokens', 'notifikasi_anonymous');
```
Harus return **3 rows** ✅

---

### ✅ STEP 2: Test Kirim Notifikasi dari Admin

1. **Login sebagai Admin**
2. **Buka halaman Kirim Notifikasi**
3. **Isi form:**
   - Judul: "Test Notification"
   - Pesan: "Testing notifikasi dari admin"
   - Target: "Semua User"
   - Tipe: "Info"
4. **Klik Kirim**

5. **Verifikasi di database:**
```sql
-- Check notifikasi tersimpan
SELECT * FROM notifikasi ORDER BY created_at DESC LIMIT 5;
```

Jika ada error, check console logs di browser (F12 → Console)

---

### ✅ STEP 3: Test di User

1. **Login sebagai User**
2. **Buka halaman Notifikasi**
3. **Seharusnya notifikasi muncul** ✅

**Jika tidak muncul:**

Check di SQL:
```sql
-- Ganti USER_UUID dengan ID user Anda
SELECT * FROM notifikasi WHERE id_user = 'USER_UUID' ORDER BY created_at DESC;
```

Jika ada data → masalah di frontend (cek console logs)
Jika tidak ada data → admin belum berhasil kirim

---

## Testing Skenario Lengkap

### Skenario 1: User Online, Terima Notifikasi

**Steps:**
1. User buka app → Login
2. Admin kirim notifikasi
3. **Expected:** Notifikasi muncul di app ✅

**Verify:**
```sql
SELECT * FROM notifikasi WHERE id_user = 'USER_UUID' AND is_read = false;
```

---

### Skenario 2: User Logout, Admin Kirim, User Login Lagi

**Steps:**
1. User login → Copy FCM token dari console logs
2. User logout
3. Admin kirim notifikasi
4. User login lagi
5. **Expected:** Notifikasi muncul di app ✅

**Verify BEFORE login:**
```sql
-- Check notifikasi tersimpan untuk user tersebut
SELECT * FROM notifikasi WHERE id_user = 'USER_UUID';
```

**Verify AFTER login:**
```sql
-- Notifikasi seharusnya sama (tidak hilang)
SELECT * FROM notifikasi WHERE id_user = 'USER_UUID' ORDER BY created_at DESC;
```

---

### Skenario 3: User Offline (App Closed), Terima Notifikasi

**⚠️ REQUIRES FIREBASE SETUP!**

**Prerequisites:**
1. Firebase project sudah setup
2. `google-services.json` ada di `android/app/`
3. App sudah di-build dengan Firebase

**Steps:**
1. User buka app → FCM token generated
2. Force close app (swipe di recent apps)
3. Admin kirim notifikasi
4. User buka app lagi
5. **Expected:** Notifikasi muncul ✅

**Verify:**
```sql
-- Check notifikasi tersimpan
SELECT * FROM notifikasi WHERE id_user = 'USER_UUID' ORDER BY created_at DESC;
```

---

## Troubleshooting

### ❌ Error: "relation notifikasi does not exist"

**Fix:** Run migration `create_notifikasi_table.sql`

```sql
-- Check tabel ada
SELECT table_name FROM information_schema.tables WHERE table_name = 'notifikasi';
```

---

### ❌ Error: "violates foreign key constraint"

**Fix:** Check user ID valid

```sql
-- Verify user exists
SELECT id_user, username, email FROM users WHERE id_user = 'USER_UUID';
```

---

### ❌ Notifikasi tidak muncul di app

**Debug Steps:**

1. **Check database:**
```sql
SELECT * FROM notifikasi WHERE id_user = 'USER_UUID';
```
- Ada data? → Masalah di frontend
- Tidak ada? → Admin belum berhasil kirim

2. **Check console logs:**
- Buka Developer Tools (F12)
- Tab Console
- Cari error messages

3. **Check user_notification_service.dart:**
```dart
// Pastikan loadNotifications() dipanggil
await UserNotificationService().loadNotifications();
```

---

### ❌ Admin tidak bisa kirim notifikasi

**Debug Steps:**

1. **Check error di console:**
```
Error sending notification: ...
```

2. **Check tabel notifikasi ada:**
```sql
SELECT * FROM notifikasi LIMIT 1;
```

3. **Check RLS policies:**
```sql
SELECT * FROM pg_policies WHERE tablename = 'notifikasi';
```

4. **Temporary fix (development only!):**
```sql
-- Disable RLS temporarily
ALTER TABLE notifikasi DISABLE ROW LEVEL SECURITY;

-- Try sending notification again

-- Re-enable RLS
ALTER TABLE notifikasi ENABLE ROW LEVEL SECURITY;
```

---

## Quick Test Script

Copy-paste ini di SQL Editor untuk test cepat:

```sql
-- 1. Check tables exist
SELECT 'Tables Check' as test,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifikasi')
    AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_tokens')
    AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifikasi_anonymous')
    THEN '✅ ALL TABLES EXIST'
    ELSE '❌ MISSING TABLES'
  END as result;

-- 2. Check RLS enabled
SELECT 'RLS Check' as test,
  CASE 
    WHEN (SELECT rowsecurity FROM pg_tables WHERE tablename = 'notifikasi') = true
    THEN '✅ RLS ENABLED'
    ELSE '❌ RLS DISABLED'
  END as result;

-- 3. Check functions exist
SELECT 'Functions Check' as test,
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'migrate_anonymous_notifications_to_user')
    THEN '✅ MIGRATION FUNCTION EXISTS'
    ELSE '❌ MIGRATION FUNCTION MISSING'
  END as result;

-- 4. Count notifications
SELECT 'Notifications Count' as test,
  CONCAT(COUNT(*), ' notifications in database') as result
FROM notifikasi;

-- 5. Count device tokens
SELECT 'Device Tokens Count' as test,
  CONCAT(COUNT(*), ' tokens registered') as result
FROM device_tokens;
```

**Expected Output:**
```
✅ ALL TABLES EXIST
✅ RLS ENABLED
✅ MIGRATION FUNCTION EXISTS
X notifications in database
Y tokens registered
```

---

## Checklist Sebelum Production

- [ ] Run semua 3 migrations
- [ ] Verify tables dengan Quick Test Script
- [ ] Test admin kirim notifikasi
- [ ] Test user terima notifikasi
- [ ] Test logout scenario
- [ ] Firebase setup (untuk offline notifications)
- [ ] Test push notifications (FCM)
- [ ] Monitor database logs

---

## Summary Perubahan

### File yang Diperbaiki:

1. **lib/admin/send_notifikasi_page.dart**
   - ❌ OLD: Kirim ke `notification_preference`
   - ✅ NEW: Kirim ke `notifikasi`
   - ✅ Field names fixed: `tipe`, `created_at`, `metadata`
   - ✅ All UKM members: Get dari `ukm_members` table

2. **database/migrations/create_notifikasi_table.sql**
   - ✅ NEW: Proper table structure
   - ✅ RLS policies
   - ✅ Helper functions

### Struktur Notifikasi Baru:

```sql
notifikasi (
    id_notifikasi UUID,
    id_user UUID,          -- User yang terima
    judul TEXT,            -- Judul notifikasi
    pesan TEXT,            -- Isi pesan
    tipe TEXT,             -- info/warning/success/event/announcement
    is_read BOOLEAN,       -- Sudah dibaca?
    created_at TIMESTAMP,
    metadata JSONB         -- Extra data (optional)
)
```

---

## Kontak Support

Jika masih ada masalah setelah follow semua steps:

1. Check logs di console (F12)
2. Check Supabase logs
3. Run Quick Test Script
4. Screenshot error messages
5. Provide error logs dari console

**Status:** ✅ Implementation Complete - Needs Database Migration
**Next Step:** Run migrations di Supabase Dashboard
