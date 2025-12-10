# 🇮🇳 Indian Stocks Currency Fix

## The Problem
When buying/selling Indian stocks, the system wasn't handling currency conversion properly:
- Indian stocks are priced in **INR (₹)**
- Portfolio cash balance is in **USD ($)**
- Without conversion, buying ₹1000 worth of Indian stock would incorrectly deduct $1000 from cash balance

## The Solution

### 1. Created Currency Converter Utility
- **File**: `lib/utils/currency_converter.dart`
- Fetches real-time USD/INR exchange rate from free API
- Caches rate for 1 hour to reduce API calls
- Fallback rate (83.0) if API fails

### 2. Updated Trade Execution
- **File**: `lib/services/paper_trading_service.dart`
- `placeTrade()` now:
  - Detects if stock is Indian (by symbol suffix `.NS`/`.BO` or currency)
  - Converts INR price to USD when calculating trade cost
  - Deducts/adds correct USD amount to cash balance
  - Stores original price in native currency

### 3. Updated Portfolio Value Calculation
- `_updatePortfolio()` now:
  - Converts Indian stock values from INR to USD
  - Calculates total portfolio value in USD
  - Handles currency conversion for auto-sell triggers

## How It Works

### Buying Indian Stocks
1. User buys 10 shares of RELIANCE.NS at ₹2,500/share
2. Total cost in INR: ₹25,000
3. System converts to USD: ₹25,000 ÷ 83 = ~$301.20
4. Deducts $301.20 from USD cash balance
5. Position stored with original INR price

### Selling Indian Stocks
1. User sells 10 shares of RELIANCE.NS at ₹2,600/share
2. Total proceeds in INR: ₹26,000
3. System converts to USD: ₹26,000 ÷ 83 = ~$313.25
4. Adds $313.25 to USD cash balance

### Portfolio Value
- All positions converted to USD for total portfolio value
- Individual positions show prices in their native currency
- Cash balance always in USD

## Exchange Rate
- **Source**: exchangerate-api.com (free, no key required)
- **Cache**: 1 hour TTL
- **Fallback**: 83.0 USD/INR if API fails
- Updates automatically when cache expires

## Testing

### Test Buy Indian Stock
1. Search for "RELIANCE" or "TCS"
2. Buy some shares
3. Check console logs - should show:
   ```
   💰 Indian stock trade: ₹25000.00 = $301.20
   💵 Cash balance after buy: $9698.80
   ```

### Test Sell Indian Stock
1. Sell Indian stock position
2. Check console logs - should show:
   ```
   💰 Indian stock trade: ₹26000.00 = $313.25
   💵 Cash balance after sell: $10012.05
   ```

### Test Portfolio Value
1. Have both US and Indian stocks
2. Portfolio total should be in USD
3. Individual positions show native currency prices

## Important Notes

1. **Cash Balance**: Always in USD, regardless of stock currencies
2. **Position Prices**: Stored in native currency (INR for Indian, USD for US)
3. **Portfolio Total**: Converted to USD for unified view
4. **Exchange Rate**: Updates hourly automatically
5. **Offline**: Uses cached rate or fallback if API unavailable

## Files Modified

1. **lib/utils/currency_converter.dart** (NEW)
   - Currency conversion utility
   - Exchange rate fetching and caching

2. **lib/services/paper_trading_service.dart**
   - Updated `placeTrade()` for currency conversion
   - Updated `_updatePortfolio()` for portfolio value calculation
   - Updated auto-sell logic for currency conversion

## Future Enhancements

- [ ] Support for multiple currencies (EUR, GBP, etc.)
- [ ] Separate cash balances per currency
- [ ] Historical exchange rates for accurate P&L
- [ ] Currency conversion fees simulation

