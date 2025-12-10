# 🔧 Troubleshooting Login/Signup Issues

## What I've Fixed

1. ✅ **Improved Error Messages** - Now shows detailed error messages in both the UI and console
2. ✅ **Added Error Logging** - All errors are now printed to console with full details
3. ✅ **Added Snackbar Notifications** - Errors now show as red snackbars for better visibility

## How to Debug

### Step 1: Check Xcode Console
When you try to login/signup, check the Xcode console (bottom panel) for error messages. Look for:
- `❌ Signup error details:` or `❌ Login error details:`
- `❌ Sign up error:` or `❌ Sign in error:`

### Step 2: Common Issues

#### Issue: "Network error" or "Connection timeout"
**Solution:**
- Check if simulator has internet connection
- In Simulator: Settings → General → Reset → Reset Network Settings
- Try restarting the simulator

#### Issue: "Service configuration error" or "Supabase not initialized"
**Solution:**
- Check if Supabase URL is correct in `lib/main.dart`
- Verify Supabase project is active
- Check Supabase dashboard for any service issues

#### Issue: "Invalid email or password"
**Solution:**
- Make sure email format is correct (e.g., `test@example.com`)
- Password must be at least 6 characters
- For signup: Make sure email doesn't already exist

#### Issue: "Password is too weak"
**Solution:**
- Use at least 6 characters
- Try a stronger password with letters and numbers

### Step 3: Test Supabase Connection

1. Open Xcode console
2. Look for: `✅ Supabase initialized successfully`
3. If you see `⚠️ Supabase initialization failed`, that's the problem

### Step 4: Check Simulator Network

The iOS Simulator should have internet by default, but sometimes it doesn't. To fix:
1. In Simulator: Settings → General → Reset → Reset Network Settings
2. Restart the simulator
3. Try again

## Next Steps

1. **Run the app again** in Xcode
2. **Try to login/signup**
3. **Check the Xcode console** (bottom panel) for error messages
4. **Share the error message** you see in the console, and I'll help fix it!

## Quick Test

Try signing up with:
- Email: `test@example.com`
- Password: `test1234` (at least 6 characters)
- Name: `Test User`

If it fails, check the console for the exact error message.






