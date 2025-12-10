-- ============================================
-- ORION APP DATABASE SETUP
-- Run this in Supabase SQL Editor
-- ============================================

-- Portfolio table
CREATE TABLE IF NOT EXISTS portfolio (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trades table
CREATE TABLE IF NOT EXISTS trades (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  trade_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Gamification table
CREATE TABLE IF NOT EXISTS gamification (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Completed actions table
CREATE TABLE IF NOT EXISTS completed_actions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  action_id TEXT NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, action_id)
);

-- Leaderboard table
CREATE TABLE IF NOT EXISTS leaderboard (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name TEXT NOT NULL,
  xp INTEGER DEFAULT 0,
  streak INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  badges INTEGER DEFAULT 0,
  portfolio_value NUMERIC(12, 2) DEFAULT 0,
  avatar TEXT DEFAULT '🎯',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Watchlist table
CREATE TABLE IF NOT EXISTS watchlist (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  symbols TEXT[] NOT NULL DEFAULT '{}',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Stock cache table (shared across users, no user_id)
CREATE TABLE IF NOT EXISTS stock_cache (
  cache_key TEXT PRIMARY KEY,
  cache_data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User screen visits tracking
CREATE TABLE IF NOT EXISTS user_screen_visits (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  screen_name TEXT NOT NULL,
  screen_type TEXT, -- 'main', 'detail', 'modal', 'overlay'
  visited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  time_spent_seconds INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb -- Additional context like symbol, action, etc.
);

-- User widget interactions tracking
CREATE TABLE IF NOT EXISTS user_widget_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  screen_name TEXT NOT NULL,
  widget_type TEXT NOT NULL, -- 'button', 'card', 'tab', 'dialog', etc.
  widget_id TEXT, -- Specific identifier for the widget
  action_type TEXT NOT NULL, -- 'tap', 'swipe', 'long_press', 'scroll', etc.
  interaction_data JSONB DEFAULT '{}'::jsonb, -- Additional data about the interaction
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User navigation flow tracking
CREATE TABLE IF NOT EXISTS user_navigation_flows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  from_screen TEXT,
  to_screen TEXT NOT NULL,
  navigation_method TEXT, -- 'push', 'pop', 'replace', 'tab_switch', 'deep_link'
  navigation_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User session tracking
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  session_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  session_end TIMESTAMP WITH TIME ZONE,
  total_screens_visited INTEGER DEFAULT 0,
  total_interactions INTEGER DEFAULT 0,
  session_data JSONB DEFAULT '{}'::jsonb,
  device_info JSONB DEFAULT '{}'::jsonb
);

-- User progress tracking (comprehensive)
CREATE TABLE IF NOT EXISTS user_progress (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  last_screen_visited TEXT,
  last_screen_visited_at TIMESTAMP WITH TIME ZONE,
  screens_visited_count JSONB DEFAULT '{}'::jsonb, -- {screen_name: count}
  total_time_spent JSONB DEFAULT '{}'::jsonb, -- {screen_name: seconds}
  learning_progress JSONB DEFAULT '{}'::jsonb,
  trading_progress JSONB DEFAULT '{}'::jsonb,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  onboarding_data JSONB DEFAULT '{}'::jsonb,
  preferences JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User state persistence (for seamless experience)
CREATE TABLE IF NOT EXISTS user_state_snapshots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  screen_name TEXT NOT NULL,
  state_data JSONB NOT NULL, -- Complete state snapshot
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Learning progress detailed tracking
CREATE TABLE IF NOT EXISTS learning_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  lesson_id TEXT NOT NULL,
  lesson_name TEXT,
  module_id TEXT,
  progress_percentage INTEGER DEFAULT 0,
  time_spent_seconds INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  quiz_scores JSONB DEFAULT '{}'::jsonb,
  last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, lesson_id)
);

-- Trading activity tracking
CREATE TABLE IF NOT EXISTS trading_activity (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  activity_type TEXT NOT NULL, -- 'view_stock', 'add_watchlist', 'remove_watchlist', 'view_chart', 'view_news', etc.
  symbol TEXT,
  activity_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- Enable Row Level Security (RLS)
-- ============================================

ALTER TABLE portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE gamification ENABLE ROW LEVEL SECURITY;
ALTER TABLE completed_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_screen_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_widget_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_navigation_flows ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_state_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE trading_activity ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Create Security Policies
-- ============================================

-- Drop existing policies if they exist, then create new ones
DO $$ 
BEGIN
  -- Portfolio: Users can only access their own data
  DROP POLICY IF EXISTS "Users can manage own portfolio" ON portfolio;
  CREATE POLICY "Users can manage own portfolio" ON portfolio
    FOR ALL USING (auth.uid() = user_id);

  -- Trades: Users can only access their own trades
  DROP POLICY IF EXISTS "Users can manage own trades" ON trades;
  CREATE POLICY "Users can manage own trades" ON trades
    FOR ALL USING (auth.uid() = user_id);

  -- Gamification: Users can only access their own data
  DROP POLICY IF EXISTS "Users can manage own gamification" ON gamification;
  CREATE POLICY "Users can manage own gamification" ON gamification
    FOR ALL USING (auth.uid() = user_id);

  -- Completed actions: Users can only access their own actions
  DROP POLICY IF EXISTS "Users can manage own completed actions" ON completed_actions;
  CREATE POLICY "Users can manage own completed actions" ON completed_actions
    FOR ALL USING (auth.uid() = user_id);

  -- Leaderboard: Everyone can read, users can only update their own
  DROP POLICY IF EXISTS "Users can read all leaderboard" ON leaderboard;
  CREATE POLICY "Users can read all leaderboard" ON leaderboard
    FOR SELECT USING (true);

  DROP POLICY IF EXISTS "Users can update own leaderboard" ON leaderboard;
  CREATE POLICY "Users can update own leaderboard" ON leaderboard
    FOR UPDATE USING (auth.uid() = user_id);

  DROP POLICY IF EXISTS "Users can insert own leaderboard" ON leaderboard;
  CREATE POLICY "Users can insert own leaderboard" ON leaderboard
    FOR INSERT WITH CHECK (auth.uid() = user_id);

  -- User profiles: Users can only access their own profile
  DROP POLICY IF EXISTS "Users can manage own profile" ON user_profiles;
  CREATE POLICY "Users can manage own profile" ON user_profiles
    FOR ALL USING (auth.uid() = user_id);

  -- Watchlist: Users can only access their own watchlist
  DROP POLICY IF EXISTS "Users can manage own watchlist" ON watchlist;
  CREATE POLICY "Users can manage own watchlist" ON watchlist
    FOR ALL USING (auth.uid() = user_id);

  -- Stock cache: Authenticated users can read/write
  DROP POLICY IF EXISTS "Authenticated users can read cache" ON stock_cache;
  CREATE POLICY "Authenticated users can read cache" ON stock_cache
    FOR SELECT USING (auth.role() = 'authenticated');

  DROP POLICY IF EXISTS "Authenticated users can write cache" ON stock_cache;
  CREATE POLICY "Authenticated users can write cache" ON stock_cache
    FOR ALL USING (auth.role() = 'authenticated');

  -- Screen visits: Users can only access their own visits
  DROP POLICY IF EXISTS "Users can manage own screen visits" ON user_screen_visits;
  CREATE POLICY "Users can manage own screen visits" ON user_screen_visits
    FOR ALL USING (auth.uid() = user_id);

  -- Widget interactions: Users can only access their own interactions
  DROP POLICY IF EXISTS "Users can manage own widget interactions" ON user_widget_interactions;
  CREATE POLICY "Users can manage own widget interactions" ON user_widget_interactions
    FOR ALL USING (auth.uid() = user_id);

  -- Navigation flows: Users can only access their own navigation
  DROP POLICY IF EXISTS "Users can manage own navigation flows" ON user_navigation_flows;
  CREATE POLICY "Users can manage own navigation flows" ON user_navigation_flows
    FOR ALL USING (auth.uid() = user_id);

  -- User sessions: Users can only access their own sessions
  DROP POLICY IF EXISTS "Users can manage own sessions" ON user_sessions;
  CREATE POLICY "Users can manage own sessions" ON user_sessions
    FOR ALL USING (auth.uid() = user_id);

  -- User progress: Users can only access their own progress
  DROP POLICY IF EXISTS "Users can manage own progress" ON user_progress;
  CREATE POLICY "Users can manage own progress" ON user_progress
    FOR ALL USING (auth.uid() = user_id);

  -- State snapshots: Users can only access their own snapshots
  DROP POLICY IF EXISTS "Users can manage own state snapshots" ON user_state_snapshots;
  CREATE POLICY "Users can manage own state snapshots" ON user_state_snapshots
    FOR ALL USING (auth.uid() = user_id);

  -- Learning progress: Users can only access their own learning progress
  DROP POLICY IF EXISTS "Users can manage own learning progress" ON learning_progress;
  CREATE POLICY "Users can manage own learning progress" ON learning_progress
    FOR ALL USING (auth.uid() = user_id);

  -- Trading activity: Users can only access their own trading activity
  DROP POLICY IF EXISTS "Users can manage own trading activity" ON trading_activity;
  CREATE POLICY "Users can manage own trading activity" ON trading_activity
    FOR ALL USING (auth.uid() = user_id);
END $$;

-- ============================================
-- Create indexes for better performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_trades_user_id ON trades(user_id);
CREATE INDEX IF NOT EXISTS idx_trades_created_at ON trades(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_completed_actions_user_id ON completed_actions(user_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_xp ON leaderboard(xp DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_streak ON leaderboard(streak DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_level ON leaderboard(level DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_portfolio_value ON leaderboard(portfolio_value DESC);

-- Indexes for new tracking tables
CREATE INDEX IF NOT EXISTS idx_screen_visits_user_id ON user_screen_visits(user_id);
CREATE INDEX IF NOT EXISTS idx_screen_visits_screen_name ON user_screen_visits(screen_name);
CREATE INDEX IF NOT EXISTS idx_screen_visits_visited_at ON user_screen_visits(visited_at DESC);
CREATE INDEX IF NOT EXISTS idx_widget_interactions_user_id ON user_widget_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_widget_interactions_screen_name ON user_widget_interactions(screen_name);
CREATE INDEX IF NOT EXISTS idx_widget_interactions_created_at ON user_widget_interactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_navigation_flows_user_id ON user_navigation_flows(user_id);
CREATE INDEX IF NOT EXISTS idx_navigation_flows_to_screen ON user_navigation_flows(to_screen);
CREATE INDEX IF NOT EXISTS idx_navigation_flows_created_at ON user_navigation_flows(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_start ON user_sessions(session_start DESC);
CREATE INDEX IF NOT EXISTS idx_learning_progress_user_id ON learning_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_learning_progress_lesson_id ON learning_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_trading_activity_user_id ON trading_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_trading_activity_symbol ON trading_activity(symbol);
CREATE INDEX IF NOT EXISTS idx_trading_activity_created_at ON trading_activity(created_at DESC);

-- ============================================
-- SOCIAL FEATURES TABLES
-- ============================================

-- Friends table
CREATE TABLE IF NOT EXISTS friends (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- Friend requests table
CREATE TABLE IF NOT EXISTS friend_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  from_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  from_display_name TEXT,
  from_photo_url TEXT,
  to_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'rejected'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(from_user_id, to_user_id)
);

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

-- Group challenges table
CREATE TABLE IF NOT EXISTS group_challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  participant_ids UUID[] NOT NULL DEFAULT '{}',
  gem_reward INTEGER DEFAULT 0,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT NOT NULL DEFAULT 'active', -- 'active', 'completed', 'cancelled'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  learning_path TEXT DEFAULT 'beginner', -- 'beginner', 'intermediate', 'advanced'
  preferences JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add username to user_profiles data JSONB (will be stored in data->>username)
-- Username is unique and searchable
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON user_profiles((data->>'username'));

-- Completed actions with XP earned
ALTER TABLE completed_actions ADD COLUMN IF NOT EXISTS xp_earned TEXT;

-- ============================================
-- Enable RLS for Social Tables
-- ============================================

ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Social Security Policies
-- ============================================

DO $$ 
BEGIN
  -- Friends: Users can manage their own friend relationships
  DROP POLICY IF EXISTS "Users can manage own friends" ON friends;
  CREATE POLICY "Users can manage own friends" ON friends
    FOR ALL USING (auth.uid() = user_id OR auth.uid() = friend_id);

  -- Friend Requests: Users can see requests they sent or received
  DROP POLICY IF EXISTS "Users can view own friend requests" ON friend_requests;
  CREATE POLICY "Users can view own friend requests" ON friend_requests
    FOR SELECT USING (
      auth.uid() = from_user_id OR 
      auth.uid() = to_user_id OR
      from_user_id::text = auth.uid()::text OR
      to_user_id::text = auth.uid()::text
    );

  -- Users can create requests (send)
  DROP POLICY IF EXISTS "Users can send friend requests" ON friend_requests;
  CREATE POLICY "Users can send friend requests" ON friend_requests
    FOR INSERT WITH CHECK (
      auth.uid() = from_user_id OR
      from_user_id::text = auth.uid()::text
    );

  -- Users can update requests they received (accept/reject)
  DROP POLICY IF EXISTS "Users can update received requests" ON friend_requests;
  CREATE POLICY "Users can update received requests" ON friend_requests
    FOR UPDATE USING (
      auth.uid() = to_user_id OR
      to_user_id::text = auth.uid()::text
    );

  -- Users can delete requests they sent (cancel)
  DROP POLICY IF EXISTS "Users can delete sent requests" ON friend_requests;
  CREATE POLICY "Users can delete sent requests" ON friend_requests
    FOR DELETE USING (
      auth.uid() = from_user_id OR
      from_user_id::text = auth.uid()::text
    );

  -- Referrals: Users can view their own referrals
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

  -- Group challenges: Users can read all, but only manage their own
  DROP POLICY IF EXISTS "Users can read all challenges" ON group_challenges;
  CREATE POLICY "Users can read all challenges" ON group_challenges
    FOR SELECT USING (true);

  DROP POLICY IF EXISTS "Users can manage own challenges" ON group_challenges;
  CREATE POLICY "Users can manage own challenges" ON group_challenges
    FOR ALL USING (auth.uid() = creator_id);

  -- User preferences: Users can only access their own preferences
  DROP POLICY IF EXISTS "Users can manage own preferences" ON user_preferences;
  CREATE POLICY "Users can manage own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);
END $$;

-- ============================================
-- Create indexes for social features
-- ============================================

CREATE INDEX IF NOT EXISTS idx_friends_user_id ON friends(user_id);
CREATE INDEX IF NOT EXISTS idx_friends_friend_id ON friends(friend_id);
CREATE INDEX IF NOT EXISTS idx_friends_status ON friends(status);
CREATE INDEX IF NOT EXISTS idx_friend_requests_from_user_id ON friend_requests(from_user_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_to_user_id ON friend_requests(to_user_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_status ON friend_requests(status);
CREATE INDEX IF NOT EXISTS idx_referrals_referral_code ON referrals(referrer_code);
CREATE INDEX IF NOT EXISTS idx_referrals_referred_user_id ON referrals(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_created_at ON referrals(created_at);
CREATE INDEX IF NOT EXISTS idx_group_challenges_creator_id ON group_challenges(creator_id);
CREATE INDEX IF NOT EXISTS idx_group_challenges_status ON group_challenges(status);
CREATE INDEX IF NOT EXISTS idx_group_challenges_end_date ON group_challenges(end_date);

-- ============================================
-- NEW FEATURES TABLES (Weekly Challenges, Streak Protection, Friend Activities)
-- ============================================

-- Daily Goals table
CREATE TABLE IF NOT EXISTS daily_goals (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Weekly Challenges table
CREATE TABLE IF NOT EXISTS weekly_challenges (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Challenge Completions table
CREATE TABLE IF NOT EXISTS challenge_completions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  challenge_id TEXT NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reward INTEGER DEFAULT 0
);

-- Streak Protection table
CREATE TABLE IF NOT EXISTS streak_protection (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  freezes_available INTEGER DEFAULT 1,
  freezes_used INTEGER DEFAULT 0,
  last_freeze_date TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Streak Freezes table
CREATE TABLE IF NOT EXISTS streak_freezes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  streak INTEGER NOT NULL
);

-- Friend Activities table
CREATE TABLE IF NOT EXISTS friend_activities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  activity_type TEXT NOT NULL, -- 'achievement', 'level_up', 'trade', 'streak'
  activity_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily Lessons table
CREATE TABLE IF NOT EXISTS daily_lessons (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- Enable RLS for New Tables
-- ============================================

ALTER TABLE daily_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_challenge_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_quest_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_quest_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE streak_protection ENABLE ROW LEVEL SECURITY;
ALTER TABLE streak_freezes ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Security Policies for New Tables
-- ============================================

DO $$ 
BEGIN
  -- Daily Goals: Users can only access their own
  DROP POLICY IF EXISTS "Users can manage own daily goals" ON daily_goals;
  CREATE POLICY "Users can manage own daily goals" ON daily_goals
    FOR ALL USING (auth.uid() = user_id);

  -- Weekly Challenges: Users can only access their own
  DROP POLICY IF EXISTS "Users can manage own weekly challenges" ON weekly_challenges;
  CREATE POLICY "Users can manage own weekly challenges" ON weekly_challenges
    FOR ALL USING (auth.uid() = user_id);

  -- Challenge Completions: Users can only access their own
  DROP POLICY IF EXISTS "Users can manage own challenge completions" ON challenge_completions;
  CREATE POLICY "Users can manage own challenge completions" ON challenge_completions
    FOR ALL USING (auth.uid() = user_id);

  -- Monthly challenges: Users can only access their own
  DROP POLICY IF EXISTS "Users can manage own monthly challenges" ON monthly_challenges;
  CREATE POLICY "Users can manage own monthly challenges" ON monthly_challenges
    FOR ALL USING (auth.uid() = user_id);

  DROP POLICY IF EXISTS "Users can manage own monthly challenge completions" ON monthly_challenge_completions;
  CREATE POLICY "Users can manage own monthly challenge completions" ON monthly_challenge_completions
    FOR ALL USING (auth.uid() = user_id);

  -- Friend quests: Users can only access their own
  DROP POLICY IF EXISTS "Users can manage own friend quests" ON friend_quests;
  CREATE POLICY "Users can manage own friend quests" ON friend_quests
    FOR ALL USING (auth.uid() = user_id);

  -- Friend quest progress: Users can read their own and partner's progress
  DROP POLICY IF EXISTS "Users can read friend quest progress" ON friend_quest_progress;
  CREATE POLICY "Users can read friend quest progress" ON friend_quest_progress
    FOR SELECT USING (
      auth.uid() = user_id OR
      EXISTS (
        SELECT 1 FROM friend_quests fq
        WHERE fq.user_id = auth.uid()
        AND (fq.data->>'partnerId')::text = user_id::text
      )
    );

  DROP POLICY IF EXISTS "Users can update own friend quest progress" ON friend_quest_progress;
  CREATE POLICY "Users can update own friend quest progress" ON friend_quest_progress
    FOR ALL USING (auth.uid() = user_id);

  DROP POLICY IF EXISTS "Users can manage own friend quest completions" ON friend_quest_completions;
  CREATE POLICY "Users can manage own friend quest completions" ON friend_quest_completions
    FOR ALL USING (auth.uid() = user_id);

  -- Streak Protection: Users can only access their own
  DROP POLICY IF EXISTS "Users can manage own streak protection" ON streak_protection;
  CREATE POLICY "Users can manage own streak protection" ON streak_protection
    FOR ALL USING (auth.uid() = user_id);

  -- Streak Freezes: Users can only access their own
  DROP POLICY IF EXISTS "Users can manage own streak freezes" ON streak_freezes;
  CREATE POLICY "Users can manage own streak freezes" ON streak_freezes
    FOR ALL USING (auth.uid() = user_id);

  -- Friend Activities: Users can read their friends' activities, write their own
  DROP POLICY IF EXISTS "Users can read friend activities" ON friend_activities;
  CREATE POLICY "Users can read friend activities" ON friend_activities
    FOR SELECT USING (
      auth.uid() = user_id OR
      auth.uid() IN (
        SELECT friend_id FROM friends WHERE user_id = friend_activities.user_id AND status = 'accepted'
        UNION
        SELECT user_id FROM friends WHERE friend_id = friend_activities.user_id AND status = 'accepted'
      )
    );

  DROP POLICY IF EXISTS "Users can create own activities" ON friend_activities;
  CREATE POLICY "Users can create own activities" ON friend_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

  -- Daily Lessons: Users can only access their own
  DROP POLICY IF EXISTS "Users can manage own daily lessons" ON daily_lessons;
  CREATE POLICY "Users can manage own daily lessons" ON daily_lessons
    FOR ALL USING (auth.uid() = user_id);

  -- Notifications: Users can only access their own
  DROP POLICY IF EXISTS "Users can manage own notifications" ON notifications;
  CREATE POLICY "Users can manage own notifications" ON notifications
    FOR ALL USING (auth.uid() = user_id);
END $$;

-- ============================================
-- Create Indexes for New Tables
-- ============================================

CREATE INDEX IF NOT EXISTS idx_challenge_completions_user_id ON challenge_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_completions_challenge_id ON challenge_completions(challenge_id);

-- Monthly challenge indexes
CREATE INDEX IF NOT EXISTS idx_monthly_challenges_user_id ON monthly_challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_monthly_challenge_completions_user_id ON monthly_challenge_completions(user_id);

-- Friend quest indexes
CREATE INDEX IF NOT EXISTS idx_friend_quests_user_id ON friend_quests(user_id);
CREATE INDEX IF NOT EXISTS idx_friend_quest_progress_quest_id ON friend_quest_progress(quest_id);
CREATE INDEX IF NOT EXISTS idx_friend_quest_progress_user_id ON friend_quest_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_friend_quest_completions_user_id ON friend_quest_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_streak_freezes_user_id ON streak_freezes(user_id);
CREATE INDEX IF NOT EXISTS idx_streak_freezes_used_at ON streak_freezes(used_at DESC);
CREATE INDEX IF NOT EXISTS idx_friend_activities_user_id ON friend_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_friend_activities_type ON friend_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_friend_activities_created_at ON friend_activities(created_at DESC);

-- ============================================
-- DYNAMIC LESSONS SYSTEM
-- ============================================

-- Lessons table - stores all lesson content dynamically
CREATE TABLE IF NOT EXISTS lessons (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  content JSONB NOT NULL, -- Complete lesson data (steps, questions, quizzes, etc.)
  learning_actions JSONB, -- Taking action slides, missions, tasks, polls
  category TEXT,
  difficulty TEXT,
  duration INTEGER, -- minutes
  xp_reward INTEGER DEFAULT 150,
  icon TEXT,
  badge TEXT,
  badge_emoji TEXT,
  color TEXT,
  order_index INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  version INTEGER DEFAULT 1, -- Increment when updating
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Lesson versions table (for update tracking)
CREATE TABLE IF NOT EXISTS lesson_versions (
  id SERIAL PRIMARY KEY,
  version INTEGER NOT NULL UNIQUE,
  total_lessons INTEGER NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User lesson progress (tracks completion, XP earned, etc.)
CREATE TABLE IF NOT EXISTS user_lesson_progress (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  xp_earned INTEGER DEFAULT 0,
  score INTEGER DEFAULT 0, -- Percentage score
  perfect_score BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  progress_data JSONB, -- Store step progress, answers, etc.
  PRIMARY KEY (user_id, lesson_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_lessons_active ON lessons(is_active, order_index);
CREATE INDEX IF NOT EXISTS idx_lessons_category ON lessons(category);
CREATE INDEX IF NOT EXISTS idx_lessons_difficulty ON lessons(difficulty);
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_user_id ON user_lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_lesson_id ON user_lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_completed ON user_lesson_progress(user_id, is_completed);

-- RLS Policies
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_lesson_progress ENABLE ROW LEVEL SECURITY;

-- Lessons: Anyone can read active lessons
DROP POLICY IF EXISTS "Anyone can read active lessons" ON lessons;
CREATE POLICY "Anyone can read active lessons" ON lessons
  FOR SELECT USING (is_active = true);

-- Lesson versions: Anyone can read
DROP POLICY IF EXISTS "Anyone can read lesson versions" ON lesson_versions;
CREATE POLICY "Anyone can read lesson versions" ON lesson_versions
  FOR SELECT USING (true);

-- User lesson progress: Users can only access their own
DROP POLICY IF EXISTS "Users can manage own lesson progress" ON user_lesson_progress;
CREATE POLICY "Users can manage own lesson progress" ON user_lesson_progress
  FOR ALL USING (auth.uid() = user_id);

-- Insert initial version
INSERT INTO lesson_versions (version, total_lessons) 
VALUES (1, 0) 
ON CONFLICT (version) DO NOTHING;

-- ============================================
-- DONE! Your database is ready
-- ============================================

