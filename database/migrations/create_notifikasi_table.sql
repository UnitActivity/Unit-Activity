-- Migration: Create notifikasi table for user notifications
-- This table stores all notifications for users (from admin, UKM, system)

-- Drop existing table if needed (careful in production!)
-- DROP TABLE IF EXISTS notifikasi CASCADE;

CREATE TABLE IF NOT EXISTS notifikasi (
    id_notifikasi UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_user UUID NOT NULL REFERENCES users(id_user) ON DELETE CASCADE,
    judul TEXT NOT NULL,
    pesan TEXT NOT NULL,
    tipe TEXT DEFAULT 'info' CHECK (tipe IN ('info', 'warning', 'success', 'event', 'announcement')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB,
    
    -- Optional: Link to specific content
    id_events UUID REFERENCES events(id_events) ON DELETE SET NULL,
    id_informasi UUID REFERENCES informasi(id_informasi) ON DELETE SET NULL,
    id_ukm UUID REFERENCES ukm(id_ukm) ON DELETE SET NULL
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_notifikasi_user ON notifikasi(id_user);
CREATE INDEX IF NOT EXISTS idx_notifikasi_created ON notifikasi(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifikasi_unread ON notifikasi(id_user, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifikasi_tipe ON notifikasi(tipe);

-- Enable RLS
ALTER TABLE notifikasi ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own notifications
CREATE POLICY "Users can view their own notifications"
    ON notifikasi FOR SELECT
    USING (id_user::text = auth.uid()::text);

-- Policy: System can insert notifications (for admin/system notifications)
CREATE POLICY "System can insert notifications"
    ON notifikasi FOR INSERT
    WITH CHECK (true);

-- Policy: Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their own notifications"
    ON notifikasi FOR UPDATE
    USING (id_user::text = auth.uid()::text)
    WITH CHECK (id_user::text = auth.uid()::text);

-- Policy: Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
    ON notifikasi FOR DELETE
    USING (id_user::text = auth.uid()::text);

-- Policy: Admin can manage all notifications
CREATE POLICY "Admin can manage all notifications"
    ON notifikasi FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM admin 
            WHERE id_admin::text = auth.uid()::text 
            AND role = 'admin'
        )
    );

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_notifikasi_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamp on notifikasi update
DROP TRIGGER IF EXISTS notifikasi_updated_at ON notifikasi;
CREATE TRIGGER notifikasi_updated_at
    BEFORE UPDATE ON notifikasi
    FOR EACH ROW
    EXECUTE FUNCTION update_notifikasi_timestamp();

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE notifikasi
    SET is_read = TRUE,
        updated_at = NOW()
    WHERE id_notifikasi = p_notification_id
    AND id_user::text = auth.uid()::text;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE notifikasi
    SET is_read = TRUE,
        updated_at = NOW()
    WHERE id_user::text = auth.uid()::text
    AND is_read = FALSE;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete old read notifications (cleanup)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    -- Delete read notifications older than 90 days
    DELETE FROM notifikasi
    WHERE is_read = TRUE
    AND created_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON TABLE notifikasi IS 'Stores all notifications for users from admin, UKM, and system';
COMMENT ON COLUMN notifikasi.id_notifikasi IS 'Unique notification identifier';
COMMENT ON COLUMN notifikasi.id_user IS 'User who receives this notification';
COMMENT ON COLUMN notifikasi.judul IS 'Notification title';
COMMENT ON COLUMN notifikasi.pesan IS 'Notification message/body';
COMMENT ON COLUMN notifikasi.tipe IS 'Notification type: info, warning, success, event, announcement';
COMMENT ON COLUMN notifikasi.is_read IS 'Whether notification has been read by user';
COMMENT ON COLUMN notifikasi.metadata IS 'Additional data for navigation and actions (JSON)';
COMMENT ON FUNCTION mark_notification_read IS 'Mark a single notification as read';
COMMENT ON FUNCTION mark_all_notifications_read IS 'Mark all user notifications as read';
COMMENT ON FUNCTION cleanup_old_notifications IS 'Delete old read notifications to save storage';
