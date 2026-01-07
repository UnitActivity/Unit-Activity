-- Migration: Create notifikasi_anonymous table for notifications when app is closed
-- This ensures notifications are saved even when user doesn't open the app

CREATE TABLE IF NOT EXISTS notifikasi_anonymous (
    id_notifikasi_anonymous UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_token TEXT NOT NULL,
    judul TEXT NOT NULL,
    pesan TEXT NOT NULL,
    tipe TEXT DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB,
    CONSTRAINT fk_device_token FOREIGN KEY (device_token) 
        REFERENCES device_tokens(token) ON DELETE CASCADE
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_notifikasi_anonymous_device ON notifikasi_anonymous(device_token);
CREATE INDEX IF NOT EXISTS idx_notifikasi_anonymous_created ON notifikasi_anonymous(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifikasi_anonymous_unread ON notifikasi_anonymous(device_token, is_read) 
    WHERE is_read = FALSE;

-- Enable RLS
ALTER TABLE notifikasi_anonymous ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their device's anonymous notifications
CREATE POLICY "Users can view their device notifications"
    ON notifikasi_anonymous FOR SELECT
    USING (true); -- Anyone can read, filtering done by device_token

-- Policy: System can insert anonymous notifications
CREATE POLICY "System can insert anonymous notifications"
    ON notifikasi_anonymous FOR INSERT
    WITH CHECK (true);

-- Policy: Users can update their device's notifications
CREATE POLICY "Users can update their device notifications"
    ON notifikasi_anonymous FOR UPDATE
    USING (true);

-- Policy: Admin can manage all anonymous notifications
CREATE POLICY "Admin can manage all anonymous notifications"
    ON notifikasi_anonymous FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM admin 
            WHERE id_admin::text = auth.uid()::text 
            AND role = 'admin'
        )
    );

-- Function to migrate anonymous notifications to user notifications on login
CREATE OR REPLACE FUNCTION migrate_anonymous_notifications_to_user(
    p_device_token TEXT,
    p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_migrated_count INTEGER := 0;
BEGIN
    -- Insert anonymous notifications as user notifications
    INSERT INTO notifikasi (id_user, judul, pesan, tipe, is_read, created_at, metadata)
    SELECT 
        p_user_id,
        judul,
        pesan,
        tipe,
        is_read,
        created_at,
        metadata
    FROM notifikasi_anonymous
    WHERE device_token = p_device_token
    AND is_read = FALSE; -- Only migrate unread notifications
    
    GET DIAGNOSTICS v_migrated_count = ROW_COUNT;
    
    -- Delete migrated anonymous notifications
    DELETE FROM notifikasi_anonymous
    WHERE device_token = p_device_token
    AND is_read = FALSE;
    
    RETURN v_migrated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up old read anonymous notifications (auto cleanup)
CREATE OR REPLACE FUNCTION cleanup_old_anonymous_notifications()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    -- Delete read notifications older than 30 days
    DELETE FROM notifikasi_anonymous
    WHERE is_read = TRUE
    AND created_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON TABLE notifikasi_anonymous IS 'Stores notifications for devices when app is closed or user is logged out. Migrated to user notifications on login.';
COMMENT ON COLUMN notifikasi_anonymous.device_token IS 'FCM token of the device';
COMMENT ON COLUMN notifikasi_anonymous.judul IS 'Notification title';
COMMENT ON COLUMN notifikasi_anonymous.pesan IS 'Notification message/body';
COMMENT ON COLUMN notifikasi_anonymous.tipe IS 'Notification type: info, warning, success, event, announcement';
COMMENT ON COLUMN notifikasi_anonymous.is_read IS 'Whether notification has been read';
COMMENT ON COLUMN notifikasi_anonymous.metadata IS 'Additional data for navigation and actions';
COMMENT ON FUNCTION migrate_anonymous_notifications_to_user IS 'Migrates anonymous notifications to user notifications when user logs in';
COMMENT ON FUNCTION cleanup_old_anonymous_notifications IS 'Cleans up old read anonymous notifications to save storage';
