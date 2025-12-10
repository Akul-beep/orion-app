# How to See DAU and Analytics in PostHog 📊

## ⚠️ Important: You Need to CREATE Insights!

**PostHog doesn't show DAU automatically** - you need to create an Insight/Dashboard first!

---

## Step 1: Check if Events Are Coming In

**Before creating dashboards, verify events are being sent:**

1. In PostHog, click **"Live events"** in the left sidebar (NOT "Dashboards")
2. Open your app on your phone
3. Watch the Live Events page
4. You should see events appearing like:
   - `app_opened`
   - `user_logged_in`
   - etc.

**If you see events here:**
- ✅ Analytics is working!
- Continue to Step 2

**If you DON'T see events:**
- ❌ Events aren't reaching PostHog
- Check console logs for errors
- See troubleshooting below

---

## Step 2: Create Daily Active Users (DAU) Insight

1. Click **"Insights"** in left sidebar
2. Click **"New insight"** button (orange button top right)
3. Select **"Trends"**
4. Configure:
   - **Event:** Select `app_opened` from dropdown
   - **Chart type:** Line chart (or Bar chart)
   - **Breakdown:** None (leave empty)
   - **Date range:** Last 7 days (or Last 30 days)
5. Click **"Save"** 
6. Name it: "Daily Active Users"
7. Click **"Save insight"**

**Now you'll see DAU!** Each day shows how many users opened the app.

---

## Step 3: Add to Dashboard

1. On your insight page, click **"Add to dashboard"**
2. Select "My App Dashboard" (or create new one)
3. Now DAU will appear on your dashboard!

---

## Other Insights to Create:

### Signups Per Day:
1. New insight → Trends
2. Event: `user_signed_up`
3. Save as "Daily Signups"

### User Logins:
1. New insight → Trends  
2. Event: `user_logged_in`
3. Save as "Daily Logins"

### Retention Rate:
1. Click **"Retention"** in sidebar
2. Should show automatically
3. Check Day 1, Day 7 retention

---

## 🐛 Troubleshooting: No Events in Live Events?

### Check Console Logs:

When you open your app, look for these logs:

**Good signs:**
```
✅ Analytics service initialized
   PostHog endpoint: https://us.i.posthog.com/capture/
   API Key: phc_TjMiRp...
📤 Sending PostHog event: app_opened
✅ PostHog event sent successfully: app_opened
```

**Bad signs:**
```
⚠️ PostHog API error: 400
⚠️ PostHog request failed: ...
```

### Common Issues:

1. **Wrong endpoint format** - I just fixed this! Restart your app
2. **API key wrong** - Check if key matches PostHog dashboard
3. **Network blocked** - Check if device has internet
4. **Events not triggering** - Make sure you're actually opening the app

---

## 🔧 What I Just Fixed:

1. **Changed to batch endpoint:** `/batch/` instead of `/capture/`
2. **Fixed event format:** Now using correct PostHog batch format
3. **Better logging:** More detailed console logs to debug

**Restart your app now** and check:
1. Console logs - should see "✅ PostHog event sent successfully"
2. PostHog Live Events - should see events appearing

---

## 📊 Quick Checklist:

- [ ] Check Live Events - see events coming in?
- [ ] Create DAU Insight - New insight → Trends → `app_opened`
- [ ] Add to Dashboard - Click "Add to dashboard"
- [ ] Check console logs - any errors?

**The key is: You need to CREATE insights first! PostHog doesn't auto-generate them.**

