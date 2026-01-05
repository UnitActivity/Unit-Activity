# Setup Database untuk Sistem Notifikasi

## Tabel yang Diperlukan

### 1. Tabel `notifikasi_broadcast`
Tabel untuk notifikasi dari Admin ke semua user.

```sql
CREATE TABLE IF NOT EXISTS notifikasi_broadcast (
    id_notifikasi UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    judul TEXT NOT NULL,
    pesan TEXT,
    tipe VARCHAR(50) DEFAULT 'announcement',
    id_informasi UUID REFERENCES informasi(id_informasi) ON DELETE SET NULL,
    pengirim VARCHAR(100) DEFAULT 'Admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa
CREATE INDEX idx_notifikasi_broadcast_created_at ON notifikasi_broadcast(created_at DESC);
CREATE INDEX idx_notifikasi_broadcast_tipe ON notifikasi_broadcast(tipe);
```

### 2. Tabel `notifikasi_ukm_member`
Tabel untuk notifikasi dari UKM ke member UKM.

```sql
CREATE TABLE IF NOT EXISTS notifikasi_ukm_member (
    id_notifikasi UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_ukm UUID NOT NULL REFERENCES ukm(id_ukm) ON DELETE CASCADE,
    judul TEXT NOT NULL,
    pesan TEXT,
    tipe VARCHAR(50) DEFAULT 'info',
    id_informasi UUID REFERENCES informasi(id_informasi) ON DELETE SET NULL,
    pengirim VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa
CREATE INDEX idx_notifikasi_ukm_member_ukm ON notifikasi_ukm_member(id_ukm);
CREATE INDEX idx_notifikasi_ukm_member_created_at ON notifikasi_ukm_member(created_at DESC);
CREATE INDEX idx_notifikasi_ukm_member_tipe ON notifikasi_ukm_member(tipe);
```

### 3. Update Tabel `notifikasi` (jika belum ada)
Tabel untuk notifikasi spesifik ke user tertentu.

```sql
-- Jika tabel belum ada
CREATE TABLE IF NOT EXISTS notifikasi (
    id_notifikasi UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user UUID REFERENCES users(id_user) ON DELETE CASCADE,
    judul TEXT NOT NULL,
    pesan TEXT,
    tipe VARCHAR(50) DEFAULT 'info',
    target_type VARCHAR(50) DEFAULT 'user', -- 'user' atau 'all_users'
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa
CREATE INDEX idx_notifikasi_user ON notifikasi(id_user);
CREATE INDEX idx_notifikasi_created_at ON notifikasi(created_at DESC);
CREATE INDEX idx_notifikasi_is_read ON notifikasi(is_read);
CREATE INDEX idx_notifikasi_target_type ON notifikasi(target_type);
```

## Trigger untuk Auto-Update updated_at

```sql
-- Function untuk update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger untuk notifikasi_broadcast
DROP TRIGGER IF EXISTS update_notifikasi_broadcast_updated_at ON notifikasi_broadcast;
CREATE TRIGGER update_notifikasi_broadcast_updated_at
    BEFORE UPDATE ON notifikasi_broadcast
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk notifikasi_ukm_member
DROP TRIGGER IF EXISTS update_notifikasi_ukm_member_updated_at ON notifikasi_ukm_member;
CREATE TRIGGER update_notifikasi_ukm_member_updated_at
    BEFORE UPDATE ON notifikasi_ukm_member
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk notifikasi
DROP TRIGGER IF EXISTS update_notifikasi_updated_at ON notifikasi;
CREATE TRIGGER update_notifikasi_updated_at
    BEFORE UPDATE ON notifikasi
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

## Row Level Security (RLS) - Opsional tapi Direkomendasikan

```sql
-- Enable RLS
ALTER TABLE notifikasi_broadcast ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifikasi_ukm_member ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifikasi ENABLE ROW LEVEL SECURITY;

-- Policy untuk notifikasi_broadcast (semua user bisa read)
CREATE POLICY "Semua user bisa membaca notifikasi broadcast"
ON notifikasi_broadcast FOR SELECT
TO authenticated
USING (true);

-- Policy untuk notifikasi_ukm_member (hanya member UKM bisa read)
CREATE POLICY "Member UKM bisa membaca notifikasi UKM"
ON notifikasi_ukm_member FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_halaman_ukm
        WHERE user_halaman_ukm.id_ukm = notifikasi_ukm_member.id_ukm
        AND user_halaman_ukm.id_user = auth.uid()
    )
);

-- Policy untuk notifikasi (user hanya bisa read notifikasi mereka sendiri)
CREATE POLICY "User bisa membaca notifikasi sendiri"
ON notifikasi FOR SELECT
TO authenticated
USING (id_user = auth.uid() OR target_type = 'all_users');

-- Admin bisa insert ke semua tabel
CREATE POLICY "Admin bisa insert notifikasi broadcast"
ON notifikasi_broadcast FOR INSERT
TO authenticated
WITH CHECK (true); -- Add proper admin check here

CREATE POLICY "UKM bisa insert notifikasi untuk member"
ON notifikasi_ukm_member FOR INSERT
TO authenticated
WITH CHECK (true); -- Add proper UKM check here
```

## Cara Menjalankan

1. Buka Supabase Dashboard
2. Pergi ke SQL Editor
3. Copy-paste semua SQL di atas
4. Execute

## Testing

Setelah menjalankan SQL di atas, test dengan:

1. **Test Notifikasi Admin:**
   - Login sebagai Admin
   - Buat informasi baru di halaman Admin > Informasi
   - Login sebagai User
   - Check halaman Notifikasi, seharusnya ada notifikasi baru

2. **Test Notifikasi UKM:**
   - Login sebagai UKM
   - Buat informasi baru di halaman UKM
   - Login sebagai User yang terdaftar di UKM tersebut
   - Check halaman Notifikasi, seharusnya ada notifikasi dari UKM

3. **Test Auto-Refresh:**
   - Buka halaman user (Dashboard, Event, History, dll)
   - Perhatikan icon bell di header
   - Badge merah seharusnya update otomatis setiap 30 detik
   - Atau pull-to-refresh di halaman Notifikasi

## Fitur yang Sudah Diimplementasikan

✅ Notifikasi broadcast dari Admin ke semua user
✅ Notifikasi dari UKM ke member UKM
✅ Auto-refresh notifikasi setiap 30 detik
✅ Pull-to-refresh di halaman Notifikasi
✅ Badge unread count di NotificationBellWidget
✅ Filter notifikasi (Semua, Admin, UKM, Event)
✅ Mark all as read
✅ Notifikasi otomatis saat Admin membuat/edit informasi
✅ Notifikasi otomatis saat UKM membuat informasi

## Catatan

- Notifikasi akan muncul **secara otomatis** di semua halaman user
- Tidak perlu refresh manual
- Badge merah akan hilang setelah notifikasi dibaca
- Notifikasi lama (lebih dari 30 hari) bisa dihapus dengan cron job (opsional)
