-- ============================================
-- REFERRALS TABLE
-- Add this to your Supabase SQL Editor
-- ============================================

-- Referrals table for tracking and rewards
CREATE TABLE IF NOT EXISTS referrals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_code TEXT NOT NULL,
  referred_user_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  rewards_awarded BOOLEAN DEFAULT false,
  xp_awarded INTEGER DEFAULT 0,
  money_awarded NUMERIC(10, 2) DEFAULT 0
);

-- Enable RLS
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DO $$ 
BEGIN
  -- Users can view their own referrals (as referrer or referee)
  -- Note: Since we use referral_code instead of referrer_user_id, we need to allow broader access
  DROP POLICY IF EXISTS "Users can view own referrals" ON referrals;
  CREATE POLICY "Users can view own referrals" ON referrals
    FOR SELECT USING (
      referred_user_id = auth.uid()::text
      OR referred_user_id::text = auth.uid()::text
    );

  -- System can insert referrals (for signup tracking)
  DROP POLICY IF EXISTS "System can insert referrals" ON referrals;
  CREATE POLICY "System can insert referrals" ON referrals
    FOR INSERT WITH CHECK (true);
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_referrals_referral_code ON referrals(referral_code);
CREATE INDEX IF NOT EXISTS idx_referrals_referred_user_id ON referrals(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_created_at ON referrals(created_at);

