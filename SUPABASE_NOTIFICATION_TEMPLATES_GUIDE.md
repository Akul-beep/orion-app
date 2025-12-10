# 📝 Supabase Notification Templates - Update Guide

## ✅ What's Been Implemented

You can now **update notification messages from Supabase** without needing to update the app code!

## 🗄️ Database Setup

### Step 1: Run the SQL Script

Run `create_notification_templates_table.sql` in your Supabase SQL Editor to create the table and insert default templates.

### Step 2: Verify Table Created

Check that the `notification_templates` table exists with all default templates.

## 📋 How It Works

1. **App fetches templates from Supabase** (with 1-hour caching)
2. **Falls back to hardcoded messages** if Supabase is unavailable
3. **Templates use placeholders** that get replaced with actual values:
   - `{greeting}` → "Hi there" or "Hi [UserName]"
   - `{userName}` → User's display name or "there"
   - `{streak}` → Current streak number

## ✏️ Updating Templates in Supabase

### Via Supabase Dashboard

1. Go to **Table Editor** → `notification_templates`
2. Find the template you want to update
3. Edit the `title_template` or `body_template` fields
4. Save changes
5. Templates will be used within 1 hour (cache expires)

### Via SQL

```sql
-- Update a specific template
UPDATE notification_templates
SET 
  body_template = 'Hi there! It''s Orion 👋 New message here! Complete your daily goals to keep your {streak}-day streak alive!',
  updated_at = NOW()
WHERE id = 'morning_streak_1';

-- Add a new template variant
INSERT INTO notification_templates (id, template_type, character_mood, title_template, body_template, priority)
VALUES (
  'morning_streak_4',
  'morning_streak',
  'friendly',
  'Orion: Your {streak}-day streak',
  'Hi there! It''s Orion 👋 Got 3 minutes? New variant message!',
  4
);

-- Disable a template (won't be used)
UPDATE notification_templates
SET is_active = false
WHERE id = 'morning_streak_1';
```

## 📊 Template Types

| Template Type | Mood | When Used |
|--------------|------|-----------|
| `morning_streak` | friendly | Morning streak reminders (8 AM) |
| `afternoon_learning` | friendly | Afternoon learning reminders (2 PM) |
| `evening_streak` | friendly | Evening streak reminders (8 PM) |
| `streak_at_risk` | concerned | When streak is at risk (20-24 hours inactive) |
| `level_up` | excited | When user levels up |
| `badge_unlocked` | excited | When user unlocks a badge |
| `streak_milestone` | excited | When user reaches streak milestone |
| `proud` | proud | When user maintains consistent progress |

## 🎯 Template Priority

Templates with **higher priority** are used first. If multiple templates match, the one with the highest priority is selected.

## 🔄 Cache Management

- **Cache Duration**: 1 hour
- **Auto-refresh**: Templates refresh automatically after cache expires
- **Manual Clear**: Call `OrionCharacter.clearCache()` to force refresh

## 📝 Template Format

### Placeholders Available

- `{greeting}` - "Hi there" or "Hi [UserName]"
- `{userName}` - User's display name or "there"
- `{streak}` - Current streak number

### Example Template

```sql
body_template: 'Hi there! It''s Orion 👋 Got 3 minutes? Complete your daily goals to keep your {streak}-day streak alive!'
```

When rendered:
- If streak = 7: "Hi there! It's Orion 👋 Got 3 minutes? Complete your daily goals to keep your 7-day streak alive!"
- If userName = "John": "Hi John! It's Orion 👋 Got 3 minutes? Complete your daily goals to keep your 7-day streak alive!"

## 🧪 Testing Updates

1. **Update a template** in Supabase
2. **Wait 1 hour** (or clear cache manually)
3. **Trigger a notification** (e.g., schedule a test notification)
4. **Verify** the new message appears

## 💡 Best Practices

1. **Test templates** before making them active
2. **Keep multiple variants** (priority 1, 2, 3) for variety
3. **Use placeholders** for personalization
4. **Keep messages concise** (notification character limits)
5. **Maintain Orion's personality** (friendly, concerned, excited, proud)

## 🚀 A/B Testing

You can A/B test different messages:

1. Create multiple templates with same `template_type` and `character_mood`
2. Set different priorities
3. System will rotate through them based on priority
4. Track engagement and update priorities accordingly

## 📱 Example: Updating Morning Streak Message

```sql
-- Make morning messages more urgent
UPDATE notification_templates
SET 
  body_template = 'Hi there! It''s Orion 👋 Your {streak}-day streak is waiting! Don''t let it break - complete your goals now!',
  updated_at = NOW()
WHERE template_type = 'morning_streak' AND priority = 1;
```

## ⚠️ Important Notes

- **Cache**: Changes take up to 1 hour to appear (cache TTL)
- **Fallback**: If Supabase is unavailable, hardcoded messages are used
- **Validation**: Make sure templates include placeholders correctly
- **Testing**: Always test on a physical device (notifications don't work on simulator)

---

**Status**: ✅ **Ready to Use**
**Next**: Run the SQL script and start updating templates from Supabase!

