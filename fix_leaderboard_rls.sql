-- ============================================
-- FIX LEADERBOARD RLS FOR REAL USERS
-- This allows all authenticated users to read the leaderboard
-- ============================================

-- Verify leaderboard table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'leaderboard'
);

-- Enable RLS (if not already enabled)
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read all leaderboard" ON leaderboard;
DROP POLICY IF EXISTS "Users can update own leaderboard" ON leaderboard;
DROP POLICY IF EXISTS "Users can insert own leaderboard" ON leaderboard;

-- Create policies:
-- 1. EVERYONE can READ the leaderboard (public data - no login required)
CREATE POLICY "Users can read all leaderboard" ON leaderboard
  FOR SELECT USING (true);

-- 2. Users can INSERT their own leaderboard entry
CREATE POLICY "Users can insert own leaderboard" ON leaderboard
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. Users can UPDATE their own leaderboard entry
CREATE POLICY "Users can update own leaderboard" ON leaderboard
  FOR UPDATE USING (auth.uid() = user_id);

-- Verify the policies
SELECT 
  policyname,
  cmd as "Command",
  qual as "Policy Condition"
FROM pg_policies 
WHERE tablename = 'leaderboard'
ORDER BY policyname;

-- Check current leaderboard entries
SELECT 
  user_id,
  display_name,
  xp,
  level,
  streak,
  badges,
  updated_at
FROM leaderboard
ORDER BY xp DESC
LIMIT 20;

