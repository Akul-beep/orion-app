# Authentication Bypass Instructions

## Overview
The authentication has been temporarily bypassed to allow testing on restricted networks (e.g., school networks that block Google Sign-In and Supabase).

## How to Toggle Bypass

### To Bypass Authentication (Skip Login):
1. Open `lib/screens/auth_wrapper.dart`
2. Find the constant at the top:
   ```dart
   const bool _BYPASS_AUTH = true;
   ```
3. Set it to `true` to skip authentication

### To Re-enable Authentication:
1. Open `lib/screens/auth_wrapper.dart`
2. Find the constant:
   ```dart
   const bool _BYPASS_AUTH = false;
   ```
3. Set it to `false` to require authentication again

## What Happens When Bypassed

- ✅ App goes directly to the main screen (no login required)
- ✅ Onboarding is automatically skipped
- ✅ App uses local storage for data (no Supabase connection needed)
- ⚠️ Login and signup screens are still in the code but not shown
- ⚠️ Some features that require Supabase may not work (but won't crash)

## Notes

- The login and signup screens are **NOT deleted** - they're just bypassed
- When you're back on a normal network, set `_BYPASS_AUTH = false` to re-enable authentication
- The app will gracefully handle Supabase connection failures and continue working with local storage

## Current Status
**BYPASS IS ENABLED** (`_BYPASS_AUTH = true`)



