-- ============================================
-- FIX PORTFOLIO PERSISTENCE
-- Ensure portfolio table RLS allows proper access
-- ============================================

-- Verify portfolio table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'portfolio'
);

-- Enable RLS (if not already enabled)
ALTER TABLE portfolio ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can manage own portfolio" ON portfolio;

-- Create policy that allows users to manage their own portfolio
-- This allows INSERT, UPDATE, SELECT, DELETE for own portfolio
CREATE POLICY "Users can manage own portfolio" ON portfolio
  FOR ALL USING (auth.uid() = user_id);

-- Verify the policy
SELECT 
  policyname,
  cmd as "Command",
  qual as "Policy Condition"
FROM pg_policies 
WHERE tablename = 'portfolio';

-- Check if there are any portfolios in the database
SELECT 
  user_id,
  updated_at,
  jsonb_array_length(data->'positions') as position_count,
  (data->>'cashBalance')::numeric as cash_balance,
  (data->>'totalValue')::numeric as total_value
FROM portfolio
ORDER BY updated_at DESC
LIMIT 10;

