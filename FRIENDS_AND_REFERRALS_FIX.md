# Friends and Referrals System Fix

## Summary
Fixed multiple issues with the friends and referral system, including search functionality, friend request sending, and Supabase integration.

## Issues Fixed

### 1. User Search Functionality ✅
**Problem:** Search was not working due to:
- Incorrect data structure access (trying to access fields directly instead of from JSONB `data` column)
- RLS policy issues
- Missing error handling

**Solution:**
- Updated `searchUsers()` to properly parse JSONB `data` column from `user_profiles` table
- Added support for multiple field name variations (`displayName`, `name`, `display_name`)
- Improved error handling and logging
- Added support for both Map and String JSONB data formats

### 2. Friend Request Sending ✅
**Problem:** Could not add friends due to:
- Not checking for authentication before sending requests
- Using local user IDs instead of Supabase UUIDs
- Missing validation for existing requests/friendships

**Solution:**
- Added authentication check before sending requests
- Ensured only Supabase UUIDs are used (not local IDs)
- Added checks for existing requests and friendships
- Improved error messages and logging
- Added proper validation for duplicate requests

### 3. Friends List Loading ✅
**Problem:** Friends list was not loading correctly due to:
- Incorrect data structure access from JSONB columns
- Not using authenticated user IDs

**Solution:**
- Fixed `_loadFriends()` to properly parse JSONB `data` from `user_profiles`
- Updated to use authenticated user IDs when available
- Fixed gamification and portfolio data loading
- Added proper error handling for missing data

### 4. Referrals Table Schema ✅
**Problem:** Referrals table structure didn't match code expectations

**Solution:**
- Updated `referrals_table.sql` to use `referrer_code` instead of `referrer_user_id`
- Fixed RLS policies to work with the new structure
- Updated indexes accordingly

### 5. RLS Policies ✅
**Problem:** RLS policies were too restrictive and didn't handle UUID comparisons properly

**Solution:**
- Updated `friend_requests_table.sql` RLS policies to handle both UUID and text comparisons
- Made policies more flexible while maintaining security

## Files Modified

1. **lib/services/friend_service.dart**
   - Fixed `searchUsers()` function
   - Fixed `sendFriendRequest()` function
   - Fixed `_loadFriends()` function
   - Fixed `_loadPendingRequests()` function
   - Fixed `_loadSentRequests()` function
   - Fixed `acceptFriendRequest()` function
   - Fixed `rejectFriendRequest()` function
   - Fixed `removeFriend()` function
   - Fixed `cancelFriendRequest()` function
   - Added proper authentication checks throughout
   - Added better error handling and logging

2. **referrals_table.sql**
   - Updated schema to match code expectations
   - Fixed RLS policies
   - Updated indexes

3. **friend_requests_table.sql**
   - Updated RLS policies to handle UUID/text comparisons
   - Made policies more flexible

## Required Supabase Setup

Run these SQL scripts in your Supabase SQL Editor:

### 1. Update Referrals Table
```sql
-- Run the updated referrals_table.sql file
-- This updates the table structure to match the code
```

### 2. Update Friend Requests RLS Policies
```sql
-- Run the updated friend_requests_table.sql file
-- This updates the RLS policies for better compatibility
```

### 3. Verify User Profiles Table
Make sure your `user_profiles` table has:
- `user_id` (UUID, primary key, references auth.users)
- `data` (JSONB) - stores profile data including:
  - `displayName` or `name` or `display_name`
  - `email` (optional but recommended)
  - `photoURL` or `photo_url` or `avatar`
  - `lastActiveAt` or `last_active`

### 4. Verify Friends Table
Make sure your `friends` table has:
- `user_id` (UUID, references auth.users)
- `friend_id` (UUID, references auth.users)
- `status` (TEXT, default 'accepted')
- `created_at` (TIMESTAMP)

### 5. Verify Friend Requests Table
Make sure your `friend_requests` table has:
- `id` (UUID, primary key)
- `from_user_id` (UUID, references auth.users)
- `from_display_name` (TEXT)
- `from_photo_url` (TEXT, optional)
- `to_user_id` (UUID, references auth.users)
- `status` (TEXT, default 'pending')
- `created_at` (TIMESTAMP)

## Testing Checklist

- [ ] Search for users by name works
- [ ] Search for users by email works
- [ ] Can send friend request
- [ ] Cannot send duplicate friend requests
- [ ] Can accept friend request
- [ ] Can reject friend request
- [ ] Can cancel sent friend request
- [ ] Friends list loads correctly
- [ ] Friend profiles show correct data (name, photo, portfolio, level, XP, streak)
- [ ] Referral codes work correctly

## Important Notes

1. **Authentication Required**: Most friend features now require the user to be authenticated with Supabase (not just using local IDs). Make sure users are logged in before using these features.

2. **Data Structure**: The code expects user profile data to be stored in the JSONB `data` column with camelCase keys (`displayName`, `photoURL`, etc.) or snake_case (`display_name`, `photo_url`, etc.).

3. **Error Handling**: All functions now have better error handling and will log detailed error messages. Check the console for debugging information.

4. **RLS Policies**: The updated RLS policies are more flexible but still secure. They allow users to:
   - View their own friend requests (sent or received)
   - Send friend requests
   - Accept/reject requests sent to them
   - Cancel requests they sent

## Next Steps

1. Run the updated SQL scripts in Supabase
2. Test the search functionality
3. Test sending and accepting friend requests
4. Verify friends list loads correctly
5. Check that referral codes work as expected

If you encounter any issues, check the console logs for detailed error messages.

