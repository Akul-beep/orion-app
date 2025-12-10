# 📧 Email System Setup - Step by Step Guide

## 🎯 What You're Setting Up

You're setting up a professional email system that will:
- Send beautiful emails with your Ory character and logo
- Increase user retention (like Duolingo!)
- Send portfolio updates, streak reminders, achievements, etc.
- Work with Resend (free tier: 100 emails/day)

---

## ✅ Step 1: Get Your Resend API Key (5 minutes)

### 1.1 Sign Up for Resend
1. Go to: **https://resend.com**
2. Click **"Sign Up"** (use Google/GitHub for faster signup)
3. Verify your email

### 1.2 Create API Key
1. Once logged in, look at the **left sidebar**
2. Click **"API Keys"**
3. Click **"Create API Key"** button (top right)
4. Give it a name: `Orion App`
5. Click **"Create"**
6. **COPY THE API KEY** - it starts with `re_` and looks like:
   ```
   re_1234567890abcdefghijklmnopqrstuvwxyz
   ```
7. **SAVE THIS SOMEWHERE** - you'll need it in Step 3!

---

## ✅ Step 2: Update Database Schema (2 minutes)

### 2.1 Go to Supabase Dashboard
1. Go to: **https://app.supabase.com**
2. Sign in
3. Select your project (or create one if you don't have one)

### 2.2 Run SQL Script
1. In the left sidebar, click **"SQL Editor"**
2. Click **"New query"** button (top left)
3. Open the file: `update_email_logs_schema.sql` (in your project folder)
4. **Copy ALL the code** from that file
5. **Paste it** into the SQL Editor
6. Click **"Run"** button (or press Ctrl+Enter / Cmd+Enter)
7. You should see: ✅ **Success. No rows returned**

---

## ✅ Step 3: Deploy Edge Function (10 minutes)

### 3.1 Go to Edge Functions
1. In Supabase dashboard, click **"Edge Functions"** in the left sidebar
2. If you see a function called `send-email`, click on it
3. If you DON'T see it, click **"Create a new function"** button

### 3.2 Copy the Code
1. Open the file: `supabase/functions/send-email/index.ts` (in your project folder)
2. **Select ALL** the code (Ctrl+A / Cmd+A)
3. **Copy it** (Ctrl+C / Cmd+C)

### 3.3 Paste and Deploy
1. Go back to Supabase Edge Functions page
2. If creating new function:
   - Name it: `send-email`
   - Click **"Create function"**
3. **Delete everything** in the code editor
4. **Paste** your copied code
5. Click **"Deploy"** button (top right)

---

## ✅ Step 4: Add Secrets to Supabase (3 minutes)

### 4.1 Add Resend API Key
1. In Supabase dashboard, go to **"Edge Functions"** → **"Secrets"** (in left sidebar)
2. Click **"Add a new secret"** button
3. Fill in:
   - **Name**: `RESEND_API_KEY`
   - **Value**: Paste your Resend API key (the `re_...` one from Step 1)
4. Click **"Save"**

### 4.2 Add Your App URL (Optional but Recommended)
1. Click **"Add a new secret"** again
2. Fill in:
   - **Name**: `APP_URL`
   - **Value**: Your app's URL (e.g., `https://your-app.com` or `https://your-app.vercel.app`)
   - If you don't have one yet, use: `https://orion-stocksense.com` (or whatever you plan to use)
3. Click **"Save"**

### 4.3 Add Image Base URL (We'll do this in Step 5)
For now, skip this - we'll add it after uploading images.

---

## ✅ Step 5: Upload Ory Images to Supabase Storage (10 minutes)

### 5.1 Create Storage Bucket
1. In Supabase dashboard, click **"Storage"** in left sidebar
2. Click **"Create a new bucket"**
3. Name: `email-assets`
4. Make it **Public** (toggle ON)
5. Click **"Create bucket"**

### 5.2 Upload Logo
1. Click on the `email-assets` bucket
2. Click **"Upload file"**
3. Navigate to: `assets/logo/app_logo.png` (in your project folder)
4. Upload it
5. After upload, **right-click** on the file → **"Copy URL"**
6. The URL will look like: `https://xxxxx.supabase.co/storage/v1/object/public/email-assets/app_logo.png`
7. **Save this URL** - you'll need it!

### 5.3 Upload Ory Character Images
1. Still in the `email-assets` bucket
2. Click **"Create folder"** → Name: `character`
3. Click into the `character` folder
4. Upload these 4 files (one by one):
   - `assets/character/ory_friendly.png`
   - `assets/character/ory_concerned.png`
   - `assets/character/ory_excited.png`
   - `assets/character/ory_proud.png`
5. After each upload, **right-click** → **"Copy URL"**
6. **Save all 4 URLs**

### 5.4 Update Edge Function with Image URLs
1. Go back to **"Edge Functions"** → Click on `send-email`
2. Find these lines near the top (around line 7-14):
   ```typescript
   const IMAGE_BASE_URL = Deno.env.get('IMAGE_BASE_URL') || 'https://your-cdn.com/images'
   const ORION_LOGO_URL = `${IMAGE_BASE_URL}/logo/app_logo.png`
   const ORY_FRIENDLY_URL = `${IMAGE_BASE_URL}/character/ory_friendly.png`
   ```
3. **Replace** those lines with your actual URLs:
   ```typescript
   const ORION_LOGO_URL = 'https://YOUR_SUPABASE_URL/storage/v1/object/public/email-assets/app_logo.png'
   const ORY_FRIENDLY_URL = 'https://YOUR_SUPABASE_URL/storage/v1/object/public/email-assets/character/ory_friendly.png'
   const ORY_CONCERNED_URL = 'https://YOUR_SUPABASE_URL/storage/v1/object/public/email-assets/character/ory_concerned.png'
   const ORY_EXCITED_URL = 'https://YOUR_SUPABASE_URL/storage/v1/object/public/email-assets/character/ory_excited.png'
   const ORY_PROUD_URL = 'https://YOUR_SUPABASE_URL/storage/v1/object/public/email-assets/character/ory_proud.png'
   ```
   (Replace `YOUR_SUPABASE_URL` with your actual Supabase project URL)
4. Click **"Deploy"** again

---

## ✅ Step 6: Test the Email System (5 minutes)

### 6.1 Test Welcome Email
1. In your Flutter app, create a test account or use an existing one
2. When you sign up, a welcome email should be sent automatically
3. Check the email inbox you used to sign up
4. You should see a beautiful email with:
   - Orion logo at the top
   - Ory character image
   - Welcome message
   - Blue gradient buttons

### 6.2 Check Resend Dashboard
1. Go to: **https://resend.com/emails**
2. You should see your email in the list
3. Click on it to see:
   - Status (should be "Delivered")
   - Email preview
   - Open/click tracking (if enabled)

### 6.3 Check Supabase Logs
1. In Supabase dashboard → **"Edge Functions"** → Click `send-email`
2. Click **"Logs"** tab
3. You should see logs showing the email was sent

---

## ✅ Step 7: Verify Everything Works

### Checklist:
- [ ] Resend API key added to Supabase secrets ✅
- [ ] Database schema updated ✅
- [ ] Edge function deployed ✅
- [ ] Images uploaded to Supabase Storage ✅
- [ ] Image URLs updated in edge function ✅
- [ ] Welcome email received ✅
- [ ] Email looks good (logo, Ory character, styling) ✅

---

## 🎉 You're Done!

Your email system is now set up! Emails will automatically send when:
- ✅ User signs up (welcome email)
- ✅ User levels up (level up email)
- ✅ User earns achievement (achievement email)
- ✅ Streak milestone reached (streak milestone email)
- ✅ Streak broken (streak lost email)
- ✅ User inactive 3+ days (retention email)
- ✅ Weekly portfolio updates (for inactive users)
- ✅ Leaderboard rank changes (if in top 10)

---

## 🐛 Troubleshooting

### "Email not sending"
1. Check Resend dashboard → Emails tab → See if there's an error
2. Check Supabase Edge Functions → Logs → Look for errors
3. Verify `RESEND_API_KEY` secret is set correctly
4. Make sure you're using `onboarding@resend.dev` as FROM email (for free tier)

### "Images not showing"
1. Check image URLs are correct in edge function
2. Make sure Storage bucket is **Public**
3. Test image URLs in browser - they should load directly

### "Edge function error"
1. Check Supabase Edge Functions → Logs
2. Look for TypeScript errors
3. Make sure all code was copied correctly

### "Database error"
1. Make sure you ran `update_email_logs_schema.sql`
2. Check Supabase → Table Editor → `email_logs` table exists

---

## 📞 Need Help?

If something doesn't work:
1. Check the error message in Supabase Edge Functions → Logs
2. Check Resend dashboard for email delivery status
3. Make sure all steps were completed in order

---

## 🚀 Next Steps (Optional)

Once everything works:
1. **Monitor email performance** in Resend dashboard
2. **Track open rates** to see which emails work best
3. **Customize email content** in the edge function if needed
4. **Add custom domain** to Resend (when ready to scale)

---

**That's it! Your email system is ready to maximize retention! 🎉**
