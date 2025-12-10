# Resend Email Setup - SIMPLIFIED 🚀

**TL;DR: You DON'T need a custom domain to get started!** Resend gives you a free testing domain.

## Step 1: Sign Up for Resend (2 minutes)

1. Go to [https://resend.com](https://resend.com)
2. Click "Sign Up" (use Google/GitHub for faster signup)
3. Verify your email

## Step 2: Get Your API Key (1 minute)

1. Once logged in, go to **API Keys** in the sidebar
2. Click **"Create API Key"**
3. Give it a name like "Orion App"
4. Copy the API key (starts with `re_`)
   - It looks like: `re_1234567890abcdef...`
   - **SAVE THIS** - you'll need it in a sec!

## Step 3: Use Resend's Free Testing Domain (NO CUSTOM DOMAIN NEEDED!)

**Good news:** Resend gives you a free domain for testing: `onboarding.resend.dev`

You can use this to send emails immediately without setting up a custom domain!

**The "from" email will be:**
```
Orion StockSense <onboarding@resend.dev>
```

This works perfectly for testing and early launch! You can add your own domain later.

## Step 4: Create Supabase Edge Function (5 minutes)

### Option A: Using Supabase Dashboard (Easiest)

1. Go to your Supabase project dashboard
2. Click **Edge Functions** in the sidebar
3. Click **"Create a new function"**
4. Name it: `send-email`
5. Copy and paste this code:

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
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #1E3A8A;">Welcome to Orion StockSense!</h1>
            <p>Thanks for joining us, ${display_name || 'there'}! We're excited to help you learn finance and practice trading.</p>
            <p>Get started by:</p>
            <ul>
              <li>Exploring the learning modules</li>
              <li>Trying your first paper trade</li>
              <li>Setting up your portfolio</li>
            </ul>
            <p>Best,<br>The Orion Team</p>
          </div>
        `
        break
      
      case 'retention':
        subject = `We miss you! 🎯`
        html = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #1E3A8A;">Hey ${display_name || 'there'}!</h1>
            <p>It's been ${days_since_last_active} days since you last used Orion.</p>
            <p>Ready to continue your finance learning journey? We've got new content waiting for you!</p>
            <p>Best,<br>The Orion Team</p>
          </div>
        `
        break
      
      case 'onboarding':
        const titles = [
          'Day 1: Getting Started with Paper Trading',
          'Day 3: Explore Learning Modules',
          'Day 7: Master Stock Analysis',
          'Day 10: Join the Leaderboard',
          'Day 14: Level Up Your Skills'
        ]
        const contents = [
          'Welcome! Today, try making your first paper trade. Paper trading lets you practice without risking real money.',
          'Ready to learn? Check out our interactive lessons on stock market basics.',
          'Learn how to analyze stocks using charts, news, and company data.',
          'Compete with friends on the leaderboard! Level up by completing lessons and trades.',
          'Keep the momentum going! Set daily goals and maintain your learning streak.'
        ]
        subject = titles[day_number - 1] || `Day ${day_number}: Continue Learning`
        html = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #1E3A8A;">${subject}</h1>
            <p>${contents[day_number - 1] || 'Continue your learning journey!'}</p>
            <p>Best,<br>The Orion Team</p>
          </div>
        `
        break
      
      case 'feedback_request':
        subject = 'We'd love your feedback! 💬'
        html = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #1E3A8A;">Help Us Improve</h1>
            <p>Hi ${display_name || 'there'}!</p>
            <p>We'd love to hear your thoughts on Orion StockSense. Your feedback helps us build a better app!</p>
            <p>Share your ideas in the Feedback Board in the app.</p>
            <p>Best,<br>The Orion Team</p>
          </div>
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
        from: 'Orion StockSense <onboarding@resend.dev>', // Using Resend's free domain!
        to: email,
        subject: subject,
        html: html,
      }),
    })

    if (!response.ok) {
      const error = await response.text()
      throw new Error(`Resend API error: ${response.status} - ${error}`)
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    console.error('Email error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
```

6. Click **"Deploy"**

### Option B: Using Supabase CLI (If you prefer CLI)

```bash
# Install Supabase CLI if you haven't
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Create the function
supabase functions new send-email

# Add the code above to supabase/functions/send-email/index.ts

# Deploy
supabase functions deploy send-email
```

## Step 5: Add Resend API Key to Supabase Secrets (2 minutes)

1. In Supabase dashboard, go to **Edge Functions** → **Secrets**
2. Click **"Add a new secret"**
3. Name: `RESEND_API_KEY`
4. Value: Paste your Resend API key (the `re_...` one you copied earlier)
5. Click **"Save"**

## Step 6: Test It! (1 minute)

1. Sign up a test user in your app
2. Check the test user's email inbox
3. You should receive a welcome email from `onboarding@resend.dev`!

## ✅ That's It!

You're done! Emails will now send automatically:
- ✅ Welcome email when users sign up
- ✅ Retention emails (when you trigger them)
- ✅ Onboarding sequence (when you trigger them)

---

## 🎯 What About Custom Domains? (Optional - Do This Later)

**You DON'T need this for now!** But if you want to use your own domain later:

1. In Resend dashboard, go to **Domains**
2. Click **"Add Domain"**
3. Enter your domain (e.g., `yourdomain.com`)
4. Resend will give you DNS records to add
5. Add them to your domain's DNS settings
6. Wait for verification (can take a few hours)
7. Update the Edge Function to use: `noreply@yourdomain.com`

**But seriously, you can skip this for now!** The free `onboarding@resend.dev` domain works perfectly for launch.

---

## 🐛 Troubleshooting

**Emails not sending?**
1. Check Edge Function logs in Supabase (Edge Functions → Logs)
2. Verify `RESEND_API_KEY` secret is set correctly
3. Check Resend dashboard → Emails to see if emails were attempted
4. Make sure you're using `onboarding@resend.dev` as the "from" address

**Getting errors?**
- Check the Edge Function logs in Supabase
- Make sure the API key starts with `re_`
- Verify the function name is exactly `send-email`

---

## 📧 Email Limits

- **Free tier**: 100 emails/day, 3,000/month
- Perfect for early launch!
- Upgrade later if you need more

---

**You got this! 🚀** The domain stuff is optional - just use Resend's free domain for now!

