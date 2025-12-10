# Analytics, Feedback & Email Setup Guide

This guide will help you set up the three core features for app launch: **Analytics**, **Feedback Board**, and **Email Sequences** - all using free tiers!

## 📊 1. Analytics Setup (PostHog)

PostHog offers a generous **free tier: 1 million events per month** - perfect for getting started!

### Steps:

1. **Sign up for PostHog**
   - Go to [https://posthog.com](https://posthog.com)
   - Sign up for a free account
   - Create a new project

2. **Get your API Key**
   - In PostHog dashboard, go to **Project Settings** → **Project API Key**
   - Copy your API key

3. **Configure in Flutter App**
   - Open `lib/services/analytics_service.dart`
   - Replace `YOUR_POSTHOG_API_KEY` on line 12 with your actual API key:
   ```dart
   static const String _posthogApiKey = 'your-actual-api-key-here';
   ```

4. **Verify it's working**
   - Run your app
   - Events should appear in PostHog dashboard within a few seconds
   - Check the "Live Events" section to see events streaming in

### What gets tracked automatically:
- ✅ App opens
- ✅ Screen views
- ✅ User signups
- ✅ User logins
- ✅ Trade executions
- ✅ Lesson completions
- ✅ Achievement unlocks
- ✅ Feedback submissions
- ✅ Retention metrics

---

## 💬 2. Feedback Board Setup

The feedback board uses your existing Supabase database (no additional service needed!).

### Steps:

1. **Run the SQL Schema**
   - Open your Supabase project dashboard
   - Go to **SQL Editor**
   - Copy and paste the contents of `supabase_schema.sql`
   - Click **Run** to create the tables

2. **Verify tables were created**
   - Go to **Table Editor** in Supabase
   - You should see:
     - `feedback` table
     - `feedback_votes` table
     - `email_logs` table

3. **That's it!**
   - The feedback board is now fully functional
   - Users can submit feedback and upvote feature requests
   - Access it from: **Settings** → **Feedback Board**

### Features:
- ✅ Submit feedback/feature requests
- ✅ Upvote/downvote other users' feedback
- ✅ Filter by status (open, in progress, completed)
- ✅ View feedback details
- ✅ Categories: feature_request, bug_report, improvement, other

---

## 📧 3. Email Sequence Setup (Resend + Supabase Edge Functions)

Resend offers **100 emails/day (3,000/month) free** - perfect for welcome emails and onboarding sequences!

### Steps:

1. **Sign up for Resend**
   - Go to [https://resend.com](https://resend.com)
   - Sign up for a free account
   - Verify your email

2. **Create an API Key**
   - Go to **API Keys** in Resend dashboard
   - Click **Create API Key**
   - Copy the API key (starts with `re_`)

3. **Set up Domain (Optional but Recommended)**
   - Go to **Domains** in Resend
   - Add your domain (e.g., `yourdomain.com`)
   - Add the DNS records Resend provides to your domain
   - Wait for verification (can take a few hours)

4. **Create Supabase Edge Function**
   - In Supabase dashboard, go to **Edge Functions**
   - Create a new function called `send-email`
   - Paste the code from `email_edge_function.ts` (see below)
   - Add your Resend API key as a secret:
     - Go to **Edge Functions** → **Secrets**
     - Add secret: `RESEND_API_KEY` = `your-resend-api-key`

5. **Configure in Code**
   - The email service is already integrated in `lib/services/email_sequence_service.dart`
   - No code changes needed!

### Email Templates:

The Edge Function will send these email types:
- **Welcome Email** - Sent when user signs up
- **Retention Email** - Sent when user hasn't logged in for 7+ days
- **Onboarding Sequence** - 5 emails over 2 weeks introducing features
- **Feedback Request** - Ask users for feedback

### Email Edge Function Code:

Create a file `supabase/functions/send-email/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

serve(async (req) => {
  try {
    const { type, user_id, email, display_name, days_since_last_active, day_number } = await req.json()

    let subject = ''
    let html = ''

    switch (type) {
      case 'welcome':
        subject = `Welcome to Orion StockSense, ${display_name || 'there'}! 🚀`
        html = `
          <h1>Welcome to Orion StockSense!</h1>
          <p>Thanks for joining us. We're excited to help you learn finance and practice trading.</p>
          <p>Get started by exploring the learning modules or trying your first paper trade!</p>
          <p>Best,<br>The Orion Team</p>
        `
        break
      
      case 'retention':
        subject = `We miss you! 🎯`
        html = `
          <h1>Hey ${display_name || 'there'}!</h1>
          <p>It's been ${days_since_last_active} days since you last used Orion.</p>
          <p>Ready to continue your finance learning journey? We've got new content waiting for you!</p>
          <p>Best,<br>The Orion Team</p>
        `
        break
      
      case 'onboarding':
        const onboardingTitles = [
          'Day 1: Getting Started with Paper Trading',
          'Day 3: Explore Learning Modules',
          'Day 7: Master Stock Analysis',
          'Day 10: Join the Leaderboard',
          'Day 14: Level Up Your Skills'
        ]
        subject = onboardingTitles[day_number - 1] || `Day ${day_number}: Continue Learning`
        html = `
          <h1>Day ${day_number} of Your Journey</h1>
          <p>${getOnboardingContent(day_number)}</p>
          <p>Best,<br>The Orion Team</p>
        `
        break
      
      case 'feedback_request':
        subject = 'We'd love your feedback! 💬'
        html = `
          <h1>Help Us Improve</h1>
          <p>Hi ${display_name || 'there'}!</p>
          <p>We'd love to hear your thoughts on Orion StockSense. Your feedback helps us build a better app!</p>
          <p>Share your ideas in the Feedback Board in the app.</p>
          <p>Best,<br>The Orion Team</p>
        `
        break
    }

    // Send email via Resend
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'Orion StockSense <noreply@yourdomain.com>', // Replace with your verified domain
        to: email,
        subject: subject,
        html: html,
      }),
    })

    if (!response.ok) {
      throw new Error(`Resend API error: ${response.statusText}`)
    }

    // Log email sent
    // You can add this to email_logs table if needed

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})

function getOnboardingContent(day: number): string {
  const content = [
    'Welcome! Today, try making your first paper trade. Paper trading lets you practice without risking real money.',
    'Ready to learn? Check out our interactive lessons on stock market basics.',
    'Learn how to analyze stocks using charts, news, and company data.',
    'Compete with friends on the leaderboard! Level up by completing lessons and trades.',
    'Keep the momentum going! Set daily goals and maintain your learning streak.',
  ]
  return content[day - 1] || 'Continue your learning journey!'
}
```

---

## ✅ Quick Verification Checklist

After setup, verify everything is working:

- [ ] **Analytics**: Check PostHog dashboard for events appearing
- [ ] **Feedback Board**: Submit a test feedback from Settings → Feedback Board
- [ ] **Email**: Sign up a test user and check for welcome email

---

## 🆓 Free Tier Limits Summary

| Service | Free Tier | What You Get |
|---------|-----------|--------------|
| **PostHog** | 1M events/month | Full analytics, retention tracking, user behavior |
| **Resend** | 100 emails/day | Welcome emails, onboarding sequences, retention emails |
| **Supabase** | Your existing plan | Database for feedback board |

---

## 🚀 Next Steps

1. **Set up PostHog** (5 minutes)
2. **Run SQL schema in Supabase** (2 minutes)
3. **Set up Resend + Edge Function** (15 minutes)
4. **Test everything works**
5. **You're ready to launch!** 🎉

---

## 📝 Notes

- All services have free tiers that should be sufficient for early stages
- You can upgrade later as you grow
- Analytics runs automatically - no code changes needed after initial setup
- Feedback board works immediately after running SQL schema
- Email sequences require the Edge Function setup but then work automatically

---

## 🐛 Troubleshooting

**Analytics not working?**
- Check API key is correct in `analytics_service.dart`
- Check PostHog project is active
- Check console for errors

**Feedback board not showing feedback?**
- Verify SQL schema ran successfully
- Check Supabase table editor to see if tables exist
- Check RLS policies allow public read

**Emails not sending?**
- Verify Resend API key is set in Supabase secrets
- Check Edge Function logs in Supabase
- Verify domain is verified in Resend (if using custom domain)
- Check Resend dashboard for delivery status

---

Good luck with your launch! 🚀

