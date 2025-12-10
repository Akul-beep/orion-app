# 🎨 Logo Setup Instructions

## Issue: Logo Not Showing

You need to add your logo file to the project. There are **TWO** places where logos are used:

### 1. **In-App Logo** (Login/Signup Screens)
**Location**: `assets/logo/app_logo.png`

**Steps**:
1. Create the directory: `assets/logo/`
2. Save your logo as `app_logo.png` in that directory
3. Make sure it's a PNG with transparency (white logo on transparent background)
4. Recommended size: 160x160px or 320x320px (for retina)

### 2. **App Icon** (Home Screen Icon)
**Location**: iOS and Android app icon folders

**For iOS**:
- Location: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- You need multiple sizes (the folder already exists with placeholder icons)
- Replace all the `Icon-App-*.png` files with your logo in different sizes

**For Android**:
- Location: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- You need multiple sizes for different screen densities

## Quick Fix: Add Your Logo Now

1. **Save your logo image** (the one with two white curved shapes on blue background)
2. **Create the folder**: `assets/logo/`
3. **Save as**: `app_logo.png` in that folder
4. **Run**: `flutter pub get`
5. **Restart the app**

## App Icon vs In-App Logo

- **App Icon**: What shows on the iPhone home screen (the "Orion" icon you see)
- **In-App Logo**: What shows inside the app on login/signup screens

You can use the same logo for both, or different versions.

## Need Help?

If you want, I can:
1. Update the code to show a placeholder if the logo is missing
2. Help you set up the app icon for iOS/Android
3. Create a script to generate all required icon sizes

Let me know what you'd like to do!

