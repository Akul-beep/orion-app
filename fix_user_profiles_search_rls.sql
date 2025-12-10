-- ============================================
-- FIX USER_PROFILES RLS FOR SEARCH
-- This allows users to SEARCH/READ all profiles
-- but still only UPDATE/INSERT/DELETE their own
-- ============================================

-- Enable RLS (if not already enabled)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing restrictive policy if it exists
DROP POLICY IF EXISTS "Users can manage own profile" ON user_profiles;

-- Create separate policies for better control:
-- 1. Allow ALL authenticated users to READ all profiles (for search)
DROP POLICY IF EXISTS "Users can read all profiles" ON user_profiles;
CREATE POLICY "Users can read all profiles" ON user_profiles
  FOR SELECT USING (auth.role() = 'authenticated');

-- 2. Users can only INSERT their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. Users can only UPDATE their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- 4. Users can only DELETE their own profile
DROP POLICY IF EXISTS "Users can delete own profile" ON user_profiles;
CREATE POLICY "Users can delete own profile" ON user_profiles
  FOR DELETE USING (auth.uid() = user_id);

-- Verify policies
SELECT 
  policyname,
  cmd as "Command",
  qual as "Policy Condition"
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

