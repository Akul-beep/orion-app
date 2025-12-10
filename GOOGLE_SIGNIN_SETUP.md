# 🔐 How to Fix Google Sign-In

## The Problem

Google Sign-In is failing because **Google OAuth provider is not enabled** in your Supabase project.

## Quick Fix (2 Steps)

### Step 1: Enable Google Provider in Supabase

1. Go to: https://app.supabase.com
2. Select your project
3. Go to **Authentication** → **Providers** (left sidebar)
4. Find **"Google"** in the list
5. Click the toggle to **Enable** it
6. You'll see a message saying you need OAuth credentials

### Step 2: Set Up Google OAuth (If Needed)

**Option A: Quick Test (Skip OAuth Setup)**
- For testing, you can use **Email/Password** sign-in instead
- Google Sign-In requires additional setup

**Option B: Full Google OAuth Setup**

1. **Create Google OAuth Credentials:**
   - Go to: https://console.cloud.google.com/
   - Create a new project (or select existing)
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth client ID**
   - Application type: **Web application**
   - Authorized redirect URIs: 
     ```
     https://lpchovurnlmucwzaltvz.supabase.co/auth/v1/callback
     ```
   - Copy the **Client ID** and **Client Secret**

2. **Add to Supabase:**
   - Back in Supabase → **Authentication** → **Providers** → **Google**
   - Paste **Client ID** and **Client Secret**
   - Click **Save**

3. **For iOS (Additional Step):**
   - In Google Cloud Console, also create an **iOS** OAuth client
   - Bundle ID: Your app's bundle ID (e.g., `com.orion.app`)
   - Add this Client ID to Supabase as well

## Alternative: Use Email/Password Instead

For now, you can use **Email/Password** sign-in which works immediately:

1. Click **"Sign up"** on the login screen
2. Enter:
   - Name: Your name
   - Email: `test@example.com`
   - Password: `test1234` (at least 6 characters)
3. Click **"Create account"**

This will work right away without any additional setup!

## Test After Setup

1. Rebuild the app in Xcode
2. Try Google Sign-In again
3. You should see a browser window open for Google login
4. After signing in, you'll be redirected back to the app

## Current Error Message

The app now shows a helpful error message:
- **"Google Sign-In is not enabled in Supabase"** → Enable it in Supabase Dashboard
- **"Network error"** → Check internet connection
- **"Redirect URL configuration error"** → Check Supabase settings

## Need Help?

If you're stuck, just use **Email/Password** sign-in for now - it works perfectly and doesn't require any additional setup!
