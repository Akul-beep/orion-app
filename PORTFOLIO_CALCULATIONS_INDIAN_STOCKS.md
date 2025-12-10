# 📊 Portfolio Calculations for Indian Stocks - Verification

## Overview
The portfolio calculations **already correctly handle Indian stocks** by converting INR values to USD for portfolio totals. This document explains how it works.

## How Portfolio Calculations Work

### 1. **Individual Position Values**
- **Stored in Native Currency**: Each position stores its value in its native currency
  - Indian stocks (RELIANCE.NS): Stored in **INR (₹)**
  - US stocks (AAPL): Stored in **USD ($)**
- **Display**: Shows in native currency (₹ for Indian, $ for US)

### 2. **Portfolio Total Value**
- **Always in USD**: Portfolio total is always calculated and displayed in **USD ($)**
- **Conversion**: Indian stock values are converted to USD when calculating portfolio total
- **Formula**: `Total Value = Cash Balance (USD) + Sum of all Position Values (converted to USD)`

### 3. **Portfolio P&L (Profit & Loss)**
- **Always in USD**: Total P&L is calculated in **USD ($)**
- **Conversion**: Indian stock P&L is converted to USD
- **Formula**: `Total P&L = Sum of all Position P&L (converted to USD)`

## Calculation Flow

### When Portfolio Updates (`_updatePortfolio()`)

1. **For Each Position**:
   ```
   Indian Stock (RELIANCE.NS):
   - Current Price: ₹2,500 (native currency)
   - Quantity: 10 shares
   - Current Value (Native): ₹25,000
   - Convert to USD: ₹25,000 ÷ 83 = $301.20
   - Add $301.20 to portfolio total
   
   US Stock (AAPL):
   - Current Price: $150 (native currency)
   - Quantity: 5 shares
   - Current Value (Native): $750
   - Already in USD, add $750 to portfolio total
   ```

2. **Portfolio Total**:
   ```
   Total Value = Cash Balance ($10,000) + Indian Positions ($301.20) + US Positions ($750)
   Total Value = $11,051.20
   ```

3. **Portfolio P&L**:
   ```
   Indian Stock P&L: ₹2,000 profit → Convert to USD: $24.10
   US Stock P&L: $50 profit
   Total P&L = $24.10 + $50 = $74.10
   ```

### When Using Cached Prices (`calculatePortfolioValue()`)

- Uses **fallback exchange rate** (83.0) for quick calculations
- More accurate rate is used when `_updatePortfolio()` runs with fresh quotes
- This is for performance - avoids API calls when just recalculating

## Code Verification

### ✅ `_updatePortfolio()` Function
**File**: `lib/services/paper_trading_service.dart` (lines 448-657)

```dart
// For Indian stocks
if (isIndian && CurrencyConverter.isInr(currency)) {
  currentValueUsd = await CurrencyConverter.inrToUsd(currentValueNative);
  unrealizedPnLUsd = await CurrencyConverter.inrToUsd(unrealizedPnLNative);
}

// Add USD value to portfolio total
totalPositionValue += currentValueUsd;
totalUnrealizedPnL += unrealizedPnLUsd;
```

### ✅ `calculatePortfolioValue()` Function
**File**: `lib/services/paper_trading_service.dart` (lines 669-697)

```dart
if (isIndian) {
  // Convert INR to USD using fallback rate
  totalPositionValue += position.currentValue / fallbackUsdToInrRate;
  totalUnrealizedPnL += position.unrealizedPnL / fallbackUsdToInrRate;
}
```

## Display in UI

### Portfolio Summary Card
- **Total Value**: Shows in **USD ($)** ✅
- **Total P&L**: Shows in **USD ($)** ✅
- **Cash Balance**: Shows in **USD ($)** ✅

### Individual Positions
- **Current Price**: Shows in **native currency** (₹ for Indian, $ for US) ✅
- **Current Value**: Shows in **native currency** ✅
- **P&L**: Shows in **native currency** ✅

## Example Scenario

### Portfolio with Mixed Stocks

**Positions**:
1. RELIANCE.NS: 10 shares @ ₹2,500 = ₹25,000
2. AAPL: 5 shares @ $150 = $750

**Calculations**:
```
Indian Stock (RELIANCE.NS):
- Value in INR: ₹25,000
- Convert to USD: ₹25,000 ÷ 83 = $301.20

US Stock (AAPL):
- Value in USD: $750

Portfolio Total:
- Cash: $10,000
- Positions: $301.20 + $750 = $1,051.20
- Total: $11,051.20
```

**Display**:
- Portfolio Total: **$11,051.20** (USD)
- RELIANCE.NS: **₹25,000** (INR)
- AAPL: **$750** (USD)

## Logging

Added detailed logging to verify calculations:
```
📊 ========== PORTFOLIO UPDATE ==========
   Cash Balance: $10000.00
   Total Position Value (USD): $1051.20
   Total Portfolio Value: $11051.20
   Total P&L: $74.10 (0.74%)
   Positions: 2
     - RELIANCE.NS: 10 shares @ ₹2500.00 = ₹25000.00
     - AAPL: 5 shares @ $150.00 = $750.00
=========================================
```

## Summary

✅ **Portfolio calculations correctly handle Indian stocks**
- Individual positions show values in native currency (₹ for Indian, $ for US)
- Portfolio totals are always in USD (converted from INR for Indian stocks)
- P&L calculations correctly convert INR to USD
- Exchange rate conversion happens automatically

✅ **Display is correct**
- Portfolio summary shows USD totals
- Individual positions show native currency
- All calculations are accurate

The portfolio system is working correctly for Indian stocks! 🎉

