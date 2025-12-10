# PostHog Analytics Guide - What You Can See & How 🎯

## 🔗 Access Your Analytics

1. Go to [https://app.posthog.com](https://app.posthog.com)
2. Log in with your account
3. Select your project (the one you created)

---

## 📊 Main Dashboard - What You'll See

### 1. **Live Events** (Real-time activity)
**Where:** Click "Live events" in sidebar or on homepage

**What you see:**
- Users using your app RIGHT NOW (real-time)
- Every event as it happens:
  - `app_opened`
  - `user_signed_up`
  - `user_logged_in`
  - `screen_view`
  - `trade_executed`
  - `lesson_completed`
  - `feedback_submitted`
- User IDs, timestamps, properties

**Why it's useful:**
- See if analytics is working (events appearing = good!)
- Debug issues
- Monitor live activity

---

### 2. **Retention Analysis** 📈
**Where:** Click "Retention" in sidebar → "Retention"

**What you see:**
- **Retention rate:** % of users who come back after X days
- **Cohort analysis:** Users who signed up together
- **Retention curve:** Visual graph showing how users return over time

**Key metrics:**
- **Day 1 retention:** % who come back the next day
- **Day 7 retention:** % who come back after a week
- **Day 30 retention:** % who come back after a month

**How to use it:**
- Low Day 1 retention? → Users aren't finding value immediately
- Low Day 7 retention? → Need better onboarding or engagement
- High retention? → Your app is sticky! 🎉

---

### 3. **User Paths / Funnels** 🗺️
**Where:** Click "Insights" → "New insight" → "Funnel"

**What you can track:**
- Signup → First trade → Second trade
- Login → View lesson → Complete lesson
- App open → Screen views → Actions

**Example funnel:**
1. User signs up
2. User views dashboard
3. User makes first trade
4. User completes a lesson

Shows where users drop off!

---

### 4. **Session Recordings** 🎥 (If enabled)
**Where:** Click "Recordings" in sidebar

**What you see:**
- Recordings of user sessions (what users clicked, where they scrolled)
- Heatmaps of where users click
- User replays

**Note:** This might be a paid feature, but you can see basic session data

---

### 5. **Feature Flags** 🚩
**Where:** Click "Feature flags" in sidebar

**What you can do:**
- A/B test features
- Roll out features gradually
- Turn features on/off without code changes

**Free tier includes basic feature flags!**

---

### 6. **Trends / Insights** 📊
**Where:** Click "Insights" in sidebar

**What you can create:**

**A. User Trends:**
- How many users signed up today/this week
- Daily Active Users (DAU)
- Weekly Active Users (WAU)
- Monthly Active Users (MAU)

**B. Event Trends:**
- How many trades executed per day
- Lessons completed per day
- Screen views per day
- Feedback submissions per day

**C. Custom Insights:**
- Create graphs for ANY event
- Compare time periods
- Filter by user properties

---

### 7. **User Profiles** 👤
**Where:** Click "Persons" in sidebar

**What you see:**
- Individual user profiles
- What events each user triggered
- User properties (email, signup date, etc.)
- User journey timeline

**Useful for:**
- Understanding individual user behavior
- Debugging user-specific issues
- Seeing what power users do differently

---

### 8. **Cohorts** 👥
**Where:** Click "Cohorts" in sidebar

**What you can create:**
- Groups of users (e.g., "Users who made their first trade")
- Filter users by behavior
- Track cohort performance

**Example cohorts:**
- "Active traders" (made 5+ trades)
- "Learning enthusiasts" (completed 10+ lessons)
- "Churned users" (haven't logged in 7+ days)

---

## 🎯 Key Metrics You Should Track

### 1. **User Growth**
**Where:** Insights → Trends → Event: `user_signed_up`
- Track signups over time
- See if marketing is working
- Compare week-over-week growth

### 2. **Retention Rate**
**Where:** Retention → Retention
- Most important metric!
- Shows if users find value
- Track Day 1, Day 7, Day 30 retention

### 3. **Engagement**
**Where:** Insights → Trends
- `app_opened` = Daily Active Users
- `trade_executed` = Trading activity
- `lesson_completed` = Learning activity
- `feedback_submitted` = User engagement

### 4. **Conversion Funnels**
**Where:** Insights → Funnel
- Signup → First trade
- Login → Lesson completion
- App open → Feature usage

### 5. **Churn Analysis**
**Where:** Cohorts → Create cohort of inactive users
- Users who haven't logged in 7+ days
- What do they have in common?
- Why did they leave?

---

## 🔍 What Events Are Being Tracked Automatically?

### User Events:
- ✅ `app_opened` - Every time app opens
- ✅ `user_signed_up` - New user registration
- ✅ `user_logged_in` - User login
- ✅ `screen_view` - When users navigate to screens

### Activity Events:
- ✅ `trade_executed` - When users make trades (when you add tracking)
- ✅ `lesson_completed` - When users finish lessons (when you add tracking)
- ✅ `achievement_unlocked` - When users earn achievements (when you add tracking)
- ✅ `feedback_submitted` - When users submit feedback

### Retention Events:
- ✅ `session_start` - When user starts a session
- ✅ `session_end` - When user ends session
- ✅ `retention_day_X` - Tracked daily for retention analysis
- ✅ `churn_risk_detected` - When user might be churning

---

## 📈 Creating Your First Insight

1. Click **"Insights"** in sidebar
2. Click **"New insight"**
3. Choose type:
   - **Trends:** Track events over time
   - **Funnel:** Track user journey
   - **Retention:** Track user retention
4. Select event (e.g., `app_opened`)
5. Set date range (last 7 days, last 30 days, etc.)
6. Click **"Save"**

**Example insights to create:**
- Daily Active Users (event: `app_opened`)
- Signups per day (event: `user_signed_up`)
- Trades per day (event: `trade_executed`)
- Retention rate (cohort analysis)

---

## 🎨 Visualizations You Can Create

1. **Line charts:** Trends over time
2. **Bar charts:** Compare different events
3. **Pie charts:** Distribution of events
4. **Funnel charts:** Conversion funnels
5. **Table:** Raw data

---

## 🔔 Setting Up Alerts (Optional)

1. Click **"Insights"**
2. Open an insight
3. Click **"Set alert"**
4. Set conditions (e.g., "Alert if signups drop below 10/day")
5. Get notified via email/Slack

---

## 💡 Pro Tips

1. **Start with Retention:**
   - Most important metric
   - Tells you if users find value
   - Track Day 1, Day 7, Day 30

2. **Create Dashboards:**
   - Click **"Dashboards"** → **"New dashboard"**
   - Add your most important insights
   - Pin it for quick access

3. **Use Filters:**
   - Filter by user properties (e.g., "Users who signed up in last 7 days")
   - Filter by event properties (e.g., "Trades over $1000")
   - Compare different user segments

4. **Export Data:**
   - Click export button on any insight
   - Get CSV for deeper analysis
   - Share with team

5. **Real-time Monitoring:**
   - Keep "Live events" open while testing
   - See events appear instantly
   - Verify tracking is working

---

## 📊 Quick Start Checklist

- [ ] Open PostHog dashboard
- [ ] Check "Live events" - see events coming in?
- [ ] Create "Daily Active Users" insight (event: `app_opened`)
- [ ] Create "Signups" insight (event: `user_signed_up`)
- [ ] Check Retention tab - see retention rates
- [ ] Explore "Persons" - see individual users

---

## 🎯 What to Look For

### 🟢 Good Signs:
- Retention rate > 40% (Day 1)
- Retention rate > 20% (Day 7)
- Steady or growing DAU
- Users completing multiple actions per session

### 🔴 Red Flags:
- Retention rate < 20% (Day 1)
- Retention rate < 5% (Day 7)
- Declining DAU
- Users signing up but never returning
- High funnel drop-off rates

---

## 🚀 Next Steps

1. **Today:** Check Live events, verify tracking works
2. **This Week:** Create key insights (DAU, signups, retention)
3. **This Month:** Build dashboard with most important metrics
4. **Ongoing:** Check analytics weekly, track trends

---

**That's it! PostHog is powerful - explore it and you'll find tons of insights about your users! 📊**

