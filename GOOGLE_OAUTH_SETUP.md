# 🔐 Google OAuth Setup Guide

## Quick Setup (2 Options)

### Option 1: Simple Setup (No Custom Credentials) ✅ RECOMMENDED

**Supabase provides default Google OAuth credentials!**

1. In Supabase Google provider settings:
   - ✅ Toggle **"Enable Sign in with Google"** to **ON**
   - ✅ Leave **Client IDs** field **EMPTY** (Supabase uses default)
   - ✅ Leave **Client Secret** field **EMPTY**
   - ✅ Click **"Save"**

**That's it!** Google Sign-In will work immediately.

---

### Option 2: Custom Setup (For Production/Advanced Users)

If you want to use your own Google OAuth credentials:

#### Step 1: Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select existing)
3. Enable **Google+ API**:
   - Go to "APIs & Services" → "Library"
   - Search for "Google+ API"
   - Click "Enable"
4. Create OAuth 2.0 Credentials:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: **"Web application"**
   - Name: "Orion App" (or any name)
   - **Authorized redirect URIs**: Add this EXACT URL:
     ```
     https://lpchovurnlmucwzaltvz.supabase.co/auth/v1/callback
     ```
   - Click "Create"
5. Copy your credentials:
   - **Client ID**: Copy this (looks like: `123456789-abc.apps.googleusercontent.com`)
   - **Client Secret**: Copy this (looks like: `GOCSPX-abc123...`)

#### Step 2: Add to Supabase

1. In Supabase Google provider settings:
   - ✅ Toggle **"Enable Sign in with Google"** to **ON**
   - ✅ Paste your **Client ID** in the "Client IDs" field
   - ✅ Paste your **Client Secret** in the "Client Secret (for Auth)" field
   - ✅ Click **"Save"**

---

## ✅ Recommended: Use Option 1

**For development and testing, Option 1 is perfect!** Supabase provides default Google OAuth credentials that work immediately.

**Only use Option 2 if:**
- You're deploying to production
- You need custom branding
- You need higher rate limits

---

## Test After Setup

1. Run the app
2. Click "Continue with Google"
3. Should redirect to Google login
4. After login, redirects back to app
5. You're logged in! ✅

---

## Troubleshooting

**"Provider is not enabled" error:**
- Make sure you clicked "Save" after enabling
- Refresh the Supabase dashboard and check again

**"Invalid redirect URI" error:**
- Make sure the callback URL in Google Cloud Console matches exactly:
  `https://lpchovurnlmucwzaltvz.supabase.co/auth/v1/callback`

**Still not working?**
- Try Option 1 (leave Client IDs empty)
- Check browser console for errors
- Make sure you ran the SQL script first (`supabase_setup.sql`)






