-- ============================================
-- ADD PORTFOLIO_VALUE COLUMN TO LEADERBOARD
-- Run this in Supabase SQL Editor if the column doesn't exist
-- ============================================

-- Add portfolio_value column if it doesn't exist
ALTER TABLE leaderboard 
ADD COLUMN IF NOT EXISTS portfolio_value NUMERIC(12, 2) DEFAULT 0;

-- Create index for portfolio value sorting
CREATE INDEX IF NOT EXISTS idx_leaderboard_portfolio_value ON leaderboard(portfolio_value DESC);

-- Update existing entries to have portfolio value from their portfolio data
-- This will set portfolio_value to 0 for existing entries (they'll update on next leaderboard update)
UPDATE leaderboard 
SET portfolio_value = 0 
WHERE portfolio_value IS NULL;

-- Make sure the column is NOT NULL
ALTER TABLE leaderboard 
ALTER COLUMN portfolio_value SET DEFAULT 0,
ALTER COLUMN portfolio_value SET NOT NULL;

-- ============================================
-- DONE! Portfolio value leaderboard is ready
-- ============================================

