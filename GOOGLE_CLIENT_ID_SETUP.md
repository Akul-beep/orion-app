# 🔑 Create Google OAuth Client ID (5 minutes)

## Step-by-Step Guide

### Step 1: Go to Google Cloud Console

1. Go to: https://console.cloud.google.com/
2. **Sign in** with your Google account

---

### Step 2: Create a Project

1. Click the **project dropdown** at the top (next to "Google Cloud")
2. Click **"New Project"**
3. Project name: `Orion App` (or any name)
4. Click **"Create"**
5. Wait a few seconds, then **select your new project** from the dropdown

---

### Step 3: Enable Google+ API

1. Go to **"APIs & Services"** → **"Library"** (left sidebar)
2. Search for **"Google+ API"**
3. Click on it
4. Click **"Enable"**
5. Wait for it to enable (takes a few seconds)

---

### Step 4: Create OAuth Credentials

1. Go to **"APIs & Services"** → **"Credentials"** (left sidebar)
2. Click **"+ CREATE CREDENTIALS"** (top of page)
3. Select **"OAuth client ID"**
4. If prompted, configure OAuth consent screen:
   - User Type: **"External"** → Click **"Create"**
   - App name: `Orion App`
   - User support email: **Your email**
   - Developer contact: **Your email**
   - Click **"Save and Continue"**
   - Scopes: Click **"Save and Continue"** (default is fine)
   - Test users: Click **"Save and Continue"** (skip for now)
   - Summary: Click **"Back to Dashboard"**
5. Now create OAuth Client ID:
   - Application type: **"Web application"**
   - Name: `Orion Web Client`
   - **Authorized redirect URIs**: Click **"+ ADD URI"**
   - Paste this EXACT URL:
     ```
     https://lpchovurnlmucwzaltvz.supabase.co/auth/v1/callback
     ```
   - Click **"Create"**

---

### Step 5: Copy Your Credentials

You'll see a popup with:
- **Client ID**: Copy this (looks like: `123456789-abc.apps.googleusercontent.com`)
- **Client secret**: Copy this (looks like: `GOCSPX-abc123...`)

**Keep this window open!** You'll need these in the next step.

---

### Step 6: Add to Supabase

1. Go back to Supabase: https://app.supabase.com/project/lpchovurnlmucwzaltvz
2. Go to **"Authentication"** → **"Providers"** → **"Google"**
3. Toggle **"Enable Sign in with Google"** to **ON**
4. **Client IDs**: Paste your **Client ID** here
5. **Client Secret (for Auth)**: Paste your **Client Secret** here
6. Click **"Save"**

---

## ✅ Done!

Now Google Sign-In should work! Test it in your app.

---

## Troubleshooting

**"Invalid redirect URI" error:**
- Make sure the redirect URI in Google Cloud Console matches EXACTLY:
  `https://lpchovurnlmucwzaltvz.supabase.co/auth/v1/callback`
- No trailing slashes, no spaces

**"OAuth consent screen" required:**
- Just follow Step 4 above - it's a one-time setup

**Still not working?**
- Make sure you enabled "Google+ API" (Step 3)
- Check that the Client ID and Secret are copied correctly (no extra spaces)






