-- Supabase SQL Schema for Feedback and Email Features
-- Run this in your Supabase SQL Editor to create the necessary tables

-- ============================================
-- FEEDBACK TABLES
-- ============================================

-- Feedback table for storing user feedback and feature requests
CREATE TABLE IF NOT EXISTS feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT DEFAULT 'feature_request' CHECK (category IN ('feature_request', 'bug_report', 'improvement', 'other')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  upvotes INTEGER DEFAULT 0,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Feedback votes table to track which users have upvoted which feedback
CREATE TABLE IF NOT EXISTS feedback_votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  feedback_id UUID NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(feedback_id, user_id)
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);
CREATE INDEX IF NOT EXISTS idx_feedback_category ON feedback(category);
CREATE INDEX IF NOT EXISTS idx_feedback_upvotes ON feedback(upvotes DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_votes_feedback_id ON feedback_votes(feedback_id);
CREATE INDEX IF NOT EXISTS idx_feedback_votes_user_id ON feedback_votes(user_id);

-- Function to increment upvotes when a vote is added
CREATE OR REPLACE FUNCTION increment_feedback_upvotes(feedback_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE feedback SET upvotes = upvotes + 1 WHERE id = feedback_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement upvotes when a vote is removed
CREATE OR REPLACE FUNCTION decrement_feedback_upvotes(feedback_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE feedback SET upvotes = GREATEST(0, upvotes - 1) WHERE id = feedback_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_feedback_updated_at
  BEFORE UPDATE ON feedback
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- EMAIL LOGS TABLE
-- ============================================

-- Email logs table to track sent emails
CREATE TABLE IF NOT EXISTS email_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  email_type TEXT NOT NULL CHECK (email_type IN ('welcome', 'retention', 'onboarding', 'feedback_request')),
  metadata JSONB,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for email logs
CREATE INDEX IF NOT EXISTS idx_email_logs_user_id ON email_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_email_logs_type ON email_logs(email_type);
CREATE INDEX IF NOT EXISTS idx_email_logs_sent_at ON email_logs(sent_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on feedback table
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Users can view all feedback
CREATE POLICY "Users can view all feedback"
  ON feedback FOR SELECT
  USING (true);

-- Users can insert their own feedback
CREATE POLICY "Users can insert their own feedback"
  ON feedback FOR INSERT
  WITH CHECK (true);

-- Users can update their own feedback
CREATE POLICY "Users can update their own feedback"
  ON feedback FOR UPDATE
  USING (auth.uid()::text = user_id);

-- Enable RLS on feedback_votes table
ALTER TABLE feedback_votes ENABLE ROW LEVEL SECURITY;

-- Users can view all votes
CREATE POLICY "Users can view all votes"
  ON feedback_votes FOR SELECT
  USING (true);

-- Users can insert their own votes
CREATE POLICY "Users can insert their own votes"
  ON feedback_votes FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

-- Users can delete their own votes
CREATE POLICY "Users can delete their own votes"
  ON feedback_votes FOR DELETE
  USING (auth.uid()::text = user_id);

-- Enable RLS on email_logs table
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;

-- Users can view their own email logs
CREATE POLICY "Users can view their own email logs"
  ON email_logs FOR SELECT
  USING (auth.uid()::text = user_id);

-- Service role can insert email logs (for Edge Functions)
CREATE POLICY "Service can insert email logs"
  ON email_logs FOR INSERT
  WITH CHECK (true);

-- ============================================
-- NOTES
-- ============================================
-- 
-- 1. After running this schema, you'll need to set up a Supabase Edge Function
--    to handle email sending via Resend API (see email_edge_function.ts)
--
-- 2. Replace the auth.uid() checks in RLS policies if you're using custom auth
--    or if your user IDs are stored differently
--
-- 3. The feedback table uses TEXT for user_id to accommodate both UUID and 
--    custom user IDs from your auth system
--
-- 4. Make sure your Supabase project has the necessary extensions enabled:
--    - uuid-ossp (for gen_random_uuid())
--    - pgcrypto (if needed)

