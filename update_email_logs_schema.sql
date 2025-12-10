-- ============================================
-- UPDATE EMAIL_LOGS TABLE FOR NEW EMAIL TYPES
-- Run this in Supabase SQL Editor
-- ============================================

-- Update email_logs table to support all new email types
ALTER TABLE email_logs 
DROP CONSTRAINT IF EXISTS email_logs_email_type_check;

ALTER TABLE email_logs
ADD CONSTRAINT email_logs_email_type_check 
CHECK (email_type IN (
  'welcome',
  'retention',
  'onboarding',
  'feedback_request',
  'portfolio_update',
  'leaderboard_update',
  'weekly_summary',
  'streak_at_risk',
  'streak_lost',
  'streak_milestone',
  'achievement_unlocked',
  'level_up',
  'market_update',
  'daily_reminder',
  'friend_activity'
));

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_email_logs_user_type_date 
ON email_logs(user_id, email_type, sent_at DESC);
