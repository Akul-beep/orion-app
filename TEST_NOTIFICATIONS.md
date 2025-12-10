# How to Test Notifications

## Quick Test (Easiest Way)

1. **Open Xcode** and run the app on your iPhone
2. **Open the Flutter console** (or Xcode console)
3. **Call this function** from anywhere in your code:

```dart
await PushNotificationService().quickTestNotification();
```

Or add a button in your app that calls it:

```dart
ElevatedButton(
  onPressed: () async {
    await PushNotificationService().quickTestNotification();
  },
  child: Text('Test Notification'),
)
```

## What It Does

1. ✅ Initializes the notification service
2. ✅ Requests notification permissions (if not already granted)
3. ✅ Shows a test notification immediately with Ory character
4. ✅ Prints detailed logs to help debug

## Important Notes for iOS

### On Real iPhone:
- **Minimize the app** (press home button or swipe up) BEFORE the notification appears
- **Pull down from the top** to see Notification Center
- Notifications may not show when app is in foreground

### On iOS Simulator:
- Press **Cmd+H** to minimize the app
- Pull down from top to see Notification Center
- Notifications work better when app is backgrounded

## Check Permissions

If notifications don't appear:

1. **Check iOS Settings:**
   - Settings > Orion > Notifications
   - Make sure "Allow Notifications" is ON
   - Make sure "Lock Screen", "Notification Center", and "Banners" are enabled

2. **Check Console Logs:**
   - Look for: `✅ Permissions granted`
   - Look for: `✅ Notification shown`
   - Look for any `❌` errors

## Debug Steps

1. **Run the app** in Xcode
2. **Call `quickTestNotification()`** from your code
3. **Check the console** for:
   - Permission status
   - File paths
   - Attachment creation
   - Any errors

4. **Check iPhone:**
   - Minimize app (Cmd+H or home button)
   - Pull down from top
   - Look for notification

## If Still Not Working

1. **Check Xcode console** for errors
2. **Verify permissions** in iOS Settings
3. **Try on a real device** (not simulator)
4. **Check that the extension is embedded** in the app bundle
5. **Verify code signing** is correct for both Runner and NotificationContentExtension

## Test from Code

Add this to any screen (like a debug menu):

```dart
import 'package:orion/services/push_notification_service.dart';

// In your widget:
ElevatedButton(
  onPressed: () async {
    final service = PushNotificationService();
    final success = await service.quickTestNotification();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent! Check notification center.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification. Check console.')),
      );
    }
  },
  child: Text('Test Notification'),
)
```

