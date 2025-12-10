# 🔍 Logo Troubleshooting Guide

## If You Don't See the Logo

### 1. **Are you on the Login/Signup Screen?**
The logo only appears on:
- **Login Screen** - When you're not logged in
- **Signup Screen** - When creating a new account

If you're already logged in, you won't see it because you're past those screens.

**To see it:**
- Log out of the app
- Or delete the app and reinstall
- Or clear app data

### 2. **Did you run `flutter pub get`?**
After adding the logo file, you MUST run:
```bash
flutter pub get
```

### 3. **Did you do a FULL restart?**
Hot reload won't pick up new assets. You need to:
- **Stop the app completely**
- **Restart it** (not just hot reload)

### 4. **Check the Console**
Look for error messages like:
- `⚠️ Logo loading error: ...`
- This will tell you what's wrong

### 5. **Verify the File**
Make sure:
- File exists at: `assets/logo/app_logo.png`
- File is a valid PNG image
- File size is reasonable (not corrupted)

### 6. **Check pubspec.yaml**
Make sure this line exists:
```yaml
assets:
  - assets/icons/
  - assets/logo/
```

## Quick Test

1. **Log out** of the app (if logged in)
2. **Stop the app** completely
3. **Run**: `flutter clean && flutter pub get`
4. **Restart** the app
5. You should see the login screen with your logo

## Still Not Working?

Check the console output for error messages. The code now prints errors when the logo fails to load, so you'll see exactly what's wrong.

---

**Note**: The logo on the **home screen icon** (the app icon) is different and needs to be set separately in iOS/Android app icon folders.

