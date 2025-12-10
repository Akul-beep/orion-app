# 🔧 Fix Google Sign-In "Provider Disabled" Error

## The Problem

Even though Google provider is enabled in Supabase, you're getting "disabled" error. This is usually because:

1. **Redirect URL not configured** in Supabase
2. **OAuth credentials not set up** properly
3. **Redirect URL mismatch** between app and Supabase

## Quick Fix

### Step 1: Check Supabase Redirect URLs

1. Go to: https://app.supabase.com
2. Select your project
3. Go to **Authentication** → **URL Configuration**
4. Look for **"Redirect URLs"** section
5. Make sure these URLs are added:
   ```
   com.orion.app://callback
   com.orion.app://
   ```
6. Click **"Save"**

### Step 2: Verify Google Provider Settings

1. Still in Supabase, go to **Authentication** → **Providers**
2. Click on **"Google"**
3. Make sure:
   - ✅ **Enabled** toggle is ON
   - ✅ **Client ID** is filled in
   - ✅ **Client Secret** is filled in
4. If any are missing, you need to set up Google OAuth (see below)

### Step 3: Set Up Google OAuth (If Not Done)

If Client ID/Secret are missing:

1. **Go to Google Cloud Console:**
   - https://console.cloud.google.com/
   - Create/select a project

2. **Enable Google+ API:**
   - Go to **APIs & Services** → **Library**
   - Search for "Google+ API"
   - Click **Enable**

3. **Create OAuth Credentials:**
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth client ID**
   - Application type: **Web application**
   - Name: "Orion App Web"
   - **Authorized redirect URIs:** Add:
     ```
     https://lpchovurnlmucwzaltvz.supabase.co/auth/v1/callback
     ```
   - Click **Create**
   - Copy **Client ID** and **Client Secret**

4. **Also Create iOS OAuth Client:**
   - Click **Create Credentials** → **OAuth client ID** again
   - Application type: **iOS**
   - Bundle ID: `com.orion.app` (or your bundle ID)
   - Click **Create**
   - Copy this **Client ID** too

5. **Add to Supabase:**
   - Back in Supabase → **Authentication** → **Providers** → **Google**
   - Paste **Web Client ID** and **Client Secret**
   - (iOS Client ID is optional, but recommended)
   - Click **Save**

### Step 4: Test Again

1. Rebuild the app in Xcode
2. Try Google Sign-In again
3. It should work now!

## Alternative: Skip Google Sign-In for Now

Since **Email/Password signup works perfectly**, you can:
- Use Email/Password for now
- Set up Google Sign-In later when you have time

The app works great with just Email/Password authentication!

## About the Xcode Warnings

The `PhaseScriptExecution` warnings are **harmless** - they're just build script warnings that don't affect the app. You can ignore them. They're common in Flutter iOS projects.






