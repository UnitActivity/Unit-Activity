# Database Migrations - Push Notifications

## Deskripsi

Migration ini menambahkan fitur push notification yang dapat bekerja bahkan ketika:
- User logout
- App tertutup/terminated
- App di background

## File Migration

**URUTAN PENTING:** Jalankan migrations dalam urutan berikut:

1. **create_notifikasi_table.sql** - Tabel utama notifikasi user (JALANKAN PERTAMA)
2. **create_device_tokens_table.sql** - Tabel untuk menyimpan FCM tokens
3. **create_notifikasi_anonymous_table.sql** - Tabel untuk notifikasi anonymous (ketika app tertutup)

## Cara Menjalankan Migration

### Opsi 1: Melalui Supabase Dashboard (RECOMMENDED)

1. Login ke [Supabase Dashboard](https://supabase.com/dashboard)
2. Pilih project Anda
3. Buka **SQL Editor**
4. Buat Query baru
5. **PERTAMA:** Copy-paste isi file `create_notifikasi_table.sql` → Klik **Run**
6. **KEDUA:** Copy-paste isi file `create_device_tokens_table.sql` → Klik **Run**
7. **KETIGA:** Copy-paste isi file `create_notifikasi_anonymous_table.sql` → Klik **Run**

**Verifikasi:**
```sql
-- Check semua tabel ter-create
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('notifikasi', 'device_tokens', 'notifikasi_anonymous');
-- Harus return 3 rows
```

### Opsi 2: Melalui Supabase CLI

```bash
# Install Supabase CLI jika belum
npm install -g supabase

# Login
supabase login

# Link ke project
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations
supabase db push

# Atau run manual
psql -h YOUR_DB_HOST -U postgres -d postgres -f create_device_tokens_table.sql
psql -h YOUR_DB_HOST -U postgres -d postgres -f create_notifikasi_anonymous_table.sql
```

## Struktur Database

### Tabel `device_tokens`

Menyimpan FCM tokens dari semua device yang menginstall app.

| Column | Type | Description |
|--------|------|-------------|
| token | TEXT (PK) | FCM registration token |
| id_user | UUID (FK) | User ID (nullable untuk anonymous) |
| platform | TEXT | android, ios, atau web |
| created_at | TIMESTAMP | Waktu token dibuat |
| updated_at | TIMESTAMP | Waktu token terakhir diupdate |

### Tabel `notifikasi_anonymous`

Menyimpan notifikasi yang diterima saat app tertutup atau user logout.

| Column | Type | Description |
|--------|------|-------------|
| id_notifikasi_anonymous | UUID (PK) | ID notifikasi |
| device_token | TEXT (FK) | FCM token device |
| judul | TEXT | Judul notifikasi |
| pesan | TEXT | Isi notifikasi |
| tipe | TEXT | info/warning/success/event/announcement |
| is_read | BOOLEAN | Status dibaca |
| created_at | TIMESTAMP | Waktu notifikasi dibuat |
| metadata | JSONB | Data tambahan (JSON) |

## Fungsi Database

### `migrate_anonymous_notifications_to_user(p_device_token, p_user_id)`

Dipanggil otomatis saat user login. Memindahkan notifikasi anonymous ke notifikasi user.

**Return:** Jumlah notifikasi yang berhasil dimigrate

### `cleanup_old_anonymous_notifications()`

Membersihkan notifikasi yang sudah dibaca lebih dari 30 hari untuk menghemat storage.

**Return:** Jumlah notifikasi yang dihapus

## Testing

### 1. Test Device Token Registration

```sql
-- Check if device tokens are being saved
SELECT * FROM device_tokens ORDER BY created_at DESC LIMIT 10;
```

### 2. Test Anonymous Notifications

```sql
-- Check anonymous notifications
SELECT 
    na.*,
    dt.platform,
    dt.id_user
FROM notifikasi_anonymous na
JOIN device_tokens dt ON na.device_token = dt.token
ORDER BY na.created_at DESC;
```

### 3. Test Notification Migration

```sql
-- Before login: Check anonymous notifications
SELECT COUNT(*) FROM notifikasi_anonymous WHERE device_token = 'YOUR_FCM_TOKEN';

-- After login: Check user notifications
SELECT COUNT(*) FROM notifikasi WHERE id_user = 'USER_ID';

-- Test migration function manually
SELECT migrate_anonymous_notifications_to_user('YOUR_FCM_TOKEN', 'USER_ID'::UUID);
```

### 4. Test Cleanup Function

```sql
-- Mark some notifications as read
UPDATE notifikasi_anonymous SET is_read = true WHERE id_notifikasi_anonymous = 'SOME_ID';

-- Run cleanup (won't delete if < 30 days old)
SELECT cleanup_old_anonymous_notifications();
```

## Troubleshooting

### Error: relation "device_tokens" does not exist

Migration belum dijalankan. Jalankan `create_device_tokens_table.sql` terlebih dahulu.

### Error: foreign key constraint

Jalankan migration dengan urutan yang benar:
1. `create_device_tokens_table.sql` (parent table)
2. `create_notifikasi_anonymous_table.sql` (child table)

### Error: permission denied

Pastikan user database memiliki permission yang cukup. Gunakan user `postgres` untuk menjalankan migration.

### Notifications tidak tersimpan saat app tertutup

1. Pastikan Firebase Cloud Messaging sudah dikonfigurasi dengan benar
2. Check logs di Supabase Dashboard > Logs
3. Pastikan background handler berfungsi (check console logs)
4. Verify FCM token tersimpan di SharedPreferences

## Rollback

Jika perlu rollback migration:

```sql
-- Drop tables (WARNING: This will delete all data!)
DROP TABLE IF EXISTS notifikasi_anonymous CASCADE;
DROP TABLE IF EXISTS device_tokens CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS migrate_anonymous_notifications_to_user;
DROP FUNCTION IF EXISTS cleanup_old_anonymous_notifications;
DROP FUNCTION IF EXISTS update_device_token_timestamp;
```

## Monitoring

### Statistik Notifikasi

```sql
-- Total device tokens
SELECT 
    platform,
    COUNT(*) as total_devices,
    COUNT(id_user) as logged_in_devices,
    COUNT(*) - COUNT(id_user) as anonymous_devices
FROM device_tokens
GROUP BY platform;

-- Notifikasi yang belum dibaca
SELECT 
    COUNT(*) as unread_anonymous,
    COUNT(DISTINCT device_token) as unique_devices
FROM notifikasi_anonymous
WHERE is_read = false;

-- Notifikasi per hari (7 hari terakhir)
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_notifications
FROM notifikasi_anonymous
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

## Security

- **RLS (Row Level Security)** diaktifkan di kedua tabel
- Anonymous users dapat insert dan read notifikasi mereka sendiri
- Admin dapat manage semua notifikasi
- Device tokens persist setelah logout untuk broadcast notifications
- Migration function menggunakan SECURITY DEFINER untuk bypass RLS

## Maintenance

Jadwalkan cleanup function untuk berjalan otomatis (gunakan Supabase cron jobs atau pg_cron):

```sql
-- Setup cron untuk cleanup setiap hari jam 2 pagi
-- (Perlu extension pg_cron)
SELECT cron.schedule(
    'cleanup-old-anonymous-notifications',
    '0 2 * * *',
    'SELECT cleanup_old_anonymous_notifications();'
);
```
