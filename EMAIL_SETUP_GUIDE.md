# 📧 Email Notifications Setup Guide

## 🎯 Free Email Service Recommendation: **Resend**

**Resend** is the best free option for transactional emails:
- ✅ **100 emails/day** (free tier)
- ✅ **3,000 emails/month** (free tier)
- ✅ Easy API integration
- ✅ Great deliverability
- ✅ Modern developer-friendly interface
- ✅ No credit card required

**Alternative Options:**
- **SendGrid**: 100 emails/day free (requires credit card)
- **Mailgun**: 5,000 emails/month free (requires credit card)
- **Postmark**: 100 emails/month free

---

## 🚀 Setup Instructions

### Step 1: Create Resend Account

1. Go to [resend.com](https://resend.com)
2. Sign up for free account
3. Verify your email
4. Go to **API Keys** section
5. Create a new API key (save it securely!)

### Step 2: Set Up Supabase Edge Function

Your email service is already integrated via Supabase Edge Functions. You need to create the Edge Function:

#### Create Edge Function:

```bash
# In your Supabase project dashboard
# Go to Edge Functions > Create Function
# Name: send-email
```

#### Edge Function Code (`supabase/functions/send-email/index.ts`):

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { Resend } from "https://esm.sh/resend@2.0.0"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!
const FROM_EMAIL = 'onboarding@yourdomain.com' // Change to your verified domain

serve(async (req) => {
  try {
    const { type, user_id, email, display_name, days_since_last_active } = await req.json()
    
    const resend = new Resend(RESEND_API_KEY)
    
    let subject = ''
    let html = ''
    
    switch (type) {
      case 'welcome':
        subject = `Welcome to Orion, ${display_name || 'there'}! 🎉`
        html = `
          <h1>Welcome to Orion!</h1>
          <p>Hi ${display_name || 'there'},</p>
          <p>Thanks for joining Orion! Start your trading journey today.</p>
          <a href="https://yourwebsite.com">Open Orion</a>
        `
        break
      
      case 'retention':
        subject = `We miss you${display_name ? `, ${display_name}` : ''}! Come back to Orion 📈`
        html = `
          <h1>We miss you!</h1>
          <p>It's been ${days_since_last_active} days since you last visited Orion.</p>
          <p>Come back and complete a lesson to keep your streak alive!</p>
          <a href="https://yourwebsite.com">Continue Learning</a>
        `
        break
      
      case 'onboarding':
        subject = `Day ${days_since_last_active} with Orion - Discover New Features!`
        html = `
          <h1>Welcome to Day ${days_since_last_active}!</h1>
          <p>Discover new features and keep learning.</p>
          <a href="https://yourwebsite.com">Explore Orion</a>
        `
        break
      
      default:
        return new Response(JSON.stringify({ error: 'Invalid email type' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        })
    }
    
    const { data, error } = await resend.emails.send({
      from: FROM_EMAIL,
      to: email,
      subject: subject,
      html: html,
    })
    
    if (error) {
      console.error('Resend error:', error)
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }
    
    return new Response(JSON.stringify({ success: true, id: data?.id }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

### Step 3: Add Environment Variable

In your Supabase project:

1. Go to **Settings** > **Edge Functions** > **Secrets**
2. Add secret: `RESEND_API_KEY` = `your_resend_api_key_here`

### Step 4: Deploy Edge Function

```bash
# Install Supabase CLI if needed
npm install -g supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref your-project-ref

# Deploy the function
supabase functions deploy send-email
```

---

## 📋 Email Types Configured

Your app sends these emails automatically:

### 1. **Welcome Email**
- **When**: After user signs up
- **Trigger**: `EmailSequenceService.sendWelcomeEmail()`
- **Content**: Welcome message with onboarding tips

### 2. **Retention Emails**
- **When**: User inactive for 3, 7, or 30+ days
- **Trigger**: `EmailSequenceService.sendRetentionEmail()`
- **Content**: Personalized "we miss you" message

### 3. **Onboarding Sequence**
- **When**: Daily emails during first 2 weeks
- **Trigger**: `EmailSequenceService.sendOnboardingSequence()`
- **Content**: Feature discovery and tips

---

## 🔧 Integration Points

### Already Integrated:

✅ `UserEngagementService` - Sends emails for inactive users  
✅ `EmailSequenceService` - Handles all email sending  
✅ Re-engagement campaigns - Automatically trigger emails  

### What You Need to Do:

1. ✅ Create Resend account
2. ✅ Get API key
3. ✅ Create Supabase Edge Function (code above)
4. ✅ Add `RESEND_API_KEY` to Supabase secrets
5. ✅ Deploy Edge Function
6. ✅ Verify your sending domain in Resend (optional but recommended)

---

## 📊 Email Limits

### Free Tier (Resend):
- **100 emails/day**
- **3,000 emails/month**
- Perfect for starting out!

### When You Need More:
- Upgrade to Pro: $20/month = 50,000 emails/month
- Or use multiple free accounts (rotate API keys)

---

## 🧪 Testing

### Test Email Sending:

```dart
// In your Flutter app, test sending an email:
await EmailSequenceService.sendWelcomeEmail(
  userId: 'test-user-id',
  email: 'your-email@example.com',
  displayName: 'Test User',
);
```

### Check Edge Function Logs:

In Supabase dashboard:
- Go to **Edge Functions** > **send-email** > **Logs**
- See all email sending attempts and errors

---

## ✅ Checklist

- [ ] Created Resend account
- [ ] Generated API key
- [ ] Created Supabase Edge Function
- [ ] Added `RESEND_API_KEY` to Supabase secrets
- [ ] Deployed Edge Function
- [ ] Tested welcome email
- [ ] Verified emails are being received

---

## 🆘 Troubleshooting

### Emails Not Sending?

1. **Check Edge Function logs** in Supabase dashboard
2. **Verify API key** is correct in Supabase secrets
3. **Check Resend dashboard** for delivery status
4. **Verify email address** is valid
5. **Check spam folder** (first emails might go there)

### "Invalid API Key" Error?

- Make sure `RESEND_API_KEY` is set in Supabase secrets
- Redeploy Edge Function after adding secret

### Emails Going to Spam?

- Verify your sending domain in Resend
- Add SPF/DKIM records (Resend provides instructions)
- Use a custom domain instead of default

---

**That's it!** Your email notifications are now set up and will automatically send to bring users back. 🎉


