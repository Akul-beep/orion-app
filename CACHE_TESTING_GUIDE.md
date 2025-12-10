# Stock Cache Testing Guide

## Quick Test Methods

### 1. **Console Log Testing** (Easiest)

Run your app and watch the console logs. You should see:

#### First Time (Cold Cache):
```
📊 Fetching popular stocks (using shared cache + batch optimization)...
🔍 Fetching REAL quote for AAPL from Finnhub...
📡 Direct Finnhub API call: ... (0/50 calls this minute)
✅ Got REAL data for AAPL: $150.00
💾 Saved shared cache for AAPL (available to all users)
```

#### Second Time (Warm Cache - Same User):
```
📊 Fetching popular stocks (using shared cache + batch optimization)...
✅ [CACHE HIT] AAPL: $150.00
✅ [SHARED CACHE HIT] Quote for AAPL (age: 30s, ttl: 300s)
```

#### Third Time (Different User/Device):
```
📊 Fetching popular stocks (using shared cache + batch optimization)...
✅ [CACHE HIT] AAPL: $150.00
✅ [SHARED CACHE HIT] Quote for AAPL (age: 60s, ttl: 300s)
```

**What to look for:**
- ✅ `[CACHE HIT]` = In-memory cache working
- ✅ `[SHARED CACHE HIT]` = Database cache working (shared across users)
- 🔍 `Fetching REAL quote` = Cache miss, making API call
- ⏰ `[CACHE EXPIRED]` = Cache expired, will fetch fresh data

---

### 2. **Test Rate Limiting**

To test rate limiting, you can temporarily lower the limits in `stock_api_service.dart`:

```dart
static const int _maxCallsPerMinute = 5; // Lower for testing
static const int _maxCallsPerSecond = 1; // Lower for testing
```

Then try fetching many stocks quickly. You should see:
```
⏳ Rate limit: 5/5 calls in last minute. Waiting 15s...
```

---

### 3. **Test Stale Cache Fallback**

To test stale cache fallback, you can:
1. Fetch a stock (it gets cached)
2. Wait 6+ minutes (cache expires)
3. Disconnect internet or block API calls
4. Try to fetch the same stock
5. Should see: `✅ [STALE CACHE FALLBACK] Using stale data...`

---

### 4. **Check Supabase Cache Table**

1. Go to your Supabase dashboard
2. Navigate to **Table Editor** → `stock_cache`
3. You should see entries like:
   - `cache_key`: `quote_AAPL`
   - `cache_data`: JSON with quote data
   - `updated_at`: Timestamp

**Test shared cache:**
- User A fetches AAPL → Entry created in `stock_cache`
- User B fetches AAPL → Should see same entry (shared!)

---

### 5. **Performance Testing**

#### Before Optimization:
- Opening app: ~8 API calls (one per stock)
- Each user opening app: ~8 API calls

#### After Optimization:
- Opening app (first user): ~8 API calls (cache empty)
- Opening app (second user, within 5 min): ~0 API calls (all cached!)
- Opening app (after 5 min): Only expired stocks fetched

**How to measure:**
1. Watch console logs for `📡 Direct Finnhub API call` messages
2. Count how many appear
3. First user: Should see ~8
4. Second user (within 5 min): Should see ~0

---

### 6. **Multi-User Test**

1. **Device 1 (User A):**
   - Open app
   - Go to home screen
   - Check console: Should see API calls

2. **Device 2 (User B) - Same or different account:**
   - Open app within 5 minutes
   - Go to home screen
   - Check console: Should see `[SHARED CACHE HIT]` messages
   - **No API calls should be made!**

---

### 7. **Cache Expiration Test**

1. Fetch a stock (e.g., AAPL)
2. Wait 6 minutes (cache TTL is 5 minutes)
3. Fetch same stock again
4. Should see:
   ```
   ⏰ [CACHE EXPIRED] Quote for AAPL (age: 360s > ttl: 300s)
   🔍 Fetching REAL quote for AAPL from Finnhub...
   ```

---

### 8. **Batch Fetching Test**

1. Clear cache: `StockApiService.clearCache()` (or restart app)
2. Call `getPopularStocks()`
3. Watch console logs
4. Should see:
   - Parallel cache checks for all 8 symbols
   - Only missing/expired stocks fetched from API
   - Example: `📡 Fetching 3 stocks from API (5 from cache)...`

---

## Expected Console Output Examples

### ✅ **Perfect Cache Hit (All Cached)**
```
📊 Fetching popular stocks (using shared cache + batch optimization)...
✅ [CACHE HIT] AAPL: $150.00
✅ [CACHE HIT] GOOGL: $2800.00
✅ [CACHE HIT] MSFT: $350.00
...
📈 Fetched 8 stocks (0 API calls, 8 cache hits)
```

### 🔍 **Partial Cache (Some Cached)**
```
📊 Fetching popular stocks (using shared cache + batch optimization)...
✅ [CACHE HIT] AAPL: $150.00
✅ [CACHE HIT] GOOGL: $2800.00
📡 Fetching 6 stocks from API (2 from cache)...
✅ [API] Got MSFT: $350.00
✅ [API] Got TSLA: $250.00
...
📈 Fetched 8 stocks (6 API calls, 2 cache hits)
```

### ⚠️ **Rate Limit Test**
```
📡 Direct Finnhub API call: ... (49/50 calls this minute)
⏳ Rate limit: 50/50 calls in last minute. Waiting 2s...
✅ [STALE CACHE FALLBACK] Using stale data for AAPL: $150.00
```

---

## Quick Test Checklist

- [ ] First app open makes API calls
- [ ] Second app open (within 5 min) uses cache (no API calls)
- [ ] Cache expires after 5 minutes
- [ ] Stale cache used on rate limit errors
- [ ] Multiple users share same cache
- [ ] Rate limiting prevents exceeding 50 calls/minute
- [ ] Batch fetching only gets missing stocks
- [ ] Console logs show cache hits/misses clearly

---

## Troubleshooting

### Cache not working?
1. Check Supabase connection: `DatabaseService.init()`
2. Check RLS policies: Cache should be publicly readable
3. Check console logs for errors

### Still making too many API calls?
1. Check cache TTL: Should be 5 minutes for quotes
2. Check if cache is being saved: Look for `💾 Saved shared cache`
3. Verify Supabase `stock_cache` table has entries

### Rate limiting not working?
1. Check `_apiCallHistory` is tracking calls
2. Look for `⏳ Rate limit` messages in console
3. Verify limits: `_maxCallsPerMinute = 50`

---

## Manual Test Script

You can add this to your app temporarily to test:

```dart
// In your app, add a test button:
ElevatedButton(
  onPressed: () async {
    print('🧪 TESTING CACHE SYSTEM...');
    
    // Test 1: First fetch (should hit API)
    print('\n📊 Test 1: First fetch (cold cache)');
    final stocks1 = await StockApiService.getPopularStocks();
    print('Got ${stocks1.length} stocks');
    
    // Wait 1 second
    await Future.delayed(Duration(seconds: 1));
    
    // Test 2: Second fetch (should hit cache)
    print('\n📊 Test 2: Second fetch (warm cache)');
    final stocks2 = await StockApiService.getPopularStocks();
    print('Got ${stocks2.length} stocks');
    
    // Test 3: Check Supabase cache
    print('\n📊 Test 3: Checking Supabase cache');
    final cached = await DatabaseService.getCachedQuote('AAPL');
    if (cached != null) {
      print('✅ AAPL is cached in Supabase!');
    } else {
      print('❌ AAPL not found in cache');
    }
  },
  child: Text('Test Cache System'),
)
```

