# 🔔 How Notifications & Engagement Work

## Overview
This document explains how notifications and engagement features are implemented in the Orion app.

---

## 📱 **Mobile Notifications (iOS/Android)**

### How It Works:
1. **Service**: `PushNotificationService` (uses `flutter_local_notifications` package)
2. **Platform**: Native iOS/Android notification APIs
3. **Scheduling**: Uses `timezone` package for timezone-aware scheduling

### Features:
- ✅ **Local Notifications**: Scheduled on the device
- ✅ **Background Notifications**: Work even when app is closed
- ✅ **Rich Notifications**: Images, sounds, actions
- ✅ **Scheduled Notifications**: Daily reminders at specific times
- ✅ **Streak-at-Risk**: Urgent notifications when streak is about to break

### Notification Types:
1. **Streak Reminders**: 2-3 times per day (morning, afternoon, evening)
2. **Learning Reminders**: Encourage lesson completion
3. **Market Open**: Daily at 9:30 AM (weekdays)
4. **Achievement Notifications**: Level ups, badges, milestones
5. **Streak-at-Risk**: Urgent when inactive 20-24 hours

---

## 🌐 **Web Notifications (Browser)**

### How It Works:
1. **Service**: `WebNotificationService` (uses `dart:html` for browser APIs)
2. **API**: Browser Notification API (`window.Notification`)
3. **Scheduling**: Uses `setTimeout` (only works while tab is open)

### Implementation:
```dart
// Check if browser supports notifications
if (html.Notification.supported) {
  // Request permission (must be from user interaction)
  final permission = await html.Notification.requestPermission();
  
  // Show notification
  final notification = html.Notification(
    'Title',
    html.NotificationOptions()..body = 'Message',
  );
}
```

### Features:
- ✅ **Browser Notifications**: Native browser notifications
- ✅ **Permission Management**: Request and check permissions
- ✅ **Click Handling**: Open app when notification clicked
- ✅ **Auto-close**: Notifications close after 5 seconds
- ⚠️ **Limitation**: Scheduled notifications only work while tab is open

### Permission Flow:
1. User clicks "Enable Notifications" button
2. Browser shows permission dialog
3. If granted, notifications are enabled
4. Preference saved to database

### Scheduling Limitations:
- **While Tab Open**: Works perfectly using `setTimeout`
- **Tab Closed**: Doesn't work (need Service Worker for background)
- **Solution**: Check on app open if scheduled notifications should have fired

---

## 🎯 **User Engagement Service**

### How It Works:
1. **Service**: `UserEngagementService`
2. **Tracking**: Stores user behavior in database
3. **Segmentation**: Automatically categorizes users into segments

### User Segments:
- **New User**: < 1 day since install
- **Beginner**: 1-7 days active
- **Active**: Regular user
- **Engaged**: 14+ sessions
- **Loyal**: 30+ days, high engagement
- **At Risk**: 7+ days inactive
- **Churned**: 30+ days inactive

### What It Tracks:
- Session start times
- Last activity timestamp
- Total sessions
- Days since install
- User preferences from onboarding

### Personalization:
- Different messages per segment
- Recommended actions per segment
- Notification frequency per segment
- Customized experiences

---

## 🎨 **Daily Engagement Hook Widget**

### How It Works:
1. **Widget**: `DailyEngagementHookWidget`
2. **Location**: Dashboard (ProfessionalDashboard)
3. **States**: 4 different visual states based on user status

### States:
1. **Celebration**: All goals complete (green gradient)
2. **Streak At Risk**: Urgent call-to-action (orange gradient)
3. **Active Streak**: Motivation to maintain (orange gradient)
4. **Motivation**: Encouragement for new users (blue)

### When It Shows:
- Always visible on dashboard
- Updates in real-time based on goals/streak
- Personalized messages from engagement service

---

## ⚙️ **How Everything Works Together**

### 1. **App Startup**:
```
Dashboard loads
  ↓
Engagement services initialize
  ↓
Track session start
  ↓
Check for scheduled notifications
  ↓
Display engagement hook widget
```

### 2. **Daily Notifications**:
```
User opens app
  ↓
Check if notifications enabled
  ↓
Schedule notifications for today
  ↓
Save to database
  ↓
setTimeout schedules (web) OR timezone schedules (mobile)
```

### 3. **Streak-at-Risk Detection**:
```
Check last activity time
  ↓
Calculate hours since activity
  ↓
If 20-24 hours → Send urgent notification
  ↓
User sees notification
  ↓
Opens app to protect streak
```

### 4. **Re-engagement Campaigns**:
```
User returns after inactivity
  ↓
Check days since last activity
  ↓
If 3+ days → Trigger re-engagement campaign
  ↓
Show personalized message
  ↓
Send notification if enabled
```

---

## 🔧 **Technical Details**

### Web Notifications:
- **API**: `dart:html` (Flutter Web built-in)
- **Permission**: Browser-native permission dialog
- **Storage**: Preferences saved to Supabase/local database
- **Limitation**: No background notifications (need Service Worker)

### Mobile Notifications:
- **Package**: `flutter_local_notifications`
- **Platform**: iOS NotificationCenter / Android NotificationManager
- **Scheduling**: `timezone` package for accurate timing
- **Background**: Works even when app is closed

### Engagement Tracking:
- **Storage**: Supabase database (`user_progress` table)
- **Data**: Session counts, timestamps, preferences
- **Real-time**: Updates on every app interaction

### Personalization:
- **Data Source**: Onboarding preferences + behavior tracking
- **Segmentation**: Automatic based on activity patterns
- **Messages**: Pre-written templates per segment
- **Dynamic**: Adjusts as user behavior changes

---

## 📊 **Notification Schedule**

### Daily Schedule:
| Time | Type | Platform | Works When |
|------|------|----------|------------|
| 8:00 AM | Morning Streak | Both | Tab open (web) / Always (mobile) |
| 2:00 PM | Learning Reminder | Both | Tab open (web) / Always (mobile) |
| 8:00 PM | Evening Streak | Both | Tab open (web) / Always (mobile) |
| 9:30 AM | Market Open | Weekdays | Tab open (web) / Always (mobile) |
| Variable | Streak-at-Risk | Both | When inactive 20-24h |

---

## 🚀 **Future Enhancements**

### For Web:
1. **Service Worker**: Enable background notifications
2. **Push API**: Real push notifications from server
3. **Web Push Protocol**: True background notifications

### For Engagement:
1. **A/B Testing**: Test different messages
2. **Machine Learning**: Predict user churn
3. **Email Integration**: Re-engagement emails
4. **Deep Linking**: Direct links from notifications

---

## 💡 **Usage Tips**

### For Users:
- **Enable Notifications**: Click the "Enable Notifications" button when prompted
- **Allow Permissions**: Browser will ask for permission (must allow)
- **Keep Tab Open**: For web, scheduled notifications work while tab is open
- **Daily Check-in**: Open app daily to maintain streak

### For Developers:
- **Web Limitations**: Remember web notifications only work while tab is open
- **Permission Timing**: Request permission from user interaction (button click)
- **Testing**: Use browser dev tools to test notifications
- **Tracking**: All notifications are logged to database for analytics

---

**Last Updated**: January 2025
**Status**: ✅ Fully Implemented and Working


