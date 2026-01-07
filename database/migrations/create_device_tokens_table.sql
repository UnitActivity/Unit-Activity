-- Migration: Create device_tokens table for FCM push notifications
-- This allows users to receive notifications even after logout

CREATE TABLE IF NOT EXISTS device_tokens (
    token TEXT PRIMARY KEY,
    id_user UUID REFERENCES users(id_user) ON DELETE SET NULL,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster lookups by user
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(id_user);

-- Index for faster lookups by platform
CREATE INDEX IF NOT EXISTS idx_device_tokens_platform ON device_tokens(platform);

-- Enable RLS
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own tokens
CREATE POLICY "Users can view their own device tokens"
    ON device_tokens FOR SELECT
    USING (id_user = auth.uid() OR id_user IS NULL);

-- Policy: Anyone can insert tokens (for anonymous notifications)
CREATE POLICY "Anyone can insert device tokens"
    ON device_tokens FOR INSERT
    WITH CHECK (true);

-- Policy: Users can update their own tokens
CREATE POLICY "Users can update their own device tokens"
    ON device_tokens FOR UPDATE
    USING (id_user = auth.uid() OR id_user IS NULL)
    WITH CHECK (id_user = auth.uid() OR id_user IS NULL);

-- Policy: Users can delete their own tokens
CREATE POLICY "Users can delete their own device tokens"
    ON device_tokens FOR DELETE
    USING (id_user = auth.uid());

-- Policy: Admin can manage all tokens
CREATE POLICY "Admin can manage all device tokens"
    ON device_tokens FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM admin 
            WHERE id_admin::text = auth.uid()::text 
            AND role = 'admin'
        )
    );

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_device_token_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamp on device_tokens update
DROP TRIGGER IF EXISTS device_tokens_updated_at ON device_tokens;
CREATE TRIGGER device_tokens_updated_at
    BEFORE UPDATE ON device_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_device_token_timestamp();

-- Comments
COMMENT ON TABLE device_tokens IS 'Stores FCM tokens for push notifications. Tokens persist even after user logout to allow anonymous notifications.';
COMMENT ON COLUMN device_tokens.token IS 'FCM registration token from Firebase';
COMMENT ON COLUMN device_tokens.id_user IS 'Optional user ID. NULL for logged out users who still want to receive broadcast notifications.';
COMMENT ON COLUMN device_tokens.platform IS 'Device platform: android, ios, or web';
