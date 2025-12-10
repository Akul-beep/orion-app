# 📱 How to See Errors in Xcode - Visual Guide

## Where is the Console?

The console in Xcode is at the **bottom of the window**. Here's how to find it:

### Step 1: Look at the Bottom of Xcode

```
┌─────────────────────────────────────────┐
│  [Your Code Editor]                     │
│                                          │
│                                          │
├─────────────────────────────────────────┤
│  [Debug Area - This is what you need!]  │
│  ┌──────────────┬────────────────────┐ │
│  │ Variables    │ Console (errors)   │ │
│  │              │                    │ │
│  │              │ ❌ Error messages  │ │
│  │              │ appear here!       │ │
│  └──────────────┴────────────────────┘ │
└─────────────────────────────────────────┘
```

### Step 2: If You Don't See It

1. **Press `Shift + Cmd + Y`** (or go to **View → Show Debug Area**)
2. The bottom panel will appear
3. The **right side** is the **Console** - that's where errors show up!

### Step 3: What to Look For

When you try to login/signup, you'll see messages like:
- `🔐 Attempting login for: test@example.com`
- `❌ Login error details: [error message]`
- `✅ Login successful!` (if it works)

## Alternative: See Errors ON SCREEN

**You don't need the console!** Errors now show **directly in the app**:

1. **Red error box** - appears at the top of the login/signup form
2. **Red snackbar** - appears at the bottom of the screen (stays for 6 seconds)

## Quick Test

1. Run the app in Xcode
2. Try to login with any email/password
3. **Look at the screen** - you'll see a red error message
4. **OR look at the console** (bottom-right of Xcode)

The error message will tell you exactly what's wrong!

## Common Errors You Might See

- **"Network error"** → Simulator doesn't have internet
- **"Invalid email or password"** → Wrong credentials (or account doesn't exist)
- **"Service configuration error"** → Supabase not set up correctly
- **"Password is too weak"** → Need at least 6 characters






