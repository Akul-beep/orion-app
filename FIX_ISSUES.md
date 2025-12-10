# 🔧 Fix These Issues

## Issue 1: Google Sign-In Error ✅ FIX

**Error:** `"Unsupported provider: provider is not enabled"`

**Solution:** Add Google credentials to Supabase:

1. Go to: https://app.supabase.com/project/lpchovurnlmucwzaltvz
2. Click **"Authentication"** → **"Providers"** → **"Google"**
3. Toggle **"Enable Sign in with Google"** to **ON**
4. **Client IDs**: 
   ```
   434755901022-vereenficj143q0ho24rru1m4npo1use.apps.googleusercontent.com
   ```
5. **Client Secret (for Auth)**:
   ```
   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
   ```
6. Click **"Save"**

---

## Issue 2: Email Sign-Up Not Showing in Supabase ✅ FIX

**Problem:** User signed up but not in `user_profiles` table

**Possible Causes:**
1. **Email confirmation required** - Supabase might require email confirmation
2. **Error during signup** - Check browser console for errors
3. **Tables not created** - Make sure SQL script ran successfully

**Quick Fixes:**

### Fix A: Disable Email Confirmation (For Testing)

1. Go to: https://app.supabase.com/project/lpchovurnlmucwzaltvz
2. Click **"Authentication"** → **"Settings"**
3. Find **"Enable email confirmations"**
4. Toggle it to **OFF**
5. Click **"Save"**

Now users can sign up without email confirmation!

### Fix B: Check if Tables Exist

1. Go to: https://app.supabase.com/project/lpchovurnlmucwzaltvz
2. Click **"Table Editor"** (left sidebar)
3. Check if you see these tables:
   - `user_profiles`
   - `portfolio`
   - `trades`
   - `gamification`
   - `leaderboard`
   - `watchlist`
   - `completed_actions`
   - `stock_cache`

If tables don't exist, run the SQL script again!

### Fix C: Check Browser Console

1. Open browser DevTools (F12)
2. Go to "Console" tab
3. Try signing up again
4. Look for any red errors
5. Share the errors with me

---

## Test After Fixes

1. **Disable email confirmation** (Fix A)
2. **Add Google credentials** (Issue 1)
3. **Try signing up again** with email/password
4. **Check Supabase Table Editor** → `user_profiles` table
5. **Try Google Sign-In**

---

## Still Not Working?

Check the browser console (F12) and share any errors you see!






