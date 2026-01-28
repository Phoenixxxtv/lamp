-- ============================================================================
-- LAMP App - Test Users Setup
-- Run this in Supabase SQL Editor
-- ============================================================================

INSERT INTO invitations (email, name, role, invite_code, expires_at)
VALUES 
  ('admin@lamp.test', 'Admin User', 'admin', 'ADMIN123', NOW() + INTERVAL '30 days'),
  ('chaperone@lamp.test', 'Chaperone User', 'chaperone', 'CHAP123', NOW() + INTERVAL '30 days'),
  ('protege@lamp.test', 'Protege User', 'protege', 'PROT123', NOW() + INTERVAL '30 days')
ON CONFLICT (invite_code) DO UPDATE SET 
  expires_at = EXCLUDED.expires_at;

-- Use these codes in the app:
-- ADMIN123 → admin@lamp.test
-- CHAP123  → chaperone@lamp.test
-- PROT123  → protege@lamp.test
