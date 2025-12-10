# PostHog Debugging Guide

## Quick Checks:

1. **Check Console Logs:**
   - Look for logs that start with `📊`, `⚠️`, or `✅` related to analytics
   - Check if you see "PostHog API error" messages
   - Check if you see "Analytics service initialized"

2. **Verify API Key:**
   - Open `lib/services/analytics_service.dart`
   - Line 12 should have your API key: `phc_TjMiRpV0vQxcRQrSbCX76iGXELIM3VwFbDe0qZs61aM`
   - Make sure it matches your PostHog dashboard

3. **Check PostHog Project:**
   - Go to PostHog dashboard
   - Make sure you're looking at the right project
   - Check "Live events" - events appear within seconds

4. **Check Event Format:**
   - PostHog expects events in a specific format
   - The endpoint might need to be `/batch/` instead of `/capture/`

## Common Issues:

1. **Wrong API Endpoint:** PostHog uses `/batch/` endpoint
2. **Wrong Event Format:** Events need to be in an array with specific structure
3. **API Key Mismatch:** Make sure you're using the Project API Key, not Personal API Key
4. **Rate Limiting:** Free tier has limits but shouldn't block basic events

## Fix Needed:

The analytics service needs to use the correct PostHog batch endpoint format.

