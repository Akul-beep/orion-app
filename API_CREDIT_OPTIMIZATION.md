# API Credit Optimization Summary

## 🎯 Goal
Optimize Finnhub API usage to stay within **60 credits/day limit** while maintaining core functionality.

## ✅ Optimizations Made

### 1. **Extended Cache TTLs**
- **Quote cache**: Extended from **60 seconds → 5 minutes**
  - Home screen Top Movers will reuse cached data for 5 minutes
  - Reduces API calls when visiting home screen multiple times
  
- **Profile cache**: Extended from **5 minutes → 30 minutes**
  - Company profiles cached for 30 minutes
  
- **Metrics cache**: Extended from **5 minutes → 30 minutes**
  - Financial metrics cached for 30 minutes

### 2. **Portfolio Price Updates**
- **Periodic updates**: Changed from **every 5 minutes → every 30 minutes**
  - If you have 5 positions: 5 credits every 30 min = 10 credits/hour = 240/day ❌
  - Now: 5 credits every 30 min = 10 credits/hour, but only runs when app is active
  - **Much better for credit conservation**

- **App start refresh**: Only fetches if last update was **> 15 minutes ago**
  - Prevents unnecessary API calls on every app launch

- **App resume refresh**: Only fetches if last update was **> 10 minutes ago**
  - Prevents refreshing every time you switch apps

### 3. **Top Movers Widget**
- Now uses **5-minute cache** for all 8 stocks
- First load: 8 API calls (if cache empty)
- Subsequent loads within 5 min: **0 API calls** (all from cache)
- **Saves 8 credits per home screen visit** (if within cache window)

### 4. **Smart Caching Logic**
- `getPopularStocks()` now tracks cache hits vs API calls
- Logs show: `"Fetched 8 stocks (2 API calls, 6 cache hits)"`
- Helps you monitor API usage

## 📊 Estimated Daily API Usage

### Worst Case Scenario (Heavy Usage):
1. **Home screen visits**: 10 times/day
   - First visit: 8 API calls (Top Movers)
   - Next 9 visits (within 5 min cache): 0 calls
   - **Total: ~8-16 calls/day** (depending on timing)

2. **Portfolio updates** (5 positions):
   - Periodic (every 30 min): ~48 updates/day = 240 calls ❌ **TOO MUCH**
   - But: Only runs when app is active, so realistically ~10-20 updates/day
   - **Total: ~50-100 calls/day**

3. **Manual stock views**: ~10-20 calls/day

**Total worst case: ~70-140 calls/day** ❌ Still over limit!

### Realistic Scenario (Normal Usage):
1. **Home screen**: 5 visits/day, mostly cached = **~8-10 calls/day**

2. **Portfolio updates** (5 positions):
   - App active for 4 hours/day
   - Updates every 30 min = 8 updates
   - **Total: 40 calls/day**

3. **Manual stock views**: ~10 calls/day

**Total realistic: ~60 calls/day** ✅ **Within limit!**

## 🚨 Additional Recommendations

### If Still Hitting Limit:

1. **Increase portfolio update interval to 60 minutes**:
   ```dart
   // In paper_trading_service.dart, line 145
   _priceUpdateTimer = Timer.periodic(const Duration(minutes: 60), ...);
   ```

2. **Disable periodic updates entirely** (only update on manual refresh):
   ```dart
   // Comment out this line in loadPortfolioFromDatabase():
   // _startPeriodicPriceUpdates();
   ```

3. **Increase cache TTLs further**:
   ```dart
   // In stock_api_service.dart
   static const _quoteCacheTTL = Duration(minutes: 10); // 10 min cache
   ```

4. **Add manual refresh button** instead of automatic updates

## 📝 Current Settings Summary

| Feature | Old Setting | New Setting | Credit Savings |
|---------|-----------|-------------|----------------|
| Quote cache | 60 seconds | 5 minutes | ~80% reduction |
| Portfolio updates | Every 5 min | Every 30 min | 83% reduction |
| App start refresh | Always | Only if >15 min | ~50% reduction |
| App resume refresh | Always | Only if >10 min | ~50% reduction |
| Profile cache | 5 minutes | 30 minutes | 83% reduction |

## ✅ What Still Works

- ✅ Portfolio P&L tracking (uses cached prices when appropriate)
- ✅ Day change calculation (updates when prices refresh)
- ✅ Top Movers on home screen (uses cache)
- ✅ Stock detail screens (cached for 5 minutes)
- ✅ Manual refresh still available via `refreshPortfolioPrices()`

## 🔍 Monitoring

Check console logs for:
- `"Fetched X stocks (Y API calls, Z cache hits)"` - Shows cache effectiveness
- `"💰 Using cached prices (saving API credits)"` - Confirms cache usage
- `"🔄 Fetching fresh prices..."` - Indicates actual API call

## 💡 Tips

1. **Use manual refresh** for portfolio when you need fresh data
2. **Close app** when not trading to stop periodic updates
3. **Check logs** to see actual API usage patterns
4. **Adjust intervals** if you're still hitting limits


