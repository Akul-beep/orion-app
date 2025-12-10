# 🔔 How Notifications & Engagement Features Work

## Quick Overview

Your app has **TWO notification systems**:

1. **Mobile (iOS/Android)**: Uses `PushNotificationService` with native notifications
2. **Web (Browser)**: Uses `WebNotificationService` with browser Notification API

---

## 📱 **MOBILE NOTIFICATIONS** (iOS/Android)

### How They Work:
- **Service**: `PushNotificationService` 
- **Package**: `flutter_local_notifications` (Flutter package)
- **Platform APIs**: 
  - iOS: `UNUserNotificationCenter`
  - Android: `NotificationManager`
- **Scheduling**: Uses `timezone` package for accurate time-based scheduling

### Features:
✅ **Background Notifications**: Work even when app is closed  
✅ **Scheduled Notifications**: Daily reminders at specific times  
✅ **Rich Notifications**: Can include images, sounds, actions  
✅ **Streak-at-Risk**: Urgent notifications when streak about to break  

### Notification Types:
1. **Streak Reminders** (2-3x per day)
   - Morning: 8 AM
   - Afternoon: 2 PM  
   - Evening: 8 PM

2. **Market Open** (Weekdays at 9:30 AM)

3. **Achievement Notifications** (Level ups, badges, milestones)

4. **Streak-at-Risk** (When inactive 20-24 hours)

### How It's Scheduled:
```dart
// Uses timezone package for accurate scheduling
final scheduledDate = tz.TZDateTime.from(time, tz.local);
await _notifications.zonedSchedule(
  id,
  title,
  body,
  scheduledDate,
  notificationDetails,
);
```

---

## 🌐 **WEB NOTIFICATIONS** (Browser)

### How They Work:
- **Service**: `WebNotificationService`
- **API**: Browser `Notification` API (`dart:html`)
- **Permission**: Browser-native permission dialog
- **Scheduling**: Uses `setTimeout` (only works while tab is open)

### Implementation:
```dart
// Check if browser supports notifications
if (html.Notification.supported) {
  // Request permission (must be from user interaction)
  final permission = html.Notification.permission;
  
  // Show notification
  final notification = html.Notification(
    'Title',
    html.NotificationOptions()..body = 'Message',
  );
}
```

### ⚠️ **Important Limitations**:
- **Scheduled notifications only work while tab is open**
- **No background notifications** (need Service Worker for that)
- **Permission must be requested from user interaction** (button click)

### How Scheduling Works:
```dart
// Uses setTimeout to schedule (only while tab open)
html.window.setTimeout(() {
  showNotification(title: title, body: body);
}, millisecondsUntilNotification);
```

### Solution for Background:
- When user opens app, check if scheduled notifications should have fired
- If missed, show them immediately
- Or implement Service Worker for true background notifications

---

## 🎯 **USER ENGAGEMENT SERVICE**

### How It Works:
1. **Tracks user behavior**:
   - Session start times
   - Last activity timestamp
   - Total sessions
   - Days since install

2. **Segments users automatically**:
   - New User (< 1 day)
   - Beginner (1-7 days)
   - Active, Engaged, Loyal
   - At Risk (7+ days inactive)
   - Churned (30+ days inactive)

3. **Personalizes experience**:
   - Different messages per segment
   - Recommended actions
   - Notification frequency adjustment

### What It Does:
- **On App Start**: Tracks session, checks for re-engagement
- **On Activity**: Records activity timestamp and type
- **Detects Inactivity**: Identifies users at risk of churning
- **Triggers Campaigns**: Sends re-engagement notifications

---

## 🎨 **DAILY ENGAGEMENT HOOK WIDGET**

### Location:
- **Dashboard** (`ProfessionalDashboard`)
- Shows at top of dashboard (below header)

### How It Works:
1. **Checks user state**:
   - Are all goals complete?
   - Is streak at risk?
   - What's the current streak?
   - What's the user segment?

2. **Displays appropriate hook**:
   - **Celebration** (green): All goals done
   - **Streak At Risk** (orange): Urgent action needed
   - **Active Streak** (orange): Motivation to maintain
   - **Motivation** (blue): Encouragement for new users

3. **Provides direct action**:
   - Button navigates to Learn screen
   - Personalized message
   - Visual urgency indicators

---

## ⚙️ **HOW IT ALL CONNECTS**

### Flow Diagram:

```
User Opens App
    ↓
Dashboard Loads
    ↓
Engagement Services Initialize:
  - Track session start
  - Check inactivity
  - Load user segment
  - Schedule notifications
    ↓
Engagement Hook Widget Shows:
  - Checks goals/streak status
  - Displays appropriate hook
  - Shows personalized message
    ↓
User Interacts:
  - Completes lesson → Activity tracked
  - Makes trade → Activity tracked
  - Checks leaderboard → Activity tracked
    ↓
Services Respond:
  - Update engagement metrics
  - Adjust user segment if needed
  - Send notifications if scheduled
```

---

## 🔄 **NOTIFICATION FLOW**

### Mobile:
```
App Starts → NotificationScheduler.initialize()
    ↓
Check if notifications enabled
    ↓
Schedule all notifications for today
    ↓
Save to timezone scheduler
    ↓
Notifications fire at scheduled times
    ↓
Even if app is closed! ✅
```

### Web:
```
App Starts → WebNotificationService.scheduleDailyNotifications()
    ↓
Check if notifications enabled
    ↓
Calculate times for today
    ↓
Use setTimeout for each notification
    ↓
Notifications fire at scheduled times
    ↓
Only if tab is still open ⚠️
```

---

## 📊 **DATA STORAGE**

### Where Data Is Stored:
- **Supabase Database**: User progress, preferences, activity
- **Local Storage**: Notification preferences, permission status
- **Service State**: Current notifications, scheduling info

### What Gets Tracked:
- Session start times
- Last activity timestamps
- Total sessions count
- Days since install
- User preferences (from onboarding)
- Notification history

---

## 💡 **KEY POINTS**

### Mobile:
- ✅ Works in background
- ✅ Accurate scheduling
- ✅ Rich notifications
- ✅ Native permission dialogs

### Web:
- ✅ Browser notifications
- ✅ Permission management
- ⚠️ Only works while tab open
- ⚠️ No background notifications

### Engagement:
- ✅ Automatic segmentation
- ✅ Personalized messaging
- ✅ Re-engagement campaigns
- ✅ Activity tracking

---

## 🚀 **TESTING**

### To Test Notifications:

**Mobile:**
1. Enable notifications in Settings
2. Wait for scheduled time
3. Close app
4. Notification should appear ✅

**Web:**
1. Click "Enable Notifications" button
2. Allow browser permission
3. Keep tab open
4. Wait for scheduled time
5. Notification should appear ✅

**Note**: For web, you can test immediately by calling:
```dart
WebNotificationService().showNotification(
  title: 'Test',
  body: 'Testing notifications',
);
```

---

This system is fully implemented and working! 🎉


