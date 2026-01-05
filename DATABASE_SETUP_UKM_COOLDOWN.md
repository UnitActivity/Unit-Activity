# Database Setup - UKM Join/Unjoin with Cooldown

## Overview
Setup untuk sistem join/unjoin UKM dengan cooldown 1 periode perkuliahan.

## Prerequisites
- Tabel `periode` sudah ada dengan kolom `id_periode`, `nama_periode`, `status`
- Tabel `ukm` sudah ada
- Tabel `user` sudah ada dengan auth dari Supabase

## 1. Create user_ukm_history Table

Tabel ini mencatat history join/unjoin user dari UKM untuk tracking cooldown.

```sql
-- Create user_ukm_history table
CREATE TABLE IF NOT EXISTS user_ukm_history (
  id BIGSERIAL PRIMARY KEY,
  id_ukm TEXT NOT NULL REFERENCES ukm(id) ON DELETE CASCADE,
  id_user UUID NOT NULL,
  id_periode TEXT REFERENCES periode(id_periode) ON DELETE SET NULL,
  action TEXT NOT NULL CHECK (action IN ('join', 'unjoin')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  unjoined_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better query performance
CREATE INDEX idx_user_ukm_history_user ON user_ukm_history(id_user);
CREATE INDEX idx_user_ukm_history_ukm ON user_ukm_history(id_ukm);
CREATE INDEX idx_user_ukm_history_user_ukm ON user_ukm_history(id_user, id_ukm);
CREATE INDEX idx_user_ukm_history_action ON user_ukm_history(action);
CREATE INDEX idx_user_ukm_history_periode ON user_ukm_history(id_periode);
CREATE INDEX idx_user_ukm_history_unjoined ON user_ukm_history(unjoined_at);

-- Add comment
COMMENT ON TABLE user_ukm_history IS 'History join/unjoin UKM untuk tracking cooldown periode';
COMMENT ON COLUMN user_ukm_history.action IS 'Action: join atau unjoin';
COMMENT ON COLUMN user_ukm_history.id_periode IS 'Periode saat join/unjoin terjadi';
COMMENT ON COLUMN user_ukm_history.unjoined_at IS 'Timestamp saat user unjoin dari UKM';
```

## 2. Update user_halaman_ukm Table

Tambahkan kolom untuk tracking periode join dan status.

```sql
-- Add new columns to user_halaman_ukm if not exists
ALTER TABLE user_halaman_ukm 
  ADD COLUMN IF NOT EXISTS id_periode TEXT REFERENCES periode(id_periode) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' CHECK (status IN ('active', 'left'));

-- Add index
CREATE INDEX IF NOT EXISTS idx_user_halaman_ukm_periode ON user_halaman_ukm(id_periode);
CREATE INDEX IF NOT EXISTS idx_user_halaman_ukm_status ON user_halaman_ukm(status);

-- Add comment
COMMENT ON COLUMN user_halaman_ukm.id_periode IS 'Periode saat user join UKM';
COMMENT ON COLUMN user_halaman_ukm.status IS 'Status: active (masih terdaftar) atau left (sudah keluar)';
```

## 3. Enable Row Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE user_ukm_history ENABLE ROW LEVEL SECURITY;

-- Policy untuk read - user bisa lihat history mereka sendiri
CREATE POLICY "Users can view their own history"
  ON user_ukm_history
  FOR SELECT
  USING (auth.uid() = id_user);

-- Policy untuk insert - user bisa insert history mereka sendiri
CREATE POLICY "Users can insert their own history"
  ON user_ukm_history
  FOR INSERT
  WITH CHECK (auth.uid() = id_user);

-- Policy untuk admin - admin bisa lihat semua
CREATE POLICY "Admins can view all history"
  ON user_ukm_history
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );
```

## 4. Create Helper Function - Check Cooldown

Function untuk check apakah user masih dalam cooldown periode.

```sql
-- Function untuk check cooldown
CREATE OR REPLACE FUNCTION check_ukm_cooldown(
  p_user_id UUID,
  p_ukm_id TEXT
)
RETURNS TABLE(
  has_cooldown BOOLEAN,
  last_unjoin_periode TEXT,
  current_periode TEXT
) AS $$
DECLARE
  v_last_unjoin RECORD;
  v_current_periode RECORD;
BEGIN
  -- Get last unjoin record
  SELECT h.id_periode, p.nama_periode, h.unjoined_at
  INTO v_last_unjoin
  FROM user_ukm_history h
  LEFT JOIN periode p ON h.id_periode = p.id_periode
  WHERE h.id_user = p_user_id
    AND h.id_ukm = p_ukm_id
    AND h.action = 'unjoin'
  ORDER BY h.unjoined_at DESC
  LIMIT 1;

  -- Get current active periode
  SELECT id_periode, nama_periode
  INTO v_current_periode
  FROM periode
  WHERE status = 'Aktif'
  ORDER BY tahun_mulai DESC
  LIMIT 1;

  -- If no unjoin history, no cooldown
  IF v_last_unjoin IS NULL THEN
    RETURN QUERY SELECT FALSE, NULL::TEXT, v_current_periode.nama_periode;
    RETURN;
  END IF;

  -- If no current periode, no cooldown
  IF v_current_periode IS NULL THEN
    RETURN QUERY SELECT FALSE, v_last_unjoin.nama_periode, NULL::TEXT;
    RETURN;
  END IF;

  -- Check if unjoin was in current periode
  IF v_last_unjoin.id_periode = v_current_periode.id_periode THEN
    RETURN QUERY SELECT TRUE, v_last_unjoin.nama_periode, v_current_periode.nama_periode;
  ELSE
    RETURN QUERY SELECT FALSE, v_last_unjoin.nama_periode, v_current_periode.nama_periode;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment
COMMENT ON FUNCTION check_ukm_cooldown IS 'Check apakah user masih dalam cooldown periode untuk join UKM';
```

## 5. Create Trigger - Auto Insert History on Join

Trigger untuk otomatis insert ke history saat user join UKM.

```sql
-- Function untuk auto insert join history
CREATE OR REPLACE FUNCTION auto_insert_join_history()
RETURNS TRIGGER AS $$
DECLARE
  v_current_periode TEXT;
BEGIN
  -- Get current active periode
  SELECT id_periode INTO v_current_periode
  FROM periode
  WHERE status = 'Aktif'
  ORDER BY tahun_mulai DESC
  LIMIT 1;

  -- Insert to history
  INSERT INTO user_ukm_history (
    id_ukm,
    id_user,
    id_periode,
    action,
    joined_at
  ) VALUES (
    NEW.id_ukm,
    NEW.id_user,
    COALESCE(NEW.id_periode, v_current_periode),
    'join',
    NOW()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_auto_join_history ON user_halaman_ukm;
CREATE TRIGGER trigger_auto_join_history
  AFTER INSERT ON user_halaman_ukm
  FOR EACH ROW
  EXECUTE FUNCTION auto_insert_join_history();

-- Add comment
COMMENT ON FUNCTION auto_insert_join_history IS 'Auto insert join history saat user join UKM';
```

## 6. Sample Queries

### Check cooldown untuk user tertentu
```sql
SELECT * FROM check_ukm_cooldown(
  '<user_uuid>'::UUID,
  '<ukm_id>'
);
```

### Get history user
```sql
SELECT 
  h.*,
  u.nama AS ukm_name,
  p.nama_periode
FROM user_ukm_history h
LEFT JOIN ukm u ON h.id_ukm = u.id
LEFT JOIN periode p ON h.id_periode = p.id_periode
WHERE h.id_user = '<user_uuid>'
ORDER BY h.created_at DESC;
```

### Get active UKM members
```sql
SELECT 
  u.id_user,
  u.id_ukm,
  ukm.nama AS ukm_name,
  p.nama_periode,
  u.status
FROM user_halaman_ukm u
LEFT JOIN ukm ON u.id_ukm = ukm.id
LEFT JOIN periode p ON u.id_periode = p.id_periode
WHERE u.status = 'active';
```

## 7. Testing

### Test 1: Join UKM
```sql
-- User join UKM
INSERT INTO user_halaman_ukm (id_ukm, id_user, id_periode, status)
VALUES ('<ukm_id>', '<user_uuid>', '<periode_id>', 'active');

-- Verify history created
SELECT * FROM user_ukm_history WHERE id_user = '<user_uuid>' ORDER BY created_at DESC LIMIT 1;
```

### Test 2: Unjoin UKM
```sql
-- User unjoin
DELETE FROM user_halaman_ukm 
WHERE id_ukm = '<ukm_id>' AND id_user = '<user_uuid>';

-- Insert unjoin history manually (or via app)
INSERT INTO user_ukm_history (id_ukm, id_user, id_periode, action, unjoined_at)
VALUES ('<ukm_id>', '<user_uuid>', '<current_periode_id>', 'unjoin', NOW());
```

### Test 3: Check Cooldown
```sql
-- Check apakah user bisa join lagi
SELECT * FROM check_ukm_cooldown('<user_uuid>'::UUID, '<ukm_id>');

-- Jika has_cooldown = true, user tidak bisa join di periode yang sama
-- Jika has_cooldown = false, user bisa join
```

## 8. Notes

1. **Cooldown Logic**: User yang unjoin di periode X tidak bisa join lagi di periode X yang sama, harus tunggu periode berikutnya.

2. **Multiple Periods**: Jika user unjoin di periode "Semester 1 2024" dan sekarang sudah "Semester 2 2024", maka cooldown sudah habis dan user bisa join lagi.

3. **History Tracking**: Semua join/unjoin dicatat di `user_ukm_history` untuk audit trail.

4. **Active Status**: Status 'active' di `user_halaman_ukm` menandakan user masih terdaftar, 'left' artinya sudah keluar.

5. **Automatic History**: Saat user join (insert ke `user_halaman_ukm`), otomatis terinsert history dengan action='join' via trigger.

6. **Manual Unjoin History**: Saat unjoin, aplikasi harus manual insert ke `user_ukm_history` dengan action='unjoin' karena record di `user_halaman_ukm` akan di-delete.

## Troubleshooting

### Error: "duplicate key value violates unique constraint"
- User sudah terdaftar di UKM tersebut
- Cek: `SELECT * FROM user_halaman_ukm WHERE id_user = '<uuid>' AND id_ukm = '<ukm_id>' AND status = 'active'`

### Cooldown tidak berfungsi
- Pastikan `id_periode` terisi saat join/unjoin
- Cek current periode: `SELECT * FROM periode WHERE status = 'Aktif'`
- Cek history: `SELECT * FROM user_ukm_history WHERE id_user = '<uuid>' AND id_ukm = '<ukm_id>' ORDER BY created_at DESC`

### User tidak bisa join padahal cooldown sudah habis
- Pastikan periode sudah berubah (status periode lama = 'Tidak Aktif', periode baru = 'Aktif')
- Test function: `SELECT * FROM check_ukm_cooldown('<uuid>'::UUID, '<ukm_id>')`
