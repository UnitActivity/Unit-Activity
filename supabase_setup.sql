-- ============================================
-- SUPABASE DATABASE SETUP
-- QR Absensi & User History Implementation
-- ============================================
-- Created: January 8, 2026
-- Version: 1.0.0
-- ============================================

-- ============================================
-- 1. CREATE TABLES (if not exist)
-- ============================================

-- Table: peserta_event (CRITICAL - untuk validasi pendaftaran)
-- Tabel ini mencatat user yang sudah mendaftar ke event
CREATE TABLE IF NOT EXISTS peserta_event (
  id_peserta UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_event UUID NOT NULL,
  id_user UUID NOT NULL,
  status VARCHAR(20) DEFAULT 'terdaftar',
  registered_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT fk_peserta_event_event FOREIGN KEY (id_event) 
    REFERENCES events(id_events) ON DELETE CASCADE,
  CONSTRAINT fk_peserta_event_user FOREIGN KEY (id_user) 
    REFERENCES users(id_user) ON DELETE CASCADE,
  CONSTRAINT unique_peserta_event UNIQUE(id_event, id_user)
);

-- Table: absen_event (untuk mencatat absensi event)
CREATE TABLE IF NOT EXISTS absen_event (
  id_absen UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_event UUID NOT NULL,
  id_user UUID NOT NULL,
  nim INTEGER,
  jam VARCHAR(5),
  status VARCHAR(20) DEFAULT 'hadir',
  hash VARCHAR(255),
  qr_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT fk_absen_event_event FOREIGN KEY (id_event) 
    REFERENCES events(id_events) ON DELETE CASCADE,
  CONSTRAINT fk_absen_event_user FOREIGN KEY (id_user) 
    REFERENCES users(id_user) ON DELETE CASCADE,
  CONSTRAINT unique_absen_event UNIQUE(id_event, id_user)
);

-- Table: absen_pertemuan (untuk mencatat absensi pertemuan UKM)
CREATE TABLE IF NOT EXISTS absen_pertemuan (
  id_absen UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_pertemuan UUID NOT NULL,
  id_user UUID NOT NULL,
  nim INTEGER,
  jam VARCHAR(5),
  status VARCHAR(20) DEFAULT 'hadir',
  hash VARCHAR(255),
  qr_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT fk_absen_pertemuan_meeting FOREIGN KEY (id_pertemuan) 
    REFERENCES pertemuan(id_pertemuan) ON DELETE CASCADE,
  CONSTRAINT fk_absen_pertemuan_user FOREIGN KEY (id_user) 
    REFERENCES users(id_user) ON DELETE CASCADE,
  CONSTRAINT unique_absen_pertemuan UNIQUE(id_pertemuan, id_user)
);

-- ============================================
-- 2. CREATE INDEXES for Performance
-- ============================================

-- Indexes for peserta_event
CREATE INDEX IF NOT EXISTS idx_peserta_event_user 
  ON peserta_event(id_user);
CREATE INDEX IF NOT EXISTS idx_peserta_event_event 
  ON peserta_event(id_event);
CREATE INDEX IF NOT EXISTS idx_peserta_event_status 
  ON peserta_event(status);
CREATE INDEX IF NOT EXISTS idx_peserta_event_registered 
  ON peserta_event(registered_at DESC);

-- Indexes for absen_event
CREATE INDEX IF NOT EXISTS idx_absen_event_user 
  ON absen_event(id_user);
CREATE INDEX IF NOT EXISTS idx_absen_event_event 
  ON absen_event(id_event);
CREATE INDEX IF NOT EXISTS idx_absen_event_created 
  ON absen_event(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_absen_event_status 
  ON absen_event(status);

-- Indexes for absen_pertemuan
CREATE INDEX IF NOT EXISTS idx_absen_pertemuan_user 
  ON absen_pertemuan(id_user);
CREATE INDEX IF NOT EXISTS idx_absen_pertemuan_meeting 
  ON absen_pertemuan(id_pertemuan);
CREATE INDEX IF NOT EXISTS idx_absen_pertemuan_created 
  ON absen_pertemuan(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_absen_pertemuan_status 
  ON absen_pertemuan(status);

-- ============================================
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE peserta_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE absen_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE absen_pertemuan ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. CREATE RLS POLICIES - peserta_event
-- ============================================

-- Allow users to view their own registrations
DROP POLICY IF EXISTS "Users can view own event registrations" ON peserta_event;
CREATE POLICY "Users can view own event registrations"
  ON peserta_event FOR SELECT
  USING (auth.uid() = id_user);

-- Allow users to register for events
DROP POLICY IF EXISTS "Users can register for events" ON peserta_event;
CREATE POLICY "Users can register for events"
  ON peserta_event FOR INSERT
  WITH CHECK (auth.uid() = id_user);

-- Allow admin to view all registrations
DROP POLICY IF EXISTS "Admin can view all event registrations" ON peserta_event;
CREATE POLICY "Admin can view all event registrations"
  ON peserta_event FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id_user = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Allow UKM to view their event registrations
DROP POLICY IF EXISTS "UKM can view their event registrations" ON peserta_event;
CREATE POLICY "UKM can view their event registrations"
  ON peserta_event FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM events e
      INNER JOIN ukm u ON e.id_ukm = u.id_ukm
      INNER JOIN users us ON u.pic_id = us.id_user
      WHERE e.id_events = peserta_event.id_event
      AND us.id_user = auth.uid()
    )
  );

-- ============================================
-- 5. CREATE RLS POLICIES - absen_event
-- ============================================

-- Allow users to view their own attendance
DROP POLICY IF EXISTS "Users can view own event attendance" ON absen_event;
CREATE POLICY "Users can view own event attendance"
  ON absen_event FOR SELECT
  USING (auth.uid() = id_user);

-- Allow users to insert their own attendance
DROP POLICY IF EXISTS "Users can insert own event attendance" ON absen_event;
CREATE POLICY "Users can insert own event attendance"
  ON absen_event FOR INSERT
  WITH CHECK (auth.uid() = id_user);

-- Allow admin to view all attendance
DROP POLICY IF EXISTS "Admin can view all event attendance" ON absen_event;
CREATE POLICY "Admin can view all event attendance"
  ON absen_event FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id_user = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Allow UKM to view their event attendance
DROP POLICY IF EXISTS "UKM can view their event attendance" ON absen_event;
CREATE POLICY "UKM can view their event attendance"
  ON absen_event FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM events e
      INNER JOIN ukm u ON e.id_ukm = u.id_ukm
      INNER JOIN users us ON u.pic_id = us.id_user
      WHERE e.id_events = absen_event.id_event
      AND us.id_user = auth.uid()
    )
  );

-- ============================================
-- 6. CREATE RLS POLICIES - absen_pertemuan
-- ============================================

-- Allow users to view their own pertemuan attendance
DROP POLICY IF EXISTS "Users can view own pertemuan attendance" ON absen_pertemuan;
CREATE POLICY "Users can view own pertemuan attendance"
  ON absen_pertemuan FOR SELECT
  USING (auth.uid() = id_user);

-- Allow users to insert their own pertemuan attendance
DROP POLICY IF EXISTS "Users can insert own pertemuan attendance" ON absen_pertemuan;
CREATE POLICY "Users can insert own pertemuan attendance"
  ON absen_pertemuan FOR INSERT
  WITH CHECK (auth.uid() = id_user);

-- Allow admin to view all pertemuan attendance
DROP POLICY IF EXISTS "Admin can view all pertemuan attendance" ON absen_pertemuan;
CREATE POLICY "Admin can view all pertemuan attendance"
  ON absen_pertemuan FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id_user = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Allow UKM to view their pertemuan attendance
DROP POLICY IF EXISTS "UKM can view their pertemuan attendance" ON absen_pertemuan;
CREATE POLICY "UKM can view their pertemuan attendance"
  ON absen_pertemuan FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pertemuan p
      INNER JOIN ukm u ON p.id_ukm = u.id_ukm
      INNER JOIN users us ON u.pic_id = us.id_user
      WHERE p.id_pertemuan = absen_pertemuan.id_pertemuan
      AND us.id_user = auth.uid()
    )
  );

-- ============================================
-- 7. CREATE FUNCTIONS for Auto-Update Timestamps
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for peserta_event
DROP TRIGGER IF EXISTS update_peserta_event_updated_at ON peserta_event;
CREATE TRIGGER update_peserta_event_updated_at
  BEFORE UPDATE ON peserta_event
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for absen_event
DROP TRIGGER IF EXISTS update_absen_event_updated_at ON absen_event;
CREATE TRIGGER update_absen_event_updated_at
  BEFORE UPDATE ON absen_event
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for absen_pertemuan
DROP TRIGGER IF EXISTS update_absen_pertemuan_updated_at ON absen_pertemuan;
CREATE TRIGGER update_absen_pertemuan_updated_at
  BEFORE UPDATE ON absen_pertemuan
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. CREATE VIEWS for Easy Querying
-- ============================================

-- View: User Event Attendance with Details
CREATE OR REPLACE VIEW view_user_event_attendance AS
SELECT 
  ae.id_absen,
  ae.id_user,
  u.username,
  u.email,
  u.nim,
  ae.id_event,
  e.nama_event,
  e.tanggal_mulai,
  e.tanggal_akhir,
  e.lokasi,
  ukm.nama_ukm,
  ae.jam as waktu_absen,
  ae.status,
  ae.created_at as tanggal_absen
FROM absen_event ae
JOIN users u ON ae.id_user = u.id_user
JOIN events e ON ae.id_event = e.id_events
LEFT JOIN ukm ON e.id_ukm = ukm.id_ukm
ORDER BY ae.created_at DESC;

-- View: User Pertemuan Attendance with Details
CREATE OR REPLACE VIEW view_user_pertemuan_attendance AS
SELECT 
  ap.id_absen,
  ap.id_user,
  u.username,
  u.email,
  u.nim,
  ap.id_pertemuan,
  p.topik,
  p.tanggal,
  p.lokasi,
  ukm.nama_ukm,
  ap.jam as waktu_absen,
  ap.status,
  ap.created_at as tanggal_absen
FROM absen_pertemuan ap
JOIN users u ON ap.id_user = u.id_user
JOIN pertemuan p ON ap.id_pertemuan = p.id_pertemuan
LEFT JOIN ukm ON p.id_ukm = ukm.id_ukm
ORDER BY ap.created_at DESC;

-- ============================================
-- 9. SAMPLE DATA (Optional - for testing)
-- ============================================

-- Uncomment below to insert sample data for testing

/*
-- Sample: Register user to event
INSERT INTO peserta_event (id_event, id_user, status)
SELECT 
  e.id_events,
  u.id_user,
  'terdaftar'
FROM events e
CROSS JOIN users u
WHERE e.nama_event LIKE '%Test%'
AND u.email LIKE '%test%'
LIMIT 1;

-- Sample: Record event attendance
INSERT INTO absen_event (id_event, id_user, jam, status)
SELECT 
  pe.id_event,
  pe.id_user,
  TO_CHAR(NOW(), 'HH24:MI'),
  'hadir'
FROM peserta_event pe
LIMIT 1;
*/

-- ============================================
-- 10. VERIFICATION QUERIES
-- ============================================

-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('peserta_event', 'absen_event', 'absen_pertemuan');

-- Check indexes
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN ('peserta_event', 'absen_event', 'absen_pertemuan');

-- Check RLS policies
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('peserta_event', 'absen_event', 'absen_pertemuan');

-- ============================================
-- 11. GRANT PERMISSIONS
-- ============================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT ON peserta_event TO authenticated;
GRANT SELECT, INSERT ON absen_event TO authenticated;
GRANT SELECT, INSERT ON absen_pertemuan TO authenticated;

-- Grant permissions on views
GRANT SELECT ON view_user_event_attendance TO authenticated;
GRANT SELECT ON view_user_pertemuan_attendance TO authenticated;

-- ============================================
-- END OF SCRIPT
-- ============================================

-- To run this script in Supabase:
-- 1. Go to Supabase Dashboard
-- 2. Navigate to SQL Editor
-- 3. Create new query
-- 4. Paste this script
-- 5. Execute (Run)
-- 6. Verify using verification queries

-- Notes:
-- - Script is idempotent (safe to run multiple times)
-- - Uses IF NOT EXISTS to prevent errors
-- - Drops and recreates policies to ensure updates
-- - All tables have proper indexes for performance
-- - RLS is enabled for security
-- - Includes sample views for easy querying
