# Portfolio P&L Tracking Fix - Summary

## ✅ What Was Fixed

### 1. **Day Start Value Tracking**
- Added `_dayStartValue` to track portfolio value at the start of each day
- Added `_dayStartDate` to track when the day start value was set
- Automatically detects new day and resets day start value

### 2. **Portfolio Price Updates**
- Portfolio now fetches fresh prices when:
  - App starts (if positions exist and last update was > 5 minutes ago)
  - App comes to foreground
  - Every 5 minutes automatically (periodic updates)
  - Manually via `refreshPortfolioPrices()`

### 3. **Day Change Calculation**
- Day change is now calculated as: `currentValue - dayStartValue`
- Day change percent: `(dayChange / dayStartValue) * 100`
- Automatically updates whenever portfolio value changes

### 4. **P&L Tracking**
- Total P&L (unrealized) is calculated from all positions
- Each position tracks:
  - `unrealizedPnL`: `(currentPrice - averagePrice) * quantity`
  - `unrealizedPnLPercent`: `((currentPrice - averagePrice) / averagePrice) * 100`
- Portfolio total P&L is sum of all position P&Ls

### 5. **Automatic Updates**
- Periodic timer updates prices every 5 minutes (only if positions exist)
- App lifecycle observer refreshes prices when app comes to foreground
- Home screen refreshes portfolio when displayed

## 📊 Database Schema

**No schema changes needed!** All new fields are stored in the existing JSONB `data` column in the `portfolio` table.

The portfolio JSON now includes:
```json
{
  "cashBalance": 10000.0,
  "positions": [...],
  "tradeHistory": [...],
  "totalValue": 10000.0,
  "totalPnL": 0.0,
  "dayChange": 0.0,
  "dayChangePercent": 0.0,
  "dayStartValue": 10000.0,        // NEW
  "dayStartDate": "2024-01-01T00:00:00Z",  // NEW
  "lastUpdated": "...",
  "lastPriceUpdate": "..."          // NEW
}
```

## 🔄 How It Works

1. **On App Start:**
   - Loads portfolio from database
   - Checks if it's a new day → resets day start value if needed
   - Fetches fresh prices if positions exist and last update > 5 min ago
   - Starts periodic update timer

2. **During Trading:**
   - After each trade, updates portfolio with cached prices (saves API calls)
   - Calculates P&L for affected positions
   - Updates day change

3. **Periodic Updates:**
   - Every 5 minutes, fetches fresh prices for all positions
   - Updates portfolio value and P&L
   - Recalculates day change

4. **App Lifecycle:**
   - When app comes to foreground, refreshes prices
   - Home screen refreshes when displayed

## 🎯 Key Features

✅ **Real-time P&L tracking** - Shows profit/loss for each position and total portfolio  
✅ **Day change tracking** - Shows how much portfolio changed today  
✅ **Automatic price updates** - Fetches fresh prices periodically  
✅ **Smart caching** - Uses cached prices when appropriate to save API calls  
✅ **New day detection** - Automatically resets day start value at midnight  

## 📝 Files Modified

1. `lib/services/paper_trading_service.dart`
   - Added day start value tracking
   - Added periodic price updates
   - Added day change calculation
   - Added app lifecycle support

2. `lib/screens/home_screen.dart`
   - Added app lifecycle observer
   - Added portfolio refresh on resume

## 🚀 Testing Checklist

- [ ] Buy a stock → verify position appears with correct P&L
- [ ] Wait for prices to update → verify portfolio value changes
- [ ] Check day change → verify it shows correct change from day start
- [ ] Close and reopen app → verify prices refresh
- [ ] Wait 5+ minutes → verify periodic update triggers
- [ ] Check home screen portfolio card → verify shows correct values

## 💡 Notes

- Periodic updates only run when positions exist (saves API calls)
- Fresh prices are fetched max once per 5 minutes to avoid exhausting API credits
- Day start value resets automatically at midnight (local time)
- All P&L calculations are real-time based on current market prices


