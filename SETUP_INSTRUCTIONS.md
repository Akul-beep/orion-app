# 🚀 Dynamic Lessons System - Setup Instructions

## ✅ What's Already Done

All code is complete and ready! The system will:
- ✅ Work with your existing 30 hardcoded lessons (no changes needed)
- ✅ Automatically use Supabase lessons once you set it up
- ✅ Fall back to hardcoded lessons if Supabase is unavailable
- ✅ Cache lessons locally for offline support

## 📋 What YOU Need to Do (2 Simple Steps)

### Step 1: Run SQL in Supabase Dashboard ⚠️ REQUIRED

1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **SQL Editor**
4. Open the file: `supabase_setup.sql`
5. Scroll to the bottom (around line 690)
6. Copy and paste **ONLY the new tables section** (from `-- DYNAMIC LESSONS SYSTEM` to the end)
7. Click **Run**

The SQL you need to run:
```sql
-- DYNAMIC LESSONS SYSTEM
CREATE TABLE IF NOT EXISTS lessons (...);
CREATE TABLE IF NOT EXISTS lesson_versions (...);
CREATE TABLE IF NOT EXISTS user_lesson_progress (...);
-- ... (all the tables, indexes, and policies)
```

**OR** just run the entire `supabase_setup.sql` file if you haven't already (it's safe to run multiple times).

### Step 2: Upload Your 30 Lessons ⚠️ REQUIRED (One Time)

You have **2 options**:

#### Option A: Add a Migration Button (Recommended)

Add this to a settings screen or admin panel:

```dart
import 'package:orion_screens/services/lesson_migration_helper.dart';

// In your settings screen:
ElevatedButton(
  onPressed: () async {
    final result = await LessonMigrationHelper.uploadLessonsToSupabase();
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Uploaded ${result['uploaded']} lessons!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${result['error']}')),
      );
    }
  },
  child: Text('Upload Lessons to Supabase'),
)
```

#### Option B: Run Migration Script Directly

1. Open `lib/services/lesson_migration_helper.dart`
2. Call `LessonMigrationHelper.uploadLessonsToSupabase()` from your app
3. Check console logs for progress

## 🎯 That's It!

After these 2 steps:
- ✅ Your app will use Supabase lessons
- ✅ You can add new lessons via Supabase dashboard (no app update!)
- ✅ Everything works offline with cached lessons
- ✅ Falls back to hardcoded lessons if Supabase is down

## 🧪 Testing

1. **Test with hardcoded lessons** (before migration):
   - App should work exactly as before
   - All 30 lessons available

2. **Test after migration**:
   - App should fetch from Supabase
   - Check console logs: `📚 Loaded X lessons from Supabase`
   - Lessons should be identical to before

3. **Test offline**:
   - Turn off internet
   - App should use cached lessons
   - Should work perfectly

## 📝 Adding New Lessons Later

1. Go to Supabase Dashboard → Table Editor → `lessons`
2. Click "Insert row"
3. Fill in lesson data (see `DYNAMIC_LESSONS_IMPLEMENTATION.md` for details)
4. Increment version:
   ```sql
   UPDATE lesson_versions 
   SET version = version + 1, 
       total_lessons = (SELECT COUNT(*) FROM lessons WHERE is_active = true);
   ```
5. Users get new lessons automatically! 🎉

## ❓ Troubleshooting

**Q: App still uses hardcoded lessons?**
- Check if Supabase tables exist (Step 1)
- Check if lessons were uploaded (Step 2)
- Check console logs for errors

**Q: Migration fails?**
- Make sure Supabase is initialized
- Check you're logged in (if RLS requires auth)
- Check console for specific error messages

**Q: Lessons not updating?**
- Check `lesson_versions` table - version should increment
- Clear app cache and restart
- Check `is_active = true` for lessons

## ✅ Verification Checklist

- [ ] SQL tables created in Supabase
- [ ] 30 lessons uploaded to Supabase
- [ ] App loads lessons from Supabase (check console)
- [ ] Offline mode works (cached lessons)
- [ ] Can add new lesson via Supabase dashboard

---

**Everything else is done!** Just these 2 steps and you're ready to go! 🚀

