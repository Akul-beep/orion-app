# PostHog Analytics - Quick Start 🚀

## 🔗 Access Your Dashboard

**URL:** [https://app.posthog.com](https://app.posthog.com)

---

## 📊 Key Metrics You Can See Right Now

### 1. **Live Events** (See events in real-time)
**Where:** Sidebar → "Live events"

**You'll see:**
- ✅ `app_opened` - Every time someone opens your app
- ✅ `user_signed_up` - New user registrations
- ✅ `user_logged_in` - User logins
- ✅ `screen_view` - When users navigate
- ✅ `feedback_submitted` - User feedback

---

### 2. **Retention Rate** (Most important!)
**Where:** Sidebar → "Retention"

**What you'll see:**
- **Day 1 retention:** % of users who come back tomorrow
- **Day 7 retention:** % of users who come back after a week
- **Day 30 retention:** % of users who come back after a month

**Good benchmarks:**
- 🟢 Day 1 retention > 40% = Great!
- 🟡 Day 1 retention 20-40% = OK, needs improvement
- 🔴 Day 1 retention < 20% = Problem - users aren't finding value

---

### 3. **User Growth**
**Where:** Sidebar → "Insights" → "New insight" → Select "Trends"

**Create this insight:**
- Event: `user_signed_up`
- See signups per day/week/month

---

### 4. **Daily Active Users (DAU)**
**Where:** Sidebar → "Insights" → "New insight" → Select "Trends"

**Create this insight:**
- Event: `app_opened`
- See how many users open your app each day

---

### 5. **User Profiles** (Individual users)
**Where:** Sidebar → "Persons"

**See:**
- Each user's activity
- What they did in your app
- Their journey timeline

---

## 🎯 3-Minute Setup

1. **Open PostHog:** [https://app.posthog.com](https://app.posthog.com)
2. **Check Live Events:** See if events are coming in
3. **Check Retention:** See your retention rates
4. **Create DAU Insight:**
   - Click "Insights" → "New insight"
   - Select "Trends"
   - Event: `app_opened`
   - Save as "Daily Active Users"

---

## 📈 What Metrics to Track Weekly

1. **Retention rate** (Day 1, Day 7)
2. **Daily Active Users** (trending up = good!)
3. **Signups per day** (are you growing?)
4. **User engagement** (trades, lessons - when you add tracking)

---

## 🔥 Pro Tip

Create a **Dashboard** with your most important metrics:
1. Click "Dashboards" → "New dashboard"
2. Add insights:
   - Daily Active Users
   - Signups
   - Retention
3. Pin it for quick access!

---

**See `POSTHOG_ANALYTICS_GUIDE.md` for detailed instructions!**

