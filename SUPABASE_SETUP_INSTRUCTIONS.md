# Supabase Database Setup Instructions

## Quick Setup

1. **Go to your Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project

2. **Open SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Run the Setup Script**
   - Copy the entire contents of `supabase_setup.sql`
   - Paste it into the SQL Editor
   - Click "Run" or press `Ctrl+Enter` (Windows/Linux) or `Cmd+Enter` (Mac)

## What This Script Creates

### Core Tables
- `portfolio` - User portfolio data
- `trades` - Trade history
- `gamification` - XP, streaks, badges
- `leaderboard` - User rankings
- `user_profiles` - User profile information
- `watchlist` - Stock watchlists
- `daily_goals` - Daily goal tracking
- `weekly_challenges` - Weekly challenge system
- `streak_protection` - Streak freeze system
- `friend_activities` - Friend activity feed

### Security
- Row Level Security (RLS) enabled on all tables
- Policies ensure users can only access their own data
- Leaderboard is readable by all, but only updatable by the owner

### Indexes
- Performance indexes on frequently queried columns
- Optimized for leaderboard sorting and user lookups

## Verification

After running the script, verify the tables were created:

1. Go to "Table Editor" in Supabase Dashboard
2. You should see all the tables listed above
3. Check that RLS is enabled (lock icon should be visible)

## Troubleshooting

### Error: "relation already exists"
- This means some tables already exist
- The script uses `CREATE TABLE IF NOT EXISTS`, so it's safe to run multiple times
- You can ignore this error or drop existing tables if needed

### Error: "permission denied"
- Make sure you're running the script as a database admin
- Check your Supabase project permissions

### RLS Policies Not Working
- Make sure RLS is enabled on the tables
- Check that policies are created correctly
- Verify user authentication is working

## Next Steps

1. **Test the Connection**
   - Run the app and verify data is saving/loading
   - Check Supabase logs for any errors

2. **Monitor Usage**
   - Use Supabase Dashboard to monitor database usage
   - Check the "Database" section for table sizes and query performance

3. **Backup**
   - Set up automatic backups in Supabase Dashboard
   - Configure backup retention policy

## Support

If you encounter any issues:
1. Check Supabase logs in the Dashboard
2. Verify your Supabase credentials in `main.dart`
3. Ensure your Supabase project is active and not paused






