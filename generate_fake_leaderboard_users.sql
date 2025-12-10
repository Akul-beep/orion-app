-- Generate 50 fake users for leaderboard with realistic data
-- Based on exponential level system: Level = floor(sqrt(XP / 10)) + 1
-- Portfolio values correlate with levels but have realistic variation
-- Filters out $10,000 (starting amount) users - only shows users who have traded

-- First, ensure portfolio_value column exists in leaderboard table
ALTER TABLE leaderboard ADD COLUMN IF NOT EXISTS portfolio_value NUMERIC DEFAULT 0;

-- IMPORTANT: This script requires either:
-- 1. Admin access to create auth users (the script will try to create them automatically), OR
-- 2. Temporarily disable foreign key constraint if you don't have admin access:
--    ALTER TABLE leaderboard DROP CONSTRAINT IF EXISTS leaderboard_user_id_fkey;
--    (Re-enable after: ALTER TABLE leaderboard ADD CONSTRAINT leaderboard_user_id_fkey 
--     FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;)
-- 3. If you get permission errors on auth.users insert, comment out that section and
--    ensure the foreign key constraint is disabled first.

-- Generate fake users with realistic data
WITH fake_user_ids AS (
  SELECT gen_random_uuid() AS user_id, generate_series(1, 50) AS user_num
),
fake_users AS (
  SELECT 
    fui.user_id,
    fui.user_num,
    (ARRAY[
      'Arjun', 'Priya', 'Rohan', 'Ananya', 'Karan', 'Sneha', 'Vikram', 'Meera',
      'Aditya', 'Kavya', 'Rahul', 'Divya', 'Siddharth', 'Isha', 'Aryan', 'Neha',
      'Krishna', 'Pooja', 'Aman', 'Shreya', 'Ravi', 'Anjali', 'Nikhil', 'Tanvi',
      'Varun', 'Sakshi', 'Harsh', 'Riya', 'Yash', 'Aishwarya', 'Dev', 'Kriti',
      'Akash', 'Swati', 'Rishabh', 'Nisha', 'Sahil', 'Pallavi', 'Mohit', 'Deepika',
      'ByteMaster', 'CodeNinja', 'DataWizard', 'AlgoKing', 'TradeBot', 'StockGuru',
      'CryptoWhiz', 'MarketPro', 'QuantGenius', 'FinanceAI'
    ])[((fui.user_num - 1) % 50) + 1] AS display_name
  FROM fake_user_ids fui
),
level_data AS (
  SELECT 
    user_id,
    user_num,
    display_name,
    -- Generate realistic levels (most users in 5-20 range, top few higher)
    CASE 
      WHEN user_num <= 3 THEN 22 + (user_num * 1)  -- Top 3: Level 23-25
      WHEN user_num <= 10 THEN 15 + ((user_num - 3) * 1)  -- Next 7: Level 16-22
      WHEN user_num <= 25 THEN 10 + ((user_num - 10) / 2)::int  -- Next 15: Level 10-17
      WHEN user_num <= 40 THEN 5 + ((user_num - 25) / 3)::int  -- Next 15: Level 5-10
      ELSE 3 + ((user_num - 40) / 2)::int  -- Last 10: Level 3-8
    END AS level
  FROM fake_users
),
xp_data AS (
  SELECT 
    user_id,
    user_num,
    display_name,
    level,
    -- Calculate XP from level: XP = 10 * (level - 1)^2
    -- Add ±15% random variation for realism
    GREATEST(0, (10 * (level - 1) * (level - 1))::int + 
    (random() * (10 * (level - 1) * (level - 1) * 0.3) - (10 * (level - 1) * (level - 1) * 0.15))::int) AS xp
  FROM level_data
),
portfolio_data AS (
  SELECT 
    user_id,
    user_num,
    display_name,
    level,
    xp,
    -- Portfolio value correlates with level but has realistic variation
    -- All values > $10,000 (starting amount) to show they've traded
    CASE 
      WHEN level >= 20 THEN 15000 + (level - 20) * 700 + (random() * 4000)::int  -- $15K-$24K
      WHEN level >= 15 THEN 12000 + (level - 15) * 500 + (random() * 2500)::int  -- $12K-$17K
      WHEN level >= 10 THEN 11000 + (level - 10) * 350 + (random() * 1500)::int  -- $11K-$14.5K
      WHEN level >= 5 THEN 10500 + (level - 5) * 250 + (random() * 1000)::int  -- $10.5K-$12K
      ELSE 10100 + level * 150 + (random() * 600)::int  -- $10.1K-$10.9K
    END AS portfolio_value
  FROM xp_data
),
streak_data AS (
  SELECT 
    user_id,
    user_num,
    display_name,
    level,
    xp,
    portfolio_value,
    -- Streak for newly launched app: mix of engagement levels
    -- Shows active community while still being believable (app launched ~2-3 weeks ago)
    CASE 
      WHEN level >= 20 THEN 12 + (random() * 9)::int  -- 12-21 days (power users, early adopters)
      WHEN level >= 15 THEN 8 + (random() * 7)::int  -- 8-15 days (very active users)
      WHEN level >= 10 THEN 5 + (random() * 6)::int  -- 5-11 days (regular users)
      WHEN level >= 5 THEN 3 + (random() * 5)::int  -- 3-8 days (casual users)
      ELSE 1 + (random() * 4)::int  -- 1-5 days (new users)
    END AS streak
  FROM portfolio_data
),
badge_data AS (
  SELECT 
    user_id,
    user_num,
    display_name,
    level,
    xp,
    portfolio_value,
    streak,
    -- Badges correlate with level: more XP = more badges
    CASE 
      WHEN level >= 20 THEN 12 + (random() * 8)::int  -- 12-20 badges
      WHEN level >= 15 THEN 8 + (random() * 6)::int  -- 8-14 badges
      WHEN level >= 10 THEN 5 + (random() * 5)::int  -- 5-10 badges
      WHEN level >= 5 THEN 2 + (random() * 4)::int  -- 2-6 badges
      ELSE 1 + (random() * 2)::int  -- 1-3 badges
    END AS badges
  FROM streak_data
)
-- Create temporary table to hold the data for multiple inserts
SELECT * INTO TEMP TABLE temp_fake_users FROM badge_data;

-- First, create auth.users entries (if they don't exist)
-- NOTE: This requires admin access. If you get permission errors, comment out this entire INSERT block
-- and temporarily disable the foreign key constraint on leaderboard.user_id instead:
-- ALTER TABLE leaderboard DROP CONSTRAINT IF EXISTS leaderboard_user_id_fkey;
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, role)
SELECT DISTINCT
  user_id,
  'fake_user_' || user_num || '@example.com' AS email,
  crypt('fake_password', gen_salt('bf')) AS encrypted_password,
  NOW() AS email_confirmed_at,
  NOW() - (random() * INTERVAL '30 days') AS created_at,
  NOW() AS updated_at,
  '{"provider":"email","providers":["email"]}'::jsonb AS raw_app_meta_data,
  '{}'::jsonb AS raw_user_meta_data,
  false AS is_super_admin,
  'authenticated' AS role
FROM temp_fake_users
ON CONFLICT (id) DO NOTHING;

-- Insert into leaderboard (using DISTINCT to prevent duplicates)
INSERT INTO leaderboard (
  user_id,
  display_name,
  xp,
  level,
  streak,
  badges,
  portfolio_value,
  updated_at
)
SELECT DISTINCT ON (user_id)
  user_id,
  display_name,
  xp,
  level,
  streak,
  badges,
  portfolio_value,
  NOW() - (random() * INTERVAL '30 days') AS updated_at  -- Random activity in last 30 days
FROM temp_fake_users
ORDER BY user_id, portfolio_value DESC  -- Order by user_id first for DISTINCT ON, then portfolio
ON CONFLICT (user_id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  xp = EXCLUDED.xp,
  level = EXCLUDED.level,
  streak = EXCLUDED.streak,
  badges = EXCLUDED.badges,
  portfolio_value = EXCLUDED.portfolio_value,
  updated_at = EXCLUDED.updated_at;

-- Also create user profiles for these fake users
INSERT INTO user_profiles (user_id, data, updated_at)
SELECT DISTINCT ON (user_id)
  user_id,
  jsonb_build_object(
    'displayName', display_name,
    'name', display_name,
    'avatar', CASE (random() * 10)::int % 10
      WHEN 0 THEN '🎯'
      WHEN 1 THEN '🚀'
      WHEN 2 THEN '💼'
      WHEN 3 THEN '📈'
      WHEN 4 THEN '💰'
      WHEN 5 THEN '⭐'
      WHEN 6 THEN '🏆'
      WHEN 7 THEN '🔥'
      WHEN 8 THEN '💎'
      ELSE '🎮'
    END
  ) AS data,
  NOW() - (random() * INTERVAL '30 days') AS updated_at
FROM temp_fake_users
ORDER BY user_id
ON CONFLICT (user_id) DO UPDATE SET
  data = EXCLUDED.data,
  updated_at = EXCLUDED.updated_at;

-- Clean up temporary table
DROP TABLE IF EXISTS temp_fake_users;

-- Verify the data
SELECT 
  COUNT(*) as total_fake_users,
  ROUND(AVG(portfolio_value)::numeric, 2) as avg_portfolio,
  ROUND(MIN(portfolio_value)::numeric, 2) as min_portfolio,
  ROUND(MAX(portfolio_value)::numeric, 2) as max_portfolio,
  COUNT(*) FILTER (WHERE portfolio_value = 10000) as users_with_starting_amount,
  ROUND(AVG(level)::numeric, 1) as avg_level,
  ROUND(AVG(xp)::numeric, 0) as avg_xp,
  ROUND(AVG(streak)::numeric, 1) as avg_streak
FROM leaderboard
WHERE portfolio_value > 10000;  -- All fake users should have > $10,000
