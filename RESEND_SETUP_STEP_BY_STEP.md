# 📧 Resend Setup - Step by Step Guide

## ✅ Step 1: Get Your Resend API Key

1. **Go to Resend Dashboard**: https://resend.com/dashboard
2. **Click "API Keys"** (left sidebar)
3. **Click "Create API Key"** (top right button)
4. **Fill in:**
   - Name: `Orion App` (or any name)
   - Permission: Select **"Sending access"**
5. **Click "Add"**
6. **COPY THE API KEY NOW** (you won't see it again!)
   - It looks like: `re_AbC123xyz...`
   - Save it somewhere safe!

---

## ✅ Step 2: Add API Key to Supabase

1. **Go to Supabase Dashboard**: https://supabase.com/dashboard
2. **Select your project**
3. **Click "Edge Functions"** (left sidebar)
4. **Click "Secrets"** (in the Edge Functions section)
5. **Click "Add Secret"**
6. **Fill in:**
   - Name: `RESEND_API_KEY`
   - Value: Paste your Resend API key (the one you copied)
7. **Click "Save"**

---

## ✅ Step 3: Create Edge Function

### Option A: Using Supabase Dashboard (Easiest!)

1. **In Supabase Dashboard**, go to **Edge Functions**
2. **Click "Create Function"**
3. **Function name**: `send-email`
4. **Click "Create Function"**
5. **Replace ALL the code** with this:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!
const FROM_EMAIL = 'onboarding@resend.dev' // Change this later to your domain

serve(async (req) => {
  try {
    const { type, user_id, email, display_name, days_since_last_active, day_number } = await req.json()
    
    let subject = ''
    let html = ''
    
    switch (type) {
      case 'welcome':
        subject = `Welcome to Orion, ${display_name || 'there'}! 🎉`
        html = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #0052FF;">Welcome to Orion! 🎉</h1>
            <p>Hi ${display_name || 'there'},</p>
            <p>Thanks for joining Orion! Start your trading journey today.</p>
            <a href="https://yourwebsite.com" style="display: inline-block; background: #0052FF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin-top: 20px;">Open Orion</a>
          </div>
        `
        break
      
      case 'retention':
        subject = `We miss you${display_name ? `, ${display_name}` : ''}! Come back to Orion 📈`
        html = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #0052FF;">We miss you!</h1>
            <p>It's been ${days_since_last_active} days since you last visited Orion.</p>
            <p>Come back and complete a lesson to keep your streak alive!</p>
            <a href="https://yourwebsite.com" style="display: inline-block; background: #0052FF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin-top: 20px;">Continue Learning</a>
          </div>
        `
        break
      
      case 'onboarding':
        subject = `Day ${day_number || days_since_last_active} with Orion - Discover New Features!`
        html = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #0052FF;">Welcome to Day ${day_number || days_since_last_active}!</h1>
            <p>Discover new features and keep learning.</p>
            <a href="https://yourwebsite.com" style="display: inline-block; background: #0052FF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin-top: 20px;">Explore Orion</a>
          </div>
        `
        break
      
      default:
        return new Response(JSON.stringify({ error: 'Invalid email type' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        })
    }
    
    // Send email using Resend API
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to: email,
        subject: subject,
        html: html,
      }),
    })
    
    const data = await response.json()
    
    if (!response.ok) {
      console.error('Resend error:', data)
      return new Response(JSON.stringify({ error: data.message || 'Failed to send email' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }
    
    return new Response(JSON.stringify({ success: true, id: data.id }), {
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

6. **Click "Deploy"** (top right)

---

### Option B: Using Supabase CLI (If you have it installed)

```bash
# 1. Install Supabase CLI (if not installed)
npm install -g supabase

# 2. Login to Supabase
supabase login

# 3. Link your project
supabase link --project-ref your-project-ref

# 4. Create the function
mkdir -p supabase/functions/send-email

# 5. Create the file
# Copy the code above into: supabase/functions/send-email/index.ts

# 6. Deploy
supabase functions deploy send-email
```

---

## ✅ Step 4: Update Your Website URL

1. **In the Edge Function code**, find this line:
   ```typescript
   <a href="https://yourwebsite.com"
   ```
2. **Replace `https://yourwebsite.com`** with your actual website URL
3. **Also update `FROM_EMAIL`**:
   - For now, use: `onboarding@resend.dev` (Resend's test domain)
   - Later, add your own domain in Resend → Domains

---

## ✅ Step 5: Test It!

### Test from your Flutter app:

1. **Run your app**
2. **Complete onboarding** (or manually trigger)
3. **Check Resend Dashboard** → **"Emails"** tab
4. **You should see the email sent!**

### Or test directly in Supabase:

1. **Go to Edge Functions** → `send-email`
2. **Click "Invoke"** tab
3. **Paste this JSON**:
```json
{
  "type": "welcome",
  "user_id": "test-123",
  "email": "your-email@example.com",
  "display_name": "Test User"
}
```
4. **Click "Invoke Function"**
5. **Check your email inbox!** 📧

---

## 🎉 Done!

Your email notifications are now set up! The app will automatically send:
- ✅ Welcome emails when users sign up
- ✅ Retention emails when users are inactive
- ✅ Onboarding sequence emails

---

## 🔧 Troubleshooting

### "Invalid API Key" Error?
- ✅ Check that `RESEND_API_KEY` secret is set in Supabase
- ✅ Make sure you copied the FULL API key
- ✅ Redeploy the Edge Function after adding the secret

### Emails Not Sending?
- ✅ Check Edge Function logs in Supabase
- ✅ Check Resend Dashboard → Emails tab
- ✅ Check spam folder

### "From email not verified" Error?
- ✅ Use `onboarding@resend.dev` for testing (already verified)
- ✅ Or add your own domain in Resend → Domains

---

## 📋 Quick Checklist

- [ ] Got API key from Resend
- [ ] Added `RESEND_API_KEY` secret to Supabase
- [ ] Created `send-email` Edge Function
- [ ] Pasted the code above
- [ ] Updated website URL in the code
- [ ] Deployed the function
- [ ] Tested sending an email

**You're all set!** 🚀

