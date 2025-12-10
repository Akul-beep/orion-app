# PostHog Not Showing Events - Debug Steps 🐛

## Quick Checks:

### 1. Check Live Events (Most Important!)
**This is where you'll see events in real-time:**

1. In PostHog dashboard, click **"Live events"** in the left sidebar
   - NOT "Dashboards" - that's different!
   - Live events shows events as they come in

2. **Open your app** and do some actions (log in, navigate)
3. **Watch Live Events** - events should appear within 5-10 seconds

**If you see events in Live Events:**
- ✅ Analytics is working!
- You just need to create Insights/Dashboards to see DAU, etc.

**If you DON'T see events in Live Events:**
- ❌ Events aren't reaching PostHog
- Check console logs for errors
- Verify API key is correct

---

### 2. Create DAU Insight (You need to create this!)

**DAU doesn't show automatically - you need to create an insight:**

1. Click **"Insights"** in left sidebar
2. Click **"New insight"** button
3. Select **"Trends"**
4. Configure:
   - **Event:** Select `app_opened`
   - **Chart type:** Line chart
   - **Breakdown:** None
   - **Date range:** Last 7 days
5. Click **"Save"** and name it "Daily Active Users"

**Now you'll see DAU!**

---

### 3. Check Console Logs

When you open your app, check the console/terminal for:
- `✅ Analytics service initialized`
- `📤 Sending PostHog event: app_opened`
- `✅ PostHog event sent successfully: app_opened`
- OR any `⚠️` error messages

---

### 4. Verify API Endpoint

The code uses: `https://us.i.posthog.com/capture/`

But PostHog might need `/batch/` endpoint. Let me check and fix if needed.

---

## What You Should See:

### In Live Events:
- `app_opened` - Every time you open app
- `user_logged_in` - When you log in
- `user_signed_up` - When you sign up

### If Creating DAU Insight:
- Should show daily counts of `app_opened` events
- Each day = one bar/point on graph

---

## Common Issues:

1. **Wrong page:** Looking at Dashboards instead of Live Events
2. **Need to create Insight:** DAU doesn't exist automatically
3. **API format wrong:** Events might not be in correct format
4. **Network issues:** Events might be blocked

Let me check the event format and fix if needed!

