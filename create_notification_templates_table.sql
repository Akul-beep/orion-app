-- ============================================
-- NOTIFICATION TEMPLATES TABLE FOR ORION APP
-- Allows updating notification messages from Supabase
-- without requiring app updates
-- ============================================

-- Notification templates table
CREATE TABLE IF NOT EXISTS notification_templates (
  id TEXT PRIMARY KEY,
  template_type TEXT NOT NULL, -- 'morning_streak', 'afternoon_learning', 'evening_streak', 'streak_at_risk', 'level_up', 'badge_unlocked', 'streak_milestone'
  character_mood TEXT NOT NULL, -- 'friendly', 'concerned', 'excited', 'proud'
  title_template TEXT NOT NULL, -- Template with {streak}, {userName} placeholders
  body_template TEXT NOT NULL, -- Template with {streak}, {userName} placeholders
  is_active BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 0, -- Higher priority templates are used first
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_notification_templates_type ON notification_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_notification_templates_mood ON notification_templates(character_mood);
CREATE INDEX IF NOT EXISTS idx_notification_templates_active ON notification_templates(is_active);

-- Enable RLS (Row Level Security)
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can read active templates
CREATE POLICY "Notification templates are viewable by everyone"
  ON notification_templates FOR SELECT
  USING (is_active = true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_notification_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_notification_templates_updated_at
  BEFORE UPDATE ON notification_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_notification_templates_updated_at();

-- Insert default notification templates (Duolingo-style aggressive, guilty marketing)
INSERT INTO notification_templates (id, template_type, character_mood, title_template, body_template, priority) VALUES
-- Morning Streak Reminders (Friendly) - 8 variations
('morning_streak_1', 'morning_streak', 'friendly', 'Hey. It''s Ory.', 'Your {streak}-day streak is waiting. Don''t make it wait any longer.', 1),
('morning_streak_2', 'morning_streak', 'friendly', 'Hi. It''s Ory.', 'It would be a bummer to lose that {streak}-day streak. Just saying.', 2),
('morning_streak_3', 'morning_streak', 'friendly', 'Ory here.', 'Hey. It looks like you haven''t completed your goals today. Good luck explaining that to your {streak}-day streak.', 3),
('morning_streak_4', 'morning_streak', 'friendly', 'Hey there.', 'Your {streak}-day streak needs you. Complete your goals now.', 4),
('morning_streak_5', 'morning_streak', 'friendly', 'It''s Ory.', 'These reminders don''t seem to be working. We''ll stop sending them for you now. (Just kidding. Complete your goals.)', 5),
('morning_streak_6', 'morning_streak', 'friendly', 'Ory here!', 'Your daily lesson is waiting. Don''t make it wait any longer.', 6),
('morning_streak_7', 'morning_streak', 'friendly', 'Hey. Ory.', 'It''s time to complete your goals. Your {streak}-day streak is counting on you.', 7),
('morning_streak_8', 'morning_streak', 'friendly', 'Hi. Ory.', 'You''re going to let your {streak}-day streak die? Really?', 8),

-- Afternoon Learning Reminders (Friendly) - 8 variations
('afternoon_learning_1', 'afternoon_learning', 'friendly', 'Hey. It''s Ory.', 'Hey. It looks like you missed your trading lesson again. Good luck talking your way out of this one.', 1),
('afternoon_learning_2', 'afternoon_learning', 'friendly', 'Ory here.', 'Your trading knowledge is fading. Complete your lesson now.', 2),
('afternoon_learning_3', 'afternoon_learning', 'friendly', 'Hey. Ory.', 'You''re falling behind. Complete your daily lesson immediately.', 3),
('afternoon_learning_4', 'afternoon_learning', 'friendly', 'It''s Ory.', 'These reminders don''t seem to be working. We''ll stop sending them for you now. (Just kidding. Complete your lesson.)', 4),
('afternoon_learning_5', 'afternoon_learning', 'friendly', 'Ory here!', 'It''s time to learn. Your future self will thank you.', 5),
('afternoon_learning_6', 'afternoon_learning', 'friendly', 'Hey there.', 'Your portfolio is waiting. But first, complete your lesson.', 6),
('afternoon_learning_7', 'afternoon_learning', 'friendly', 'Hey. It''s Ory.', 'You know what would be cool? Completing your lesson. Just saying.', 7),
('afternoon_learning_8', 'afternoon_learning', 'friendly', 'Ory here.', 'I''m not mad, just disappointed. Complete your lesson.', 8),

-- Evening Streak Reminders (Friendly) - 8 variations
('evening_streak_1', 'evening_streak', 'friendly', 'Hey. It''s Ory.', 'It would be a bummer to lose that {streak}-day streak. Just saying.', 1),
('evening_streak_2', 'evening_streak', 'friendly', 'Ory here.', 'Your {streak}-day streak is about to break. Complete your goals now.', 2),
('evening_streak_3', 'evening_streak', 'friendly', 'Hey. Ory.', 'Time is running out. Your {streak}-day streak needs you.', 3),
('evening_streak_4', 'evening_streak', 'friendly', 'It''s Ory.', 'Hey. It looks like you haven''t completed your goals today. Your {streak}-day streak won''t be happy.', 4),
('evening_streak_5', 'evening_streak', 'friendly', 'Ory here!', 'This is your last chance. Complete your goals before your {streak}-day streak breaks.', 5),
('evening_streak_6', 'evening_streak', 'friendly', 'Hey there.', 'Your {streak}-day streak is waiting. Don''t let it down.', 6),
('evening_streak_7', 'evening_streak', 'friendly', 'Hey. It''s Ory.', 'After {streak} days, you''re going to let it all go?', 7),
('evening_streak_8', 'evening_streak', 'friendly', 'Ory here.', 'Your {streak}-day streak is in danger. It would be a shame to lose it.', 8),

-- Streak At Risk (Concerned - High Streaks 30+) - 10 variations
('streak_at_risk_high_1', 'streak_at_risk', 'concerned', 'Hey. It''s Ory.', 'After {streak} days, you''re going to let it all go? Your streak needs you right now.', 1),
('streak_at_risk_high_2', 'streak_at_risk', 'concerned', 'Ory here.', 'Your {streak}-day streak is about to break. I really don''t want that to happen. Please come back.', 2),
('streak_at_risk_high_3', 'streak_at_risk', 'concerned', 'Hey. Ory.', 'Hey. It looks like you haven''t been here today. Your {streak}-day streak won''t be happy.', 3),
('streak_at_risk_high_4', 'streak_at_risk', 'concerned', 'It''s Ory.', 'It would be a bummer to lose that {streak}-day streak. Just saying. Come back now.', 4),
('streak_at_risk_high_5', 'streak_at_risk', 'concerned', 'Ory here...', 'Your {streak}-day streak is in danger. It would be a shame to lose it after all this time.', 5),
('streak_at_risk_high_6', 'streak_at_risk', 'concerned', 'Hey there.', 'These reminders don''t seem to be working. We''ll stop sending them for you now. (Just kidding. Complete your goals.)', 6),
('streak_at_risk_high_7', 'streak_at_risk', 'concerned', 'Ory here.', 'I''ve been watching your {streak}-day streak. It''s not looking good. Please come back.', 7),
('streak_at_risk_high_8', 'streak_at_risk', 'concerned', 'Hey. It''s Ory.', 'Your {streak}-day streak is crying. (Not really, but you get the point.)', 8),
('streak_at_risk_high_9', 'streak_at_risk', 'concerned', 'Ory here.', 'After {streak} days of hard work, you''re just going to throw it away?', 9),
('streak_at_risk_high_10', 'streak_at_risk', 'concerned', 'Hey. Ory.', 'Your {streak}-day streak is about to break. I''m not mad, just disappointed.', 10),

-- Streak At Risk (Concerned - Medium Streaks 7-29) - 10 variations
('streak_at_risk_medium_1', 'streak_at_risk', 'concerned', 'Hey. It''s Ory.', 'Your {streak}-day streak is about to break. I really don''t want that to happen.', 1),
('streak_at_risk_medium_2', 'streak_at_risk', 'concerned', 'Ory here.', 'After {streak} days, you''re going to let it all go? Complete your goals now.', 2),
('streak_at_risk_medium_3', 'streak_at_risk', 'concerned', 'Hey. Ory.', 'Hey. It looks like you haven''t been here today. Your {streak}-day streak is waiting.', 3),
('streak_at_risk_medium_4', 'streak_at_risk', 'concerned', 'It''s Ory.', 'Your {streak}-day streak is in danger. Complete your goals now.', 4),
('streak_at_risk_medium_5', 'streak_at_risk', 'concerned', 'Ory here...', 'It would be a shame to lose your {streak}-day streak. Just saying.', 5),
('streak_at_risk_medium_6', 'streak_at_risk', 'concerned', 'Hey there.', 'Your {streak}-day streak needs you. Don''t let it down.', 6),
('streak_at_risk_medium_7', 'streak_at_risk', 'concerned', 'Ory here.', 'I''m worried about your {streak}-day streak. Please come back.', 7),
('streak_at_risk_medium_8', 'streak_at_risk', 'concerned', 'Hey. It''s Ory.', 'Your {streak}-day streak is about to break. Don''t let that happen.', 8),
('streak_at_risk_medium_9', 'streak_at_risk', 'concerned', 'Ory here.', 'After {streak} days, you''re going to give up? Really?', 9),
('streak_at_risk_medium_10', 'streak_at_risk', 'concerned', 'Hey. Ory.', 'Your {streak}-day streak won''t survive without you. Come back now.', 10),

-- Streak At Risk (Concerned - Low Streaks) - 10 variations
('streak_at_risk_low_1', 'streak_at_risk', 'concerned', 'Hey. It''s Ory.', 'Your streak is about to break. I really don''t want that to happen.', 1),
('streak_at_risk_low_2', 'streak_at_risk', 'concerned', 'Ory here.', 'Hey. It looks like you haven''t been here today. Your streak is waiting.', 2),
('streak_at_risk_low_3', 'streak_at_risk', 'concerned', 'Hey. Ory.', 'Your streak is in danger. Complete your goals now.', 3),
('streak_at_risk_low_4', 'streak_at_risk', 'concerned', 'It''s Ory.', 'These reminders don''t seem to be working. We''ll stop sending them for you now. (Just kidding. Complete your goals.)', 4),
('streak_at_risk_low_5', 'streak_at_risk', 'concerned', 'Ory here...', 'Your streak needs you. Don''t let it down.', 5),
('streak_at_risk_low_6', 'streak_at_risk', 'concerned', 'Hey there.', 'It would be a shame to lose your streak. Just saying.', 6),
('streak_at_risk_low_7', 'streak_at_risk', 'concerned', 'Ory here.', 'I''m worried about your streak. Please come back.', 7),
('streak_at_risk_low_8', 'streak_at_risk', 'concerned', 'Hey. It''s Ory.', 'Your streak is about to break. Don''t let that happen.', 8),
('streak_at_risk_low_9', 'streak_at_risk', 'concerned', 'Ory here.', 'You''re going to let your streak die? Really?', 9),
('streak_at_risk_low_10', 'streak_at_risk', 'concerned', 'Hey. Ory.', 'Your streak won''t survive without you. Come back now.', 10),

-- Level Up (Excited) - 8 variations
('level_up_1', 'level_up', 'excited', 'Hey. It''s Ory!', 'You leveled up! Keep going!', 1),
('level_up_2', 'level_up', 'excited', 'Ory here!', 'Level up! You''re getting better!', 2),
('level_up_3', 'level_up', 'excited', 'Hey! Ory!', 'Congratulations! You leveled up!', 3),
('level_up_4', 'level_up', 'excited', 'It''s Ory!', 'Level up! Your trading skills are improving!', 4),
('level_up_5', 'level_up', 'excited', 'Ory here!', 'You leveled up! This is amazing!', 5),
('level_up_6', 'level_up', 'excited', 'Hey! It''s Ory!', 'Level up! Keep the momentum going!', 6),
('level_up_7', 'level_up', 'excited', 'Ory here!', 'You leveled up! I''m so proud!', 7),
('level_up_8', 'level_up', 'excited', 'Hey. Ory!', 'Level up! You''re crushing it!', 8),

-- Badge Unlocked (Excited) - 8 variations
('badge_unlocked_1', 'badge_unlocked', 'excited', 'Hey. It''s Ory!', 'Achievement unlocked! Amazing work!', 1),
('badge_unlocked_2', 'badge_unlocked', 'excited', 'Ory here!', 'You unlocked an achievement! Incredible!', 2),
('badge_unlocked_3', 'badge_unlocked', 'excited', 'Hey! Ory!', 'Achievement unlocked! You''re doing great!', 3),
('badge_unlocked_4', 'badge_unlocked', 'excited', 'It''s Ory!', 'New achievement! Keep it up!', 4),
('badge_unlocked_5', 'badge_unlocked', 'excited', 'Ory here!', 'Achievement unlocked! I''m so proud!', 5),
('badge_unlocked_6', 'badge_unlocked', 'excited', 'Hey! It''s Ory!', 'You earned an achievement! This is awesome!', 6),
('badge_unlocked_7', 'badge_unlocked', 'excited', 'Ory here!', 'Achievement unlocked! You''re on fire!', 7),
('badge_unlocked_8', 'badge_unlocked', 'excited', 'Hey. Ory!', 'New achievement! Your hard work paid off!', 8),

-- Streak Milestone (Excited) - 8 variations
('streak_milestone_1', 'streak_milestone', 'excited', 'Hey. It''s Ory!', '{streak}-day streak milestone! Incredible!', 1),
('streak_milestone_2', 'streak_milestone', 'excited', 'Ory here!', 'You hit a {streak}-day streak! Amazing!', 2),
('streak_milestone_3', 'streak_milestone', 'excited', 'Hey! Ory!', '{streak}-day streak! You''re unstoppable!', 3),
('streak_milestone_4', 'streak_milestone', 'excited', 'It''s Ory!', 'Milestone reached! {streak} days strong!', 4),
('streak_milestone_5', 'streak_milestone', 'excited', 'Ory here!', '{streak}-day streak! I''m so proud!', 5),
('streak_milestone_6', 'streak_milestone', 'excited', 'Hey! It''s Ory!', 'You''ve reached {streak} days! Incredible!', 6),
('streak_milestone_7', 'streak_milestone', 'excited', 'Ory here!', '{streak}-day streak milestone! Keep going!', 7),
('streak_milestone_8', 'streak_milestone', 'excited', 'Hey. Ory!', '{streak} days! You''re a streak champion!', 8),

-- Proud (Streak Maintenance) - 8 variations
('proud_1', 'proud', 'proud', 'Hey. It''s Ory!', '{streak}-day streak! You''re doing amazing!', 1),
('proud_2', 'proud', 'proud', 'Ory here!', '{streak} days strong! I''m so proud!', 2),
('proud_3', 'proud', 'proud', 'Hey! Ory!', '{streak}-day streak! Keep it up!', 3),
('proud_4', 'proud', 'proud', 'It''s Ory!', 'You''ve maintained {streak} days! Incredible!', 4),
('proud_5', 'proud', 'proud', 'Ory here!', '{streak}-day streak! You''re unstoppable!', 5),
('proud_6', 'proud', 'proud', 'Hey! It''s Ory!', '{streak} days! You''re a champion!', 6),
('proud_7', 'proud', 'proud', 'Ory here!', '{streak}-day streak! This is amazing!', 7),
('proud_8', 'proud', 'proud', 'Hey. Ory!', '{streak} days! You''re doing great!', 8)
ON CONFLICT (id) DO UPDATE SET
  template_type = EXCLUDED.template_type,
  character_mood = EXCLUDED.character_mood,
  title_template = EXCLUDED.title_template,
  body_template = EXCLUDED.body_template,
  priority = EXCLUDED.priority,
  updated_at = NOW();

-- Verify the templates were created
SELECT COUNT(*) as total_templates, 
       COUNT(*) FILTER (WHERE is_active = true) as active_templates,
       COUNT(*) FILTER (WHERE template_type = 'morning_streak') as morning_templates,
       COUNT(*) FILTER (WHERE template_type = 'afternoon_learning') as learning_templates,
       COUNT(*) FILTER (WHERE template_type = 'evening_streak') as evening_templates,
       COUNT(*) FILTER (WHERE template_type = 'streak_at_risk') as streak_at_risk_templates
FROM notification_templates;

