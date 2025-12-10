# 🚀 Orion App Store Readiness - Complete TODO List

## Target Audience: High Schoolers Learning Trading

This comprehensive list covers everything needed to publish Orion on the App Store and provide an excellent experience for high school students learning about trading.

---

## 🔴 CRITICAL ISSUES (Must Fix Before Launch)

### 1. **Fix Trading Indicators Mock Data** ⚠️ HIGH PRIORITY
**Problem**: When Finnhub API fails, backend returns fake/mock indicator data (RSI, MACD, SMA) instead of real data or proper error handling.

**Location**: 
- `backend.py` lines 193-200 (mock data fallback)
- `lib/widgets/stock_detail_v6/technical_indicators_list.dart` (hardcoded values)

**Fix Required**:
- Remove mock data fallback in `backend.py`
- Show proper error messages when API fails
- Use cached data if available
- Display "Data unavailable" instead of fake numbers

**Impact**: Users see incorrect trading signals, which is dangerous for learning.

---

### 2. **Fix Learning Actions - All Same/Wrong** ⚠️ HIGH PRIORITY
**Problem**: Most lessons show the same default actions because `SmartLearningActions` only has actions for 8 lessons, while there are 30 lessons total.

**Location**: 
- `lib/services/learning_action_service.dart` line 28 (uses SmartLearningActions)
- `lib/data/smart_learning_actions.dart` (only 8 lessons defined)
- `lib/data/learning_actions_content.dart` (has all 30 days but not used)

**Fix Required**:
- Option A: Add all 30 lesson actions to `SmartLearningActions`
- Option B: Change `LearningActionService` to use `LearningActionsContent` instead
- Ensure each lesson has unique, relevant actions

**Impact**: Users get repetitive, irrelevant tasks that don't match their current lesson.

---

### 3. **Implement Push Notifications** ⚠️ HIGH PRIORITY
**Problem**: `NotificationManager` only handles in-app notifications. No push notifications for:
- Daily lesson reminders
- Streak protection warnings
- Price alerts
- Achievement unlocks
- Friend activity

**Location**: 
- `lib/services/notification_manager.dart` (in-app only)
- `pubspec.yaml` has `flutter_local_notifications` but not configured

**Fix Required**:
- Set up `flutter_local_notifications` properly
- Request iOS/Android notification permissions
- Schedule daily reminders (e.g., "Keep your streak alive!")
- Implement price alert notifications
- Add notification handlers for deep linking

**Impact**: Lower user engagement, users miss lessons, lose streaks.

---

### 4. **Fix Paper Trading Mock Prices** ⚠️ MEDIUM PRIORITY
**Problem**: When API fails, paper trading uses fake prices (`_getMockPrice` method) instead of showing errors.

**Location**:
- `lib/services/paper_trading_service.dart` lines 580-597 (mock prices)
- `lib/screens/paper_trading_screen.dart` lines 1112-1131 (mock price fallback)

**Fix Required**:
- Remove `_getMockPrice` method
- Show "Price unavailable" when API fails
- Use last known cached price with timestamp
- Disable trading when price data unavailable

**Impact**: Users trade with fake prices, learn wrong concepts.

---

## 🟡 IMPORTANT FEATURES (Should Have)

### 5. **Complete Technical Indicators Implementation**
**Status**: Only RSI is fetched. MACD, SMA, Bollinger Bands widgets exist but need real data.

**Fix Required**:
- Fetch MACD, SMA, Bollinger Bands from Finnhub API
- Integrate with `indicators_tab.dart` widget
- Add proper error handling
- Cache indicator data (5-10 min TTL)

---

### 6. **Verify Database Schema**
**Status**: SQL schema exists but may not be applied to Supabase.

**Fix Required**:
- Run `supabase_setup.sql` in Supabase SQL Editor
- Verify all tables exist:
  - `portfolio`, `trades`, `gamification`
  - `completed_actions`, `leaderboard`
  - `user_profiles`, `watchlist`
  - `daily_goals`, `weekly_challenges`
  - `notifications`, `friend_activities`
  - `streak_protection`, `daily_lessons`
- Test RLS (Row Level Security) policies
- Verify indexes are created

---

### 7. **Add Error Handling for API Failures**
**Status**: API failures cause crashes or show mock data.

**Fix Required**:
- Add try-catch blocks with user-friendly messages
- Show "Network error - please try again" instead of crashes
- Implement retry logic (max 3 attempts)
- Add offline mode indicators
- Cache last successful data

---

### 8. **Fix Learning Action Verification**
**Status**: `LearningActionVerifier` may not properly verify actions are completed.

**Fix Required**:
- Verify trades were actually made (check `PaperTradingService`)
- Verify watch time requirements (30 seconds minimum)
- Verify portfolio checks were done
- Prevent auto-completion without actual action

---

### 9. **Implement Price Alerts**
**Status**: Feature doesn't exist.

**Fix Required**:
- Add "Set Price Alert" button in stock detail screen
- Store alerts in database (`price_alerts` table)
- Background service to check prices
- Send push notification when target hit
- Allow multiple alerts per stock

---

### 10. **Fix Social Features**
**Status**: Friends screen shows mock data.

**Location**: `lib/screens/social/friends_screen.dart` line 660

**Fix Required**:
- Implement real friend requests (send/accept/decline)
- Show real friend activity feed
- Add friend search functionality
- Link with leaderboard

---

## 🟢 NICE TO HAVE (Can Add Post-Launch)

### 11. **Add Analytics & Crash Reporting**
- Set up Firebase Crashlytics or Sentry
- Track key events: lessons completed, trades made, time spent
- Monitor API usage, error rates
- User retention metrics

---

### 12. **Optimize API Usage**
**Status**: May hit Finnhub rate limits (60 calls/day free tier).

**Fix Required**:
- Better caching (already 5min, consider 10min for profiles)
- Batch requests when possible
- Show API usage counter in dev mode
- Warn users when approaching limit

---

### 13. **Add Offline Mode Support**
**Status**: App may crash or show errors when offline.

**Fix Required**:
- Show cached data with "Last updated" timestamp
- Disable features requiring network (trading, new data)
- Clear offline indicators
- Sync when back online

---

### 14. **Add User Onboarding Improvements**
**Status**: Onboarding exists but may not be optimal for high schoolers.

**Fix Required**:
- Add tooltips and help text
- Simplify language for younger audience
- Add video tutorials
- Test with actual high school students

---

## 📱 APP STORE REQUIREMENTS

### 15. **App Store Metadata**
**Required**:
- [ ] App screenshots (6.5", 5.5" iPhone sizes)
- [ ] App preview video (optional but recommended)
- [ ] App description (compelling, clear value prop)
- [ ] Keywords (trading, stocks, learning, finance, education)
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] App icon (1024x1024px)

---

### 16. **iOS Build Configuration**
**Check**:
- [ ] `Info.plist` has notification permissions
- [ ] Bundle identifier is set correctly
- [ ] Version matches `pubspec.yaml` (1.0.0+1)
- [ ] Build number increments for each release
- [ ] Signing certificates configured
- [ ] App Store Connect app created

---

### 17. **Privacy Policy & Terms**
**Required by App Store**:
- [ ] Privacy policy explaining:
  - Data collection (Supabase, analytics)
  - How data is used
  - Data sharing (if any)
  - User rights
- [ ] Terms of service
- [ ] Link in app settings screen

---

### 18. **Testing**
**Before Submission**:
- [ ] Test on physical iPhone/iPad
- [ ] Test all user flows end-to-end
- [ ] Test notifications
- [ ] Test offline mode
- [ ] Test with slow network
- [ ] Check for memory leaks
- [ ] Verify no crashes
- [ ] Test with real high school students

---

## 🎯 PRIORITY ORDER

### Week 1 (Critical)
1. Fix Learning Actions (all same issue)
2. Fix Trading Indicators mock data
3. Implement push notifications
4. Fix paper trading mock prices

### Week 2 (Important)
5. Verify database schema
6. Complete technical indicators
7. Add error handling
8. Fix learning action verification

### Week 3 (Polish)
9. Implement price alerts
10. Fix social features
11. Add analytics
12. Optimize API usage

### Week 4 (App Store Prep)
13. App Store metadata
14. Privacy policy & terms
15. Final testing
16. Submit to App Store

---

## 📊 DATABASE CHECKLIST

Run this SQL in Supabase to verify all tables exist:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

**Expected Tables**:
- ✅ portfolio
- ✅ trades
- ✅ gamification
- ✅ completed_actions
- ✅ leaderboard
- ✅ user_profiles
- ✅ watchlist
- ✅ stock_cache
- ✅ daily_goals
- ✅ weekly_challenges
- ✅ notifications
- ✅ friend_activities
- ✅ streak_protection
- ✅ daily_lessons
- ✅ friends
- ✅ group_challenges
- ✅ user_preferences
- ✅ learning_progress
- ✅ trading_activity

---

## 🔍 CODE QUALITY CHECKS

Before submitting:
- [ ] No `print()` statements (use proper logging)
- [ ] No hardcoded API keys (use environment variables)
- [ ] No mock data in production code
- [ ] All errors handled gracefully
- [ ] Loading states for all async operations
- [ ] Proper null safety
- [ ] No memory leaks
- [ ] Performance optimized

---

## 📝 NOTES

- **Target Audience**: High schoolers need simple, clear instructions
- **Pain Points**: 
  - Complex trading concepts → Simplify with examples
  - Boring lessons → Make interactive and gamified
  - Fear of losing money → Emphasize paper trading safety
  - Lack of motivation → Daily streaks, achievements, social features
- **Key Features for Success**:
  - Daily lessons (Duolingo-style)
  - Paper trading simulator
  - Gamification (XP, levels, badges)
  - Social features (friends, leaderboard)
  - Push notifications (engagement)

---

## ✅ COMPLETION CHECKLIST

Before App Store submission, ensure:
- [ ] All critical issues fixed
- [ ] All important features implemented
- [ ] Database schema verified
- [ ] Push notifications working
- [ ] No mock data in production
- [ ] Error handling comprehensive
- [ ] Privacy policy published
- [ ] App tested on real devices
- [ ] App Store metadata complete
- [ ] Ready for review!

---

**Last Updated**: $(date)
**Status**: In Progress
**Target Launch**: ASAP


