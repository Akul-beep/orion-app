-- Supabase Schema for Remote Lessons Management
-- This allows adding lessons without app updates!

-- Lessons table
CREATE TABLE IF NOT EXISTS lessons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  content JSONB NOT NULL, -- Full lesson structure (steps, questions, etc.)
  difficulty TEXT CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')),
  xp_reward INTEGER DEFAULT 200,
  badge_name TEXT,
  badge_emoji TEXT,
  order_index INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  unlock_requirement JSONB DEFAULT '{}', -- {'level': 5, 'streak': 3, 'badge': 'RSI Rookie'}
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- User lesson progress
CREATE TABLE IF NOT EXISTS user_lesson_progress (
  user_id TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  unlocked_at TIMESTAMP,
  completed_at TIMESTAMP,
  xp_earned INTEGER DEFAULT 0,
  score INTEGER, -- Quiz score percentage
  attempts INTEGER DEFAULT 0,
  time_spent_seconds INTEGER DEFAULT 0,
  PRIMARY KEY (user_id, lesson_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_lessons_active ON lessons(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_lessons_difficulty ON lessons(difficulty);
CREATE INDEX IF NOT EXISTS idx_lessons_order ON lessons(order_index);
CREATE INDEX IF NOT EXISTS idx_user_progress_user ON user_lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_lesson ON user_lesson_progress(lesson_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at
CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Example lesson insert (for reference)
/*
INSERT INTO lessons (lesson_id, title, description, content, difficulty, xp_reward, badge_name, badge_emoji, order_index)
VALUES (
  'macd_indicator',
  'MACD Indicator Basics',
  'Learn to use MACD for trend analysis',
  '{
    "steps": [
      {
        "type": "intro",
        "content": "Ready to learn MACD?",
        "subtitle": "Master the Moving Average Convergence Divergence!",
        "icon": "📊"
      },
      {
        "type": "multiple_choice",
        "question": "What does MACD stand for?",
        "options": [
          "Moving Average Convergence Divergence",
          "Market Analysis Chart Data",
          "Maximum Average Chart Display",
          "Market Average Calculation Data"
        ],
        "correct": 0,
        "explanation": "MACD measures the relationship between two moving averages!",
        "xp": 15
      }
    ]
  }'::jsonb,
  'Intermediate',
  350,
  'MACD Master',
  '📈',
  31
);
*/






