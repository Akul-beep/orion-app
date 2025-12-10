# 🔧 Fix Code Signing Issues

## Quick Fix Steps

### Option 1: Automatic Signing (Recommended)

1. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Fix Runner Target**:
   - Click on **Runner** project in left sidebar
   - Select **Runner** target
   - Go to **Signing & Capabilities** tab
   - Check ✅ **"Automatically manage signing"**
   - Select your **Team** from dropdown (or add your Apple ID)
   - If you don't have a team, click **"Add Account..."** and sign in with your Apple ID

3. **Fix Extension Target**:
   - Still in project settings, select **NotificationContentExtension** target
   - Go to **Signing & Capabilities** tab
   - Check ✅ **"Automatically manage signing"**
   - Select the **same Team** as Runner
   - Xcode will automatically create provisioning profiles

4. **Build Again**:
   - Press `Cmd + B` to build
   - Xcode will automatically handle code signing

### Option 2: If You Don't Have an Apple Developer Account

For **development/testing only**, you can use a free Apple ID:

1. **Add Apple ID to Xcode**:
   - Xcode → Settings (or Preferences) → Accounts
   - Click **+** → Add Apple ID
   - Sign in with your Apple ID (free account works)

2. **Select Team**:
   - In Signing & Capabilities for both targets
   - Select your Apple ID from the Team dropdown
   - Xcode will create a free development profile

### Option 3: Disable Code Signing (Development Only - May Not Work)

If you just want to test locally, you can try:

1. **Runner Target**:
   - Signing & Capabilities → Uncheck "Automatically manage signing"
   - Set Code Signing Identity to "Don't Code Sign"

2. **Extension Target**:
   - Same as above

**Note**: Extensions usually require code signing, so this might not work.

## Common Issues

### "No Accounts" Error
- Go to Xcode → Settings → Accounts
- Add your Apple ID
- Make sure it's selected in Signing & Capabilities

### "No profiles found" Error
- Make sure "Automatically manage signing" is checked
- Select a Team
- Clean build folder: `Cmd + Shift + K`
- Build again: `Cmd + B`

### Extension Signing Issues
- Extension MUST use the same Team as the main app
- Extension bundle ID must be: `com.akulnehra.orion.NotificationContentExtension`
- Make sure both targets have signing enabled

## Recommended Solution

**Just use automatic signing with your Apple ID** - it's the easiest and works for development!

1. Open Xcode
2. Select Runner target → Signing & Capabilities → Check "Automatically manage signing" → Select Team
3. Select NotificationContentExtension target → Signing & Capabilities → Check "Automatically manage signing" → Select same Team
4. Build!

That's it! 🎉

