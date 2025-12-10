# 🌐 Web Notifications - Complete Setup Guide

## Overview
Your website uses **browser notifications** to engage users and bring them back daily. This is the **ONLY** notification system used on web.

---

## ✅ How It Works (Web-Only)

### 1. **Permission Request**
- User clicks "Enable Notifications" button (shown after onboarding)
- Browser shows native permission dialog
- User clicks "Allow" → Notifications enabled ✅

### 2. **Notification Types**
- **Morning Streak** (8 AM)
- **Learning Reminder** (2 PM)  
- **Evening Streak** (8 PM)
- **Market Open** (9:30 AM weekdays)
- **Streak-at-Risk** (when inactive 20-24 hours)

### 3. **Scheduling**
- Uses browser `Timer` API
- Notifications fire at scheduled times
- ⚠️ **Note**: Only works while browser tab is open

### 4. **Implementation**
```dart
// Service: WebNotificationService
// Uses: Browser Notification API (dart:html)
// Scheduling: Timer (only while tab open)
```

---

## 🔧 Technical Implementation

### Files:
- **`lib/services/web_notification_service.dart`** - Main service
- **`lib/widgets/web_notification_permission_button.dart`** - Permission button widget
- **`lib/screens/onboarding/notification_permission_screen.dart`** - Onboarding flow
- **`lib/screens/professional_dashboard.dart`** - Initializes notifications on dashboard

### Key Code:
```dart
// Request permission
final webNotification = WebNotificationService();
final granted = await webNotification.requestPermission();

// Show notification
await webNotification.showNotification(
  title: 'Title',
  body: 'Message',
);

// Schedule notification
await webNotification.scheduleDailyNotifications(
  gamification: gamification,
  dailyGoals: dailyGoals,
);
```

---

## 📍 Where Notifications Are Used

### 1. **Onboarding**
- After user completes onboarding
- Shows `NotificationPermissionScreen`
- User enables notifications → Navigate to app
- User skips → Can enable later in settings

### 2. **Dashboard**
- `ProfessionalDashboard` initializes notifications on load
- Checks if permission granted
- Schedules daily notifications if enabled
- Checks for streak-at-risk

### 3. **Settings** (Future)
- Users can enable/disable notifications
- Button to re-request permission

---

## ⚠️ Important Limitations

### Browser Notifications:
- ✅ Work when tab is open
- ✅ Show native browser notifications
- ✅ Can click to focus tab
- ❌ **Don't work when tab is closed** (need Service Worker)
- ❌ **Can't schedule far in advance** (only while tab open)

### Solutions:
- **Current**: Check on page load if notifications should have fired
- **Future**: Implement Service Worker for background notifications

---

## 🎯 User Flow

```
1. User completes onboarding
   ↓
2. Notification Permission Screen appears
   ↓
3. User clicks "Enable Notifications"
   ↓
4. Browser shows permission dialog
   ↓
5a. User clicks "Allow" → Notifications enabled
    ↓
    Dashboard schedules daily notifications
    ↓
    Notifications fire at scheduled times (while tab open)
    
5b. User clicks "Block" → Can enable later in settings
```

---

## 📊 Notification Schedule

| Time | Type | Message |
|------|------|---------|
| 8:00 AM | Morning Streak | "Good morning! Your streak is growing..." |
| 2:00 PM | Learning Reminder | "Time to learn! Complete a quick lesson..." |
| 8:00 PM | Evening Streak | "Don't break your streak! Complete goals..." |
| 9:30 AM | Market Open | "Market is open! Check your portfolio..." |

---

## 🚀 Testing

### To Test Notifications:

1. **Enable Permission**:
   - Complete onboarding
   - Click "Enable Notifications"
   - Allow in browser dialog

2. **Test Immediate Notification**:
   ```dart
   final webNotification = WebNotificationService();
   await webNotification.showNotification(
     title: 'Test',
     body: 'This is a test notification',
   );
   ```

3. **Test Scheduled Notification**:
   - Schedule for 1 minute from now
   - Keep tab open
   - Notification should appear ✅

---

## 🔍 Code Locations

### Initialization:
- **Dashboard**: `professional_dashboard.dart` → `_initializeEngagementServices()`
- **Onboarding**: `notification_permission_screen.dart` → `_requestPermissions()`

### Services:
- **Web Notifications**: `web_notification_service.dart`
- **Engagement**: `user_engagement_service.dart`
- **Daily Hooks**: `daily_engagement_hook_widget.dart`

---

## 💡 Best Practices

1. **Always check permission before showing notification**
2. **Request permission from user interaction** (button click)
3. **Schedule notifications on dashboard load**
4. **Handle permission denied gracefully**
5. **Show notification permission button if not granted**

---

## ⚡ Quick Reference

```dart
// Check if supported
if (WebNotificationService().isSupported()) {
  // Check permission
  final enabled = await WebNotificationService().areNotificationsEnabled();
  
  if (!enabled) {
    // Request permission
    final granted = await WebNotificationService().requestPermission();
  }
  
  // Show notification
  await WebNotificationService().showNotification(
    title: 'Title',
    body: 'Body',
  );
}
```

---

**Status**: ✅ Fully Implemented and Working  
**Platform**: Web Only  
**Last Updated**: January 2025


