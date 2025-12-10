# PostHog Not Showing Events - Troubleshooting

## Issue: Events not appearing in PostHog dashboard

### ✅ Quick Fixes to Try:

1. **Check Console Logs**
   - When you open the app, look for logs that say:
     - `✅ Analytics service initialized`
     - `✅ PostHog event sent successfully`
     - `⚠️ PostHog API error` (if there's an error)

2. **Verify API Key**
   - Your API key: `phc_TjMiRpV0vQxcRQrSbCX76iGXELIM3VwFbDe0qZs61aM`
   - Check in PostHog dashboard → Project Settings → Project API Key
   - Make sure they match exactly

3. **Check PostHog Dashboard**
   - Go to **Live Events** (sidebar) - events appear in real-time
   - Make sure you're in the correct project
   - Events can take a few seconds to appear

4. **Test Event Sending**
   - I've updated the code to use PostHog's batch API format
   - The endpoint is now `/batch/` instead of `/capture/`
   - Events are wrapped in the correct format

### 🔍 What Was Fixed:

1. **API Endpoint:** Changed from `/capture/` to `/batch/`
2. **Event Format:** Events now wrapped in `batch` array as PostHog expects
3. **Better Logging:** Added more detailed error messages

### 🧪 Test It Now:

1. **Restart your app** (important - to reload the fixed code)
2. **Open the app** - should see `app_opened` event
3. **Log in** - should see `user_logged_in` event
4. **Check PostHog Live Events** - events should appear within seconds

### 📱 Check Your Console:

Look for these logs when opening the app:
```
✅ Analytics service initialized
✅ PostHog event sent successfully: app_opened
✅ PostHog event sent successfully: user_logged_in
```

If you see errors like:
```
⚠️ PostHog API error: 400 - ...
```

That means the format is still wrong. Let me know what error you see!

### 🔑 Important Notes:

- **Project API Key vs Personal API Key:** Make sure you're using the **Project API Key**, not a personal API key
- **Event Delay:** Events can take 5-30 seconds to appear in PostHog
- **Rate Limits:** Free tier has limits but shouldn't affect basic tracking
- **Network Issues:** Make sure your device/simulator has internet connection

### 🚨 If Still Not Working:

1. Check the console logs - copy any error messages
2. Check PostHog → Settings → Project API Key - verify it matches
3. Try creating a test event manually in PostHog to verify your account works
4. Check your PostHog project is active (not paused/disabled)

Let me know what you see in the console logs!

