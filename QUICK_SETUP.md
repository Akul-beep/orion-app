# 🚀 QUICK SETUP GUIDE

## Step 1: Create Database Tables (REQUIRED)

1. Go to: https://app.supabase.com/project/lpchovurnlmucwzaltvz
2. Click **"SQL Editor"** in left sidebar
3. Click **"New query"**
4. Copy **ALL** the SQL from `supabase_setup.sql` file
5. Paste into the SQL Editor
6. Click **"Run"** (or press Cmd/Ctrl + Enter)
7. You should see: "Success. No rows returned"

✅ **Tables created!**

---

## Step 2: Enable Google Sign-In (REQUIRED for Google login)

**You need to create Google OAuth credentials first!**

### Quick Steps:

1. **Create Google OAuth Client ID** (5 minutes):
   - Follow the detailed guide in `GOOGLE_CLIENT_ID_SETUP.md`
   - Or quick version below ⬇️

2. **Add to Supabase:**
   - Go to: https://app.supabase.com/project/lpchovurnlmucwzaltvz
   - Click **"Authentication"** → **"Providers"** → **"Google"**
   - Toggle **"Enable Sign in with Google"** to **ON**
   - Paste your **Client ID** in "Client IDs" field
   - Paste your **Client Secret** in "Client Secret (for Auth)" field
   - Click **"Save"**

✅ **Google Sign-In enabled!**

### Quick Google OAuth Setup:

1. Go to: https://console.cloud.google.com/
2. Create a new project (or use existing)
3. Enable **"Google+ API"** (APIs & Services → Library)
4. Create **OAuth Client ID** (APIs & Services → Credentials):
   - Application type: **"Web application"**
   - Authorized redirect URI: `https://lpchovurnlmucwzaltvz.supabase.co/auth/v1/callback`
5. Copy **Client ID** and **Client Secret**
6. Paste into Supabase (see Step 2 above)

**Full detailed guide:** See `GOOGLE_CLIENT_ID_SETUP.md`

---

## Step 3: Test the App

1. **Email/Password Sign-Up:**
   - Click "Sign Up"
   - Enter name, email, password
   - Should create account and log you in

2. **Email/Password Sign-In:**
   - Use the email/password you just created
   - Should log you in

3. **Google Sign-In:**
   - Click "Continue with Google"
   - Should redirect to Google login
   - After login, redirects back to app
   - (Only works if Step 2 is done)

---

## ✅ That's It!

Your app is now fully connected to Supabase with:
- ✅ Database tables created
- ✅ User authentication working
- ✅ All data saving to Supabase
- ✅ Google Sign-In ready (if enabled)

**If you see errors:**
- "Google sign-in failed" → Enable Google provider (Step 2)
- "Table doesn't exist" → Run SQL script (Step 1)
- Any other errors → Check terminal for details

