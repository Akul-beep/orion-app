# 🚀 Supabase Setup Guide for Orion App

## Why Supabase?

✅ **Open Source** - Built on PostgreSQL  
✅ **Free Tier** - 500MB database, 2GB bandwidth  
✅ **Google Sign-In** - Built-in OAuth support  
✅ **Email/Password Auth** - Easy to set up  
✅ **Real-time** - Live data updates  
✅ **Better than Firebase** - More flexible, SQL-based  

---

## Step 1: Create Supabase Project

1. Go to [Supabase](https://supabase.com/)
2. Click **"Start your project"** or **"Sign up"**
3. Sign up with GitHub (easiest) or email
4. Click **"New Project"**
5. Fill in:
   - **Name**: `orion-trading-app` (or your choice)
   - **Database Password**: Create a strong password (SAVE THIS!)
   - **Region**: Choose closest to you
   - **Pricing Plan**: Free (for now)
6. Click **"Create new project"**
7. Wait 2-3 minutes for setup

---

## Step 2: Get Your Credentials

1. In your Supabase project dashboard, click **"Settings"** (gear icon)
2. Click **"API"** in the left sidebar
3. You'll see:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

**COPY THESE - You'll need them!**

---

## Step 3: Enable Google OAuth

1. In Supabase dashboard, go to **"Authentication"** → **"Providers"**
2. Find **"Google"** and click it
3. Click **"Enable Google provider"**
4. You'll need to create OAuth credentials:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project (or use existing)
   - Enable Google+ API
   - Create OAuth 2.0 credentials
   - Add authorized redirect URI: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`
   - Copy **Client ID** and **Client Secret**
5. Paste them into Supabase Google provider settings
6. Click **"Save"**

---

## Step 4: Create Database Tables

1. In Supabase dashboard, go to **"SQL Editor"**
2. Click **"New query"**
3. Paste this SQL and click **"Run"**:

```sql
-- Portfolio table
CREATE TABLE IF NOT EXISTS portfolio (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trades table
CREATE TABLE IF NOT EXISTS trades (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  trade_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Gamification table
CREATE TABLE IF NOT EXISTS gamification (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Completed actions table
CREATE TABLE IF NOT EXISTS completed_actions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  action_id TEXT NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, action_id)
);

-- Leaderboard table
CREATE TABLE IF NOT EXISTS leaderboard (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  display_name TEXT NOT NULL,
  xp INTEGER DEFAULT 0,
  streak INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  badges INTEGER DEFAULT 0,
  avatar TEXT DEFAULT '🎯',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Watchlist table
CREATE TABLE IF NOT EXISTS watchlist (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  symbols TEXT[] NOT NULL DEFAULT '{}',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Stock cache table
CREATE TABLE IF NOT EXISTS stock_cache (
  cache_key TEXT PRIMARY KEY,
  cache_data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE gamification ENABLE ROW LEVEL SECURITY;
ALTER TABLE completed_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_cache ENABLE ROW LEVEL SECURITY;

-- Create policies (users can only access their own data)
CREATE POLICY "Users can manage own portfolio" ON portfolio
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own trades" ON trades
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own gamification" ON gamification
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own completed actions" ON completed_actions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can read all leaderboard" ON leaderboard
  FOR SELECT USING (true);

CREATE POLICY "Users can update own leaderboard" ON leaderboard
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own leaderboard" ON leaderboard
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage own profile" ON user_profiles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own watchlist" ON watchlist
  FOR ALL USING (auth.uid() = user_id);

-- Stock cache is SHARED across all users (stock data is the same for everyone)
-- Allow public read access (anyone can read cached stock data)
CREATE POLICY "Anyone can read stock cache" ON stock_cache
  FOR SELECT USING (true);

-- Only authenticated users can write to cache (to prevent abuse)
CREATE POLICY "Authenticated users can write cache" ON stock_cache
  FOR INSERT, UPDATE USING (auth.role() = 'authenticated');
```

4. Click **"Run"** - You should see "Success. No rows returned"

---

## Step 5: Configure Flutter App

1. **Open `lib/main.dart`**
2. **Find the commented Supabase initialization** (around line 15)
3. **Replace with your credentials**:

```dart
await Supabase.initialize(
  url: 'https://YOUR_PROJECT_ID.supabase.co',  // Your Project URL
  anonKey: 'YOUR_ANON_KEY_HERE',                // Your anon/public key
);
print('✅ Supabase initialized successfully');
```

4. **Uncomment the Supabase initialization code**

---

## Step 6: Install Dependencies

Run in terminal:
```bash
cd "/Users/akulnehra/Desktop/Orion Cursor/OrionScreens-master"
flutter pub get
```

---

## Step 7: Test It!

Run your app:
```bash
flutter run -d chrome
```

You should see: `✅ Supabase initialized successfully` in the console.

Try signing up with email or Google!

---

## What You Get

✅ **Email/Password Authentication**  
✅ **Google Sign-In** (after OAuth setup)  
✅ **Cloud Database** (PostgreSQL)  
✅ **Real-time Sync** (when online)  
✅ **Offline Support** (local storage fallback)  
✅ **Free Tier** (500MB database, 2GB bandwidth)  

---

## Troubleshooting

### "Invalid API key"
- Check your Project URL and anon key are correct
- Make sure you copied the **anon/public** key, not the service_role key

### "Google sign-in not working"
- Make sure you enabled Google provider in Supabase
- Check OAuth redirect URI matches exactly
- Verify Google Cloud credentials are correct

### "Table doesn't exist"
- Run the SQL script again in SQL Editor
- Check table names match exactly

### "Permission denied"
- Check RLS policies are created
- Verify user is authenticated

---

## Summary Checklist

- [ ] Created Supabase account
- [ ] Created new project
- [ ] Copied Project URL and anon key
- [ ] Enabled Google OAuth provider
- [ ] Created all database tables (SQL script)
- [ ] Set up RLS policies
- [ ] Updated `main.dart` with credentials
- [ ] Ran `flutter pub get`
- [ ] Tested the app

---

## Current Status

✅ **App works WITHOUT Supabase** - uses local storage (SharedPreferences)  
✅ **All features work offline**  
✅ **When Supabase is configured**, data will sync to cloud automatically  

---

## Need Help?

- Supabase Docs: https://supabase.com/docs
- Flutter Supabase: https://supabase.com/docs/reference/dart/introduction
- Discord: https://discord.supabase.com/






