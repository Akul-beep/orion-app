# Notification Content Extension Setup Instructions

## Overview
This Notification Content Extension allows the mascot image to appear on the right side of iOS notifications, similar to Duolingo.

## Step 1: Add Extension to Xcode Project

1. **Open Xcode Project**
   - Open `ios/Runner.xcworkspace` in Xcode (NOT the .xcodeproj file)

2. **Create New Target**
   - In Xcode, go to **File** → **New** → **Target**
   - Select **Notification Content Extension**
   - Click **Next**

3. **Configure Extension**
   - **Product Name**: `NotificationContentExtension`
   - **Language**: Swift
   - **Embed in Application**: Runner
   - Click **Finish**
   - When prompted to activate the scheme, click **Cancel** (we'll do this manually)

## Step 2: Replace Extension Files

The extension files have already been created in `ios/NotificationContentExtension/`. You need to:

1. **Delete the auto-generated files** that Xcode created:
   - Delete `NotificationViewController.swift` (if Xcode created one)
   - Delete `MainInterface.storyboard` (if Xcode created one)
   - Delete `Info.plist` (if Xcode created one)

2. **Add our custom files to the extension target**:
   - Right-click on the `NotificationContentExtension` folder in Xcode
   - Select **Add Files to "NotificationContentExtension"...**
   - Navigate to `ios/NotificationContentExtension/`
   - Select all three files:
     - `NotificationViewController.swift`
     - `MainInterface.storyboard`
     - `Info.plist`
   - Make sure **"Copy items if needed"** is UNCHECKED (files are already in place)
   - Make sure **"Add to targets: NotificationContentExtension"** is CHECKED
   - Click **Add**

## Step 3: Configure Extension Settings

1. **Select the Extension Target**
   - In Xcode, click on the project name in the left sidebar
   - Select the **NotificationContentExtension** target

2. **General Settings**
   - **Bundle Identifier**: `com.akulnehra.orion.NotificationContentExtension`
   - **Deployment Target**: Should match your main app (iOS 12.0 or higher)
   - **Team**: Select your development team

3. **Signing & Capabilities**
   - Enable **Automatically manage signing**
   - Select your development team

4. **Build Settings**
   - **Swift Language Version**: Swift 5
   - **iOS Deployment Target**: Should match your main app

## Step 4: Configure App Group (Optional but Recommended)

For better file sharing between the app and extension:

1. **Add App Group to Main App**
   - Select the **Runner** target
   - Go to **Signing & Capabilities** tab
   - Click **+ Capability**
   - Add **App Groups**
   - Click **+** and add: `group.com.akulnehra.orion`
   - Check the checkbox

2. **Add App Group to Extension**
   - Select the **NotificationContentExtension** target
   - Go to **Signing & Capabilities** tab
   - Click **+ Capability**
   - Add **App Groups**
   - Click **+** and add: `group.com.akulnehra.orion`
   - Check the checkbox

3. **Update Flutter Code** (if using App Groups)
   - The extension code already supports App Groups
   - You may need to update the Flutter code to save images to the shared container
   - For now, the extension will try to access files from the Documents directory

## Step 5: Update Info.plist (if needed)

The `Info.plist` has already been configured with:
- Category identifier: `ORY_NOTIFICATION`
- This matches the category set in the Flutter code

## Step 6: Build and Test

1. **Select Scheme**
   - In Xcode, select **Runner** scheme (not the extension scheme)
   - Select your device (not simulator)

2. **Build and Run**
   - Press `Cmd + R` to build and run
   - The extension will be automatically embedded

3. **Test Notification**
   - Trigger a notification in your app
   - The mascot image should appear on the right side of the notification

## Troubleshooting

### Extension Not Loading
- Make sure the extension target is included in the build
- Check that the bundle identifier is correct
- Verify the category identifier matches (`ORY_NOTIFICATION`)

### Image Not Showing
- Check console logs for file path errors
- Verify the image file exists at the specified path
- Try using App Groups for better file sharing
- Check that file permissions are correct

### Build Errors
- Make sure Swift version matches (Swift 5)
- Verify deployment target matches main app
- Check that all files are added to the extension target

## Notes

- The extension runs in a separate process from the main app
- File access between app and extension requires App Groups or accessible file paths
- The extension will try multiple methods to load the image:
  1. From notification attachments (most reliable)
  2. From file path in userInfo
  3. From App Group shared container
  4. From Documents directory

## Next Steps

After setup, rebuild the app and test notifications. The mascot should appear on the right side of notifications!

