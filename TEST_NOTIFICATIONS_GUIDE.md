# 🧪 Test Notifications - Preview All Ori Moods!

## ✅ Test Mode Enabled!

When you launch the app, **all notification types will be sent automatically** so you can see how they look with different Ori moods!

### 🎯 What You'll See:

The app will send **8 different notifications** with **3-second delays** between each:

1. **Friendly Ori** - Morning Streak Reminder (blushing Ori)
2. **Concerned Ori** - Aggressive Streak at Risk (angry Ori with steam!) 🔥
3. **Excited Ori** - Achievement Unlocked (jumping Ori)
4. **Excited Ori** - Level Up (jumping Ori)
5. **Proud Ori** - Streak Milestone (heart eyes Ori)
6. **Friendly Ori** - Learning Reminder (blushing Ori)
7. **Friendly Ori** - Market Open (blushing Ori)
8. **Concerned Ori** - High Streak at Risk (VERY aggressive Ori!) 😤

### 📱 How to Test:

1. **Launch the app** in Xcode
2. **Grant notification permissions** when prompted
3. **Wait 2 seconds** after app loads
4. **Notifications will start appearing** every 3 seconds
5. **Check your notification center** to see all Ori moods!

### 🎨 What to Check:

- ✅ **Ori images appear** in each notification
- ✅ **Different Ori moods** for different contexts
- ✅ **Aggressive "concerned" Ori** for streak at risk (Duolingo-style!)
- ✅ **Friendly Ori** for daily reminders
- ✅ **Excited Ori** for achievements
- ✅ **Proud Ori** for milestones

### 🛑 To Disable Test Notifications:

Open `lib/services/test_notification_service.dart` and change:

```dart
static const bool TEST_NOTIFICATIONS_ENABLED = false; // Change to false
```

Then rebuild the app.

### 🧹 After Testing:

Once you've verified all notifications look good:
1. Set `TEST_NOTIFICATIONS_ENABLED = false` in `test_notification_service.dart`
2. The test notifications will stop
3. Normal scheduled notifications will continue working

---

**Status**: ✅ **TEST MODE ACTIVE - All notifications will fire on app launch!**

