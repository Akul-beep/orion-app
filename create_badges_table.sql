-- ============================================
-- BADGES TABLE FOR ORION APP
-- This allows badges to be managed in Supabase
-- without requiring app updates
-- ============================================

-- Badges definition table
CREATE TABLE IF NOT EXISTS badges (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  emoji TEXT NOT NULL,
  category TEXT NOT NULL, -- 'learning', 'trading', 'streak', 'milestone', 'social', 'special'
  rarity TEXT NOT NULL, -- 'common', 'rare', 'epic', 'legendary'
  requirements JSONB NOT NULL, -- {'statName': minimumValue}
  xp_reward INTEGER DEFAULT 0,
  icon TEXT, -- Optional icon URL or identifier
  is_active BOOLEAN DEFAULT true, -- Allow disabling badges without deleting
  display_order INTEGER DEFAULT 0, -- For sorting in UI
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_badges_category ON badges(category);
CREATE INDEX IF NOT EXISTS idx_badges_rarity ON badges(rarity);
CREATE INDEX IF NOT EXISTS idx_badges_active ON badges(is_active);

-- Enable RLS (Row Level Security)
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can read active badges
CREATE POLICY "Badges are viewable by everyone"
  ON badges FOR SELECT
  USING (is_active = true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_badges_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_badges_updated_at
  BEFORE UPDATE ON badges
  FOR EACH ROW
  EXECUTE FUNCTION update_badges_updated_at();

-- Insert existing badges from the app
-- This migrates the hardcoded badges to the database
INSERT INTO badges (id, name, description, emoji, category, rarity, requirements, xp_reward, display_order) VALUES
-- LEARNING BADGES
('first_lesson', 'First Steps', 'Complete your first lesson', '🎯', 'learning', 'common', '{"lessonsCompleted": 1}', 50, 1),
('week_1_champion', 'Week 1 Champion', 'Complete 7 lessons', '🏆', 'learning', 'rare', '{"lessonsCompleted": 7}', 200, 2),
('month_master', 'Month Master', 'Complete 30 lessons', '👑', 'learning', 'epic', '{"lessonsCompleted": 30}', 500, 3),
('course_completer', 'Course Completer', 'Complete all 30 lessons in the course', '🎓', 'learning', 'legendary', '{"lessonsCompleted": 30}', 1000, 4),
('perfect_lesson', 'Perfect Score', 'Complete a lesson with 100% accuracy', '⭐', 'learning', 'rare', '{"perfectLessons": 1}', 100, 5),
('perfect_week', 'Perfect Week', 'Complete 7 lessons with perfect scores', '🌟', 'learning', 'epic', '{"perfectLessons": 7}', 500, 6),

-- TRADING BADGES
('first_trader', 'First Trader', 'Make your first trade', '💼', 'trading', 'common', '{"totalTrades": 1}', 50, 10),
('active_trader', 'Active Trader', 'Make 10 trades', '📈', 'trading', 'rare', '{"totalTrades": 10}', 200, 11),
('experienced_trader', 'Experienced Trader', 'Make 50 trades', '📊', 'trading', 'epic', '{"totalTrades": 50}', 500, 12),
('trading_master', 'Trading Master', 'Make 100 trades', '🚀', 'trading', 'legendary', '{"totalTrades": 100}', 1000, 13),

-- STREAK BADGES
('streak_3', '3-Day Streak', 'Maintain a 3-day learning streak', '🔥', 'streak', 'common', '{"streak": 3}', 50, 20),
('streak_7', 'Week Warrior', 'Maintain a 7-day learning streak', '🔥🔥', 'streak', 'rare', '{"streak": 7}', 200, 21),
('streak_14', 'Two Week Champion', 'Maintain a 14-day learning streak', '🔥🔥🔥', 'streak', 'epic', '{"streak": 14}', 500, 22),
('streak_30', 'Month Warrior', 'Maintain a 30-day learning streak', '🔥🔥🔥🔥', 'streak', 'legendary', '{"streak": 30}', 1000, 23),
('streak_100', 'Centurion', 'Maintain a 100-day learning streak', '👑🔥', 'streak', 'legendary', '{"streak": 100}', 2000, 24),

-- MILESTONE BADGES (Level-based)
('level_5', 'Level 5', 'Reach level 5', '⭐', 'milestone', 'common', '{"level": 5}', 100, 30),
('level_10', 'Level 10', 'Reach level 10', '⭐⭐', 'milestone', 'rare', '{"level": 10}', 300, 31),
('level_20', 'Level 20', 'Reach level 20', '⭐⭐⭐', 'milestone', 'epic', '{"level": 20}', 500, 32),
('level_30', 'Level 30', 'Reach level 30', '⭐⭐⭐⭐', 'milestone', 'legendary', '{"level": 30}', 1000, 33),
('level_50', 'Level 50', 'Reach level 50', '👑', 'milestone', 'legendary', '{"level": 50}', 2000, 34),

-- XP MILESTONE BADGES
('xp_1000', 'XP Novice', 'Earn 1,000 total XP', '💎', 'milestone', 'common', '{"totalXP": 1000}', 100, 40),
('xp_5000', 'XP Master', 'Earn 5,000 total XP', '💎💎', 'milestone', 'rare', '{"totalXP": 5000}', 300, 41),
('xp_10000', 'XP Legend', 'Earn 10,000 total XP', '💎💎💎', 'milestone', 'epic', '{"totalXP": 10000}', 500, 42),
('xp_25000', 'XP Champion', 'Earn 25,000 total XP', '💎💎💎💎', 'milestone', 'legendary', '{"totalXP": 25000}', 1000, 43),
('xp_50000', 'XP God', 'Earn 50,000 total XP', '👑💎', 'milestone', 'legendary', '{"totalXP": 50000}', 2000, 44),

-- SPECIAL BADGES
('early_adopter', 'Early Adopter', 'Join during the first month', '🌱', 'special', 'rare', '{"daysSinceJoin": 30}', 200, 50),
('daily_learner', 'Daily Learner', 'Complete lessons for 7 consecutive days', '📚', 'learning', 'rare', '{"consecutiveLearningDays": 7}', 200, 7)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  emoji = EXCLUDED.emoji,
  category = EXCLUDED.category,
  rarity = EXCLUDED.rarity,
  requirements = EXCLUDED.requirements,
  xp_reward = EXCLUDED.xp_reward,
  display_order = EXCLUDED.display_order,
  updated_at = NOW();

-- Verify the badges were created
SELECT COUNT(*) as total_badges, 
       COUNT(*) FILTER (WHERE is_active = true) as active_badges,
       COUNT(*) FILTER (WHERE category = 'learning') as learning_badges,
       COUNT(*) FILTER (WHERE category = 'trading') as trading_badges,
       COUNT(*) FILTER (WHERE category = 'streak') as streak_badges,
       COUNT(*) FILTER (WHERE category = 'milestone') as milestone_badges
FROM badges;

