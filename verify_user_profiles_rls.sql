-- ============================================
-- VERIFY USER_PROFILES RLS POLICIES
-- Run this to check if RLS is set up correctly
-- ============================================

-- Check if RLS is enabled
SELECT 
  tablename,
  rowsecurity as "RLS Enabled"
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'user_profiles';

-- Check existing policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'user_profiles';

-- ============================================
-- If no policies show up, run this to create them:
-- ============================================

-- Enable RLS (if not already enabled)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create the policy
DROP POLICY IF EXISTS "Users can manage own profile" ON user_profiles;
CREATE POLICY "Users can manage own profile" ON user_profiles
  FOR ALL USING (auth.uid() = user_id);

-- Verify again
SELECT 
  policyname,
  cmd as "Command",
  qual as "Policy Condition"
FROM pg_policies 
WHERE tablename = 'user_profiles';

