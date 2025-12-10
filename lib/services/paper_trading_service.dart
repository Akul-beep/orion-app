import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/paper_trade.dart';
import '../models/stock_quote.dart';
import 'stock_api_service.dart';
import 'database_service.dart';
import 'daily_goals_service.dart';
import 'gamification_service.dart';
import 'weekly_challenge_service.dart';
import 'monthly_challenge_service.dart';
import 'friend_quest_service.dart';
import '../utils/market_detector.dart';
import '../utils/currency_converter.dart';

class PaperTradingService extends ChangeNotifier {
  static const double _initialBalance = 10000.0; // $10,000 starting balance
  
  double _cashBalance = _initialBalance;
  List<PaperPosition> _positions = [];
  List<PaperTrade> _tradeHistory = [];
  double _totalValue = _initialBalance;
  double _totalPnL = 0.0;
  double _dayChange = 0.0;
  double _dayChangePercent = 0.0;
  double _dayStartValue = _initialBalance; // Portfolio value at start of day
  DateTime _lastUpdated = DateTime.now();
  DateTime? _lastPriceUpdate; // Track when we last fetched prices from API
  DateTime? _dayStartDate; // Date when day start value was set
  Timer? _priceUpdateTimer; // Timer for periodic price updates

  // Getters
  double get cashBalance => _cashBalance;
  List<PaperPosition> get positions => _positions;
  List<PaperTrade> get tradeHistory => _tradeHistory;
  List<PaperTrade> get recentTrades => _tradeHistory.take(10).toList();
  double get totalValue => _totalValue;
  double get totalPnL => _totalPnL;
  double get totalPnLPercent => _totalPnL / _initialBalance * 100;
  double get dayChange => _dayChange;
  double get dayChangePercent => _dayChangePercent;
  DateTime get lastUpdated => _lastUpdated;
  double get investedValue => _totalValue - _cashBalance;

  PaperPortfolio get portfolio => PaperPortfolio(
    totalValue: _totalValue,
    cashBalance: _cashBalance,
    investedValue: investedValue,
    totalPnL: _totalPnL,
    totalPnLPercent: totalPnLPercent,
    positions: _positions,
    recentTrades: _tradeHistory.take(10).toList(),
    lastUpdated: _lastUpdated,
    dayChange: _dayChange,
    dayChangePercent: _dayChangePercent,
  );

  // Initialize portfolio
  void initializePortfolio() {
    _cashBalance = _initialBalance;
    _positions.clear();
    _tradeHistory.clear();
    _totalValue = _initialBalance;
    _totalPnL = 0.0;
    _dayChange = 0.0;
    _dayChangePercent = 0.0;
    _dayStartValue = _initialBalance;
    _dayStartDate = DateTime.now();
    _lastUpdated = DateTime.now();
    _savePortfolioToDatabase();
    notifyListeners();
  }
  
  // Check if it's a new day and reset day start value if needed
  void _checkAndResetDayStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_dayStartDate == null) {
      // First time, set day start
      _dayStartValue = _totalValue;
      _dayStartDate = today;
    } else {
      final lastDayStart = DateTime(_dayStartDate!.year, _dayStartDate!.month, _dayStartDate!.day);
      if (!today.isAtSameMomentAs(lastDayStart)) {
        // New day - reset day start value
        _dayStartValue = _totalValue;
        _dayStartDate = today;
        _dayChange = 0.0;
        _dayChangePercent = 0.0;
        print('📅 New day detected - resetting day start value to \$${_dayStartValue.toStringAsFixed(2)}');
      }
    }
  }
  
  // Load portfolio from database
  Future<void> loadPortfolioFromDatabase() async {
    print('📥 ========== LOAD PORTFOLIO FROM DATABASE ==========');
    try {
      final data = await DatabaseService.loadPortfolio();
      if (data != null) {
        print('✅ Portfolio data found, loading...');
        fromJson(data);
        
        print('   Loaded positions: ${_positions.length}');
        print('   Cash balance: \$${_cashBalance.toStringAsFixed(2)}');
        print('   Total value: \$${_totalValue.toStringAsFixed(2)}');
        
        // Also load trade history
        try {
          final trades = await DatabaseService.loadTradeHistory();
          _tradeHistory = trades.map((t) => PaperTrade.fromJson(t)).toList();
          print('   Loaded trade history: ${_tradeHistory.length} trades');
        } catch (e) {
          print('⚠️ Error loading trade history: $e');
        }
        
        // Check if it's a new day and reset day start if needed
        _checkAndResetDayStart();
        
        // Refresh portfolio with fresh prices (but limit API calls aggressively)
        // Only fetch fresh prices if we have positions and haven't updated recently (15 min threshold)
        if (_positions.isNotEmpty) {
          final shouldFetchFresh = _lastPriceUpdate == null || 
              DateTime.now().difference(_lastPriceUpdate!).inMinutes > 15;
          
          if (shouldFetchFresh) {
            print('🔄 Loading portfolio - fetching fresh prices (last update > 15 min ago)...');
            await _updatePortfolio(useCachedPrices: false);
          } else {
            print('💰 Loading portfolio - using cached prices (saving API credits)');
            await calculatePortfolioValue();
          }
        } else {
          // No positions, just calculate with current values
          print('💰 No positions, calculating portfolio value...');
          await calculatePortfolioValue();
        }
        
        // Start periodic price updates if we have positions
        _startPeriodicPriceUpdates();
        
        notifyListeners();
        print('✅ Portfolio loaded successfully');
      } else {
        // No portfolio data - initialize fresh
        print('⚠️ No portfolio data found, initializing fresh portfolio');
        initializePortfolio();
      }
    } catch (e, stackTrace) {
      print('❌ Error loading portfolio: $e');
      print('Stack trace: $stackTrace');
      // Try to initialize fresh portfolio on error
      try {
        print('   Attempting to initialize fresh portfolio...');
        initializePortfolio();
      } catch (initError) {
        print('❌ Error initializing portfolio: $initError');
      }
    }
    print('📥 ========== LOAD COMPLETE ==========');
  }
  
  // Start periodic price updates (every 30 minutes to save API credits)
  void _startPeriodicPriceUpdates() {
    _stopPeriodicPriceUpdates(); // Stop any existing timer
    
    if (_positions.isEmpty) {
      return; // No positions to update
    }
    
    // Only update every 30 minutes to conserve API credits (60/day limit)
    _priceUpdateTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (_positions.isNotEmpty) {
        print('⏰ Periodic portfolio update triggered (30 min interval)');
        _updatePortfolio(useCachedPrices: false).catchError((e) {
          print('⚠️ Error in periodic portfolio update: $e');
        });
      } else {
        _stopPeriodicPriceUpdates();
      }
    });
    
    print('🔄 Started periodic portfolio price updates (every 30 minutes to save API credits)');
  }
  
  // Stop periodic price updates
  void _stopPeriodicPriceUpdates() {
    _priceUpdateTimer?.cancel();
    _priceUpdateTimer = null;
  }
  
  // Call this when app comes to foreground to refresh prices (only if needed)
  Future<void> onAppResumed() async {
    if (_positions.isEmpty) {
      return; // No positions to update
    }
    
    // Only refresh if last update was more than 10 minutes ago (save API credits)
    final shouldRefresh = _lastPriceUpdate == null || 
        DateTime.now().difference(_lastPriceUpdate!).inMinutes > 10;
    
    if (shouldRefresh) {
      print('📱 App resumed - refreshing portfolio prices (last update > 10 min ago)...');
      await _updatePortfolio(useCachedPrices: false);
    } else {
      print('💰 App resumed - using cached prices (saving API credits)');
      await calculatePortfolioValue();
    }
  }
  
  // Update day change based on day start value
  void _updateDayChange() {
    _dayChange = _totalValue - _dayStartValue;
    if (_dayStartValue > 0) {
      _dayChangePercent = (_dayChange / _dayStartValue) * 100;
    } else {
      _dayChangePercent = 0.0;
    }
  }
  
  // Save portfolio to database
  Future<void> _savePortfolioToDatabase() async {
    try {
      await DatabaseService.savePortfolio(toJson());
    } catch (e) {
      print('Error saving portfolio: $e');
    }
  }

  // Place a paper trade
  Future<bool> placeTrade({
    required String symbol,
    required String action,
    required int quantity,
    double? stopLoss,
    double? takeProfit,
    String? notes,
  }) async {
    try {
      // Get current stock price
      final quote = await StockApiService.getQuote(symbol);
      final price = quote.currentPrice;
      final currency = quote.currency;
      
      // Check if this is an Indian stock
      final isIndian = MarketDetector.isIndianStock(symbol) || CurrencyConverter.isInr(currency);
      
      // Calculate total cost in stock's native currency
      double totalCostNative = price * quantity;
      
      // Convert to USD for portfolio cash balance
      double totalCostUsd;
      if (isIndian && CurrencyConverter.isInr(currency)) {
        // Indian stock - convert INR to USD
        totalCostUsd = await CurrencyConverter.inrToUsd(totalCostNative);
        print('💰 Indian stock trade: ₹${totalCostNative.toStringAsFixed(2)} = \$${totalCostUsd.toStringAsFixed(2)}');
      } else {
        // US stock - already in USD
        totalCostUsd = totalCostNative;
      }

      // Check if we have enough cash for buy orders (in USD)
      if (action == 'buy' && totalCostUsd > _cashBalance) {
        print('❌ Insufficient funds: Need \$${totalCostUsd.toStringAsFixed(2)}, have \$${_cashBalance.toStringAsFixed(2)}');
        return false; // Insufficient funds
      }

      // Check if we have enough shares for sell orders
      if (action == 'sell') {
        final position = _positions.firstWhere(
          (p) => p.symbol == symbol,
          orElse: () => PaperPosition(
            symbol: symbol,
            quantity: 0,
            averagePrice: 0,
            currentPrice: 0,
            firstBought: DateTime.now(),
            lastUpdated: DateTime.now(),
            unrealizedPnL: 0,
            unrealizedPnLPercent: 0,
            totalInvested: 0,
            currentValue: 0,
          ),
        );
        
        if (position.quantity < quantity) {
          return false; // Insufficient shares
        }
      }

      // Create trade
      final trade = PaperTrade(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: symbol,
        action: action,
        price: price,
        quantity: quantity,
        timestamp: DateTime.now(),
        status: 'filled',
        stopLoss: stopLoss,
        takeProfit: takeProfit,
        notes: notes,
      );

      // Execute trade
      if (action == 'buy') {
        // Deduct USD from cash balance (converted if Indian stock)
        _cashBalance -= totalCostUsd;
        print('💵 Cash balance after buy: \$${_cashBalance.toStringAsFixed(2)}');
        _updatePosition(symbol, quantity, price, true, stopLoss: stopLoss, takeProfit: takeProfit, currency: currency);
      } else {
        // Add USD to cash balance (converted if Indian stock)
        _cashBalance += totalCostUsd;
        print('💵 Cash balance after sell: \$${_cashBalance.toStringAsFixed(2)}');
        _updatePosition(symbol, quantity, price, false, currency: currency);
      }

      // Add to trade history
      _tradeHistory.insert(0, trade);
      
      // Save trade to database
      await DatabaseService.saveTrade(trade);
      
      // Track trade in daily goals
      try {
        DailyGoalsService().trackTrade();
      } catch (e) {
        print('Error tracking trade in daily goals: $e');
      }
      
      // Track for weekly challenges
      try {
        final challengeService = WeeklyChallengeService();
        challengeService.trackProgress('trade', 1);
        
        // Track stop-loss if set
        if (stopLoss != null) {
          challengeService.trackProgress('stop_loss', 1);
          print('🛡️ Stop-loss set - tracking for Risk Manager Challenge');
        }
        
        // Track take-profit if set
        if (takeProfit != null) {
          challengeService.trackProgress('take_profit', 1);
          print('🎯 Take-profit set - tracking for Profit Target Challenge');
        }
      } catch (e) {
        print('⚠️ Error tracking trade in weekly challenge: $e');
      }
      
      // Track for monthly challenges
      try {
        MonthlyChallengeService().trackProgress('trade', 1);
      } catch (e) {
        print('⚠️ Error tracking trade in monthly challenge: $e');
      }
      
      // Track for friend quests
      try {
        FriendQuestService().trackProgress('trade', 1);
      } catch (e) {
        print('⚠️ Error tracking trade in friend quest: $e');
      }
      
      // Update gamification immediately - track trade and award XP
      try {
        final gamification = GamificationService.instance;
        if (gamification != null) {
          gamification.trackTrade();
          
          // Award XP for trading - scales with user level
          // Base: 25 XP, +5 XP per level (capped at 100 XP per trade)
          final userLevel = gamification.level;
          final tradeXP = (25 + (userLevel * 5)).clamp(25, 100);
          
          if (gamification.canEarnXP('trading', tradeXP)) {
            gamification.addXP(tradeXP, 'trading');
            print('✅ Awarded $tradeXP XP for trade: ${trade.symbol} ${trade.action} (Level ${userLevel})');
          } else {
            print('⚠️ Daily trading XP cap reached, no XP awarded');
          }
        } else {
          print('⚠️ GamificationService not initialized yet');
        }
      } catch (e) {
        print('Error updating gamification for trade: $e');
      }
      
      // Update portfolio using cached prices (don't fetch new prices after every trade)
      await _updatePortfolio(useCachedPrices: true);
      
      // Restart periodic updates if we now have positions
      if (_positions.isNotEmpty) {
        _startPeriodicPriceUpdates();
      }
      
      // Save portfolio to database
      await _savePortfolioToDatabase();
      
      // Update leaderboard with new portfolio value (pass current totalValue)
      try {
        print('💰 Updating leaderboard with portfolio value: \$${_totalValue.toStringAsFixed(2)}');
        final gamification = GamificationService.instance;
        if (gamification != null) {
          await gamification.updateLeaderboard(portfolioValue: _totalValue);
        }
      } catch (e) {
        print('⚠️ Error updating leaderboard after trade: $e');
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error placing trade: $e');
      return false;
    }
  }

  // Update position after trade
  void _updatePosition(String symbol, int quantity, double price, bool isBuy, {double? stopLoss, double? takeProfit, String? currency}) {
    final existingIndex = _positions.indexWhere((p) => p.symbol == symbol);
    
    if (existingIndex != -1) {
      final existing = _positions[existingIndex];
      if (isBuy) {
        // Add to position
        final newQuantity = existing.quantity + quantity;
        final newAveragePrice = ((existing.averagePrice * existing.quantity) + (price * quantity)) / newQuantity;
        
        // Use new stop loss/take profit if provided, otherwise keep existing ones
        final finalStopLoss = stopLoss ?? existing.stopLoss;
        final finalTakeProfit = takeProfit ?? existing.takeProfit;
        
        _positions[existingIndex] = PaperPosition(
          symbol: symbol,
          quantity: newQuantity,
          averagePrice: newAveragePrice,
          currentPrice: price,
          firstBought: existing.firstBought,
          lastUpdated: DateTime.now(),
          unrealizedPnL: (price - newAveragePrice) * newQuantity,
          unrealizedPnLPercent: ((price - newAveragePrice) / newAveragePrice) * 100,
          totalInvested: newAveragePrice * newQuantity,
          currentValue: price * newQuantity,
          stopLoss: finalStopLoss,
          takeProfit: finalTakeProfit,
        );
      } else {
        // Remove from position
        final newQuantity = existing.quantity - quantity;
        if (newQuantity <= 0) {
          _positions.removeAt(existingIndex);
        } else {
          _positions[existingIndex] = PaperPosition(
            symbol: symbol,
            quantity: newQuantity,
            averagePrice: existing.averagePrice,
            currentPrice: price,
            firstBought: existing.firstBought,
            lastUpdated: DateTime.now(),
            unrealizedPnL: (price - existing.averagePrice) * newQuantity,
            unrealizedPnLPercent: ((price - existing.averagePrice) / existing.averagePrice) * 100,
            totalInvested: existing.averagePrice * newQuantity,
            currentValue: price * newQuantity,
            stopLoss: existing.stopLoss,
            takeProfit: existing.takeProfit,
          );
        }
      }
    } else if (isBuy) {
      // Create new position
      _positions.add(PaperPosition(
        symbol: symbol,
        quantity: quantity,
        averagePrice: price,
        currentPrice: price,
        firstBought: DateTime.now(),
        lastUpdated: DateTime.now(),
        unrealizedPnL: 0,
        unrealizedPnLPercent: 0,
        totalInvested: price * quantity,
        currentValue: price * quantity,
        stopLoss: stopLoss,
        takeProfit: takeProfit,
      ));
    }
  }

  // Update portfolio values
  // useCachedPrices: if true, uses existing prices from positions (saves API calls)
  // if false, fetches fresh prices from API (use sparingly to avoid exhausting credits)
  Future<void> _updatePortfolio({bool useCachedPrices = false}) async {
    double totalPositionValue = 0.0;
    double totalUnrealizedPnL = 0.0;

    // Update positions with current prices and check stop loss/take profit
    for (int i = 0; i < _positions.length; i++) {
      try {
        final position = _positions[i];
        double currentPrice;
        String? currency;
        final isIndian = MarketDetector.isIndianStock(position.symbol);
        StockQuote? quote;
        
        if (useCachedPrices && position.currentPrice > 0) {
          // For Indian stocks, always try to get fresh price to ensure portfolio updates correctly
          // For US stocks, use cached price to save API calls
          if (isIndian) {
            try {
              print('🔄 Fetching fresh price for Indian stock ${position.symbol}...');
              quote = await StockApiService.getQuote(position.symbol);
              currentPrice = quote.currentPrice;
              currency = quote.currency;
              print('✅ Updated ${position.symbol} to ₹${currentPrice.toStringAsFixed(2)}');
            } catch (e) {
              // Fallback to cached price if API fails
              currentPrice = position.currentPrice;
              currency = 'INR';
              print('💰 Using cached price for ${position.symbol}: ₹${currentPrice.toStringAsFixed(2)}');
            }
          } else {
            // US stock - use cached price
            currentPrice = position.currentPrice;
            currency = 'USD';
            print('💰 Using cached price for ${position.symbol}: \$${currentPrice.toStringAsFixed(2)}');
          }
        } else {
          // Fetch fresh price from API (only when explicitly requested)
          try {
            print('🔄 Fetching fresh price for ${position.symbol}...');
            quote = await StockApiService.getQuote(position.symbol);
            currentPrice = quote.currentPrice;
            currency = quote.currency;
            final currencySymbol = isIndian ? '₹' : '\$';
            print('✅ Updated ${position.symbol} to $currencySymbol${currentPrice.toStringAsFixed(2)}');
          } catch (e) {
            print('⚠️ API error for ${position.symbol}, using cached/mock price: $e');
            // Fallback to cached price or mock price
            currentPrice = position.currentPrice > 0 
                ? position.currentPrice 
                : _getMockPrice(position.symbol);
            currency = isIndian ? 'INR' : 'USD';
          }
        }
        
        // Check stop loss and take profit triggers (only with fresh prices)
        // Don't check triggers with cached prices as they may be stale
        bool shouldSell = false;
        String? sellReason;
        
        if (!useCachedPrices) {
          // Only check stop loss/take profit when we have fresh prices
          if (position.stopLoss != null && currentPrice <= position.stopLoss!) {
            shouldSell = true;
            sellReason = 'Stop Loss triggered at \$${position.stopLoss!.toStringAsFixed(2)}';
          } else if (position.takeProfit != null && currentPrice >= position.takeProfit!) {
            shouldSell = true;
            sellReason = 'Take Profit triggered at \$${position.takeProfit!.toStringAsFixed(2)}';
          }
        }
        
        // Execute automatic sell if triggered
        if (shouldSell && position.quantity > 0) {
          print('🚨 Auto-executing sell for ${position.symbol}: $sellReason');
          
          // Get quote to check currency
          try {
            final quote = await StockApiService.getQuote(position.symbol);
            final isIndian = MarketDetector.isIndianStock(position.symbol) || CurrencyConverter.isInr(quote.currency);
            final positionValueNative = currentPrice * position.quantity;
            final positionValueUsd = isIndian && CurrencyConverter.isInr(quote.currency)
                ? await CurrencyConverter.inrToUsd(positionValueNative)
                : positionValueNative;
            
            final sellTrade = PaperTrade(
              id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
              symbol: position.symbol,
              action: 'sell',
              price: currentPrice,
              quantity: position.quantity,
              timestamp: DateTime.now(),
              status: 'filled',
              notes: sellReason,
            );
            
            // Execute the sell - add USD to cash balance
            _cashBalance += positionValueUsd;
            _positions.removeAt(i);
            i--; // Adjust index after removal
            
            // Add to trade history
            _tradeHistory.insert(0, sellTrade);
            await DatabaseService.saveTrade(sellTrade);
            
            print('✅ Auto-sold ${position.symbol} at ${isIndian ? "₹" : "\$"}${currentPrice.toStringAsFixed(2)} (Value: \$${positionValueUsd.toStringAsFixed(2)})');
            continue; // Skip position update since we sold it
          } catch (e) {
            print('⚠️ Error getting quote for auto-sell: $e');
            // Fallback: assume USD
            final sellTrade = PaperTrade(
              id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
              symbol: position.symbol,
              action: 'sell',
              price: currentPrice,
              quantity: position.quantity,
              timestamp: DateTime.now(),
              status: 'filled',
              notes: sellReason,
            );
            
            _cashBalance += currentPrice * position.quantity;
            _positions.removeAt(i);
            i--;
            _tradeHistory.insert(0, sellTrade);
            await DatabaseService.saveTrade(sellTrade);
            continue;
          }
        }
        
        // Currency already determined above from quote fetch
        
        final currentValueNative = currentPrice * position.quantity;
        final unrealizedPnLNative = (currentPrice - position.averagePrice) * position.quantity;
        final unrealizedPnLPercent = ((currentPrice - position.averagePrice) / position.averagePrice) * 100;

        // Convert to USD for portfolio calculations if Indian stock
        double currentValueUsd;
        double unrealizedPnLUsd;
        if (isIndian && CurrencyConverter.isInr(currency)) {
          currentValueUsd = await CurrencyConverter.inrToUsd(currentValueNative);
          unrealizedPnLUsd = await CurrencyConverter.inrToUsd(unrealizedPnLNative);
        } else {
          currentValueUsd = currentValueNative;
          unrealizedPnLUsd = unrealizedPnLNative;
        }

        _positions[i] = PaperPosition(
          symbol: position.symbol,
          quantity: position.quantity,
          averagePrice: position.averagePrice,
          currentPrice: currentPrice,
          firstBought: position.firstBought,
          lastUpdated: DateTime.now(),
          unrealizedPnL: unrealizedPnLNative, // Store in native currency
          unrealizedPnLPercent: unrealizedPnLPercent,
          totalInvested: position.averagePrice * position.quantity,
          currentValue: currentValueNative, // Store in native currency
          stopLoss: position.stopLoss,
          takeProfit: position.takeProfit,
        );

        // Add USD value to portfolio total
        totalPositionValue += currentValueUsd;
        totalUnrealizedPnL += unrealizedPnLUsd;
      } catch (e) {
        print('Error updating position ${_positions[i].symbol}: $e');
        // Use mock price if API fails
        final position = _positions[i];
        final mockPrice = _getMockPrice(position.symbol);
        final currentValueNative = mockPrice * position.quantity;
        final unrealizedPnLNative = (mockPrice - position.averagePrice) * position.quantity;
        final unrealizedPnLPercent = ((mockPrice - position.averagePrice) / position.averagePrice) * 100;

        // Check if Indian stock and convert to USD
        final isIndian = MarketDetector.isIndianStock(position.symbol);
        double currentValueUsd;
        double unrealizedPnLUsd;
        if (isIndian) {
          // Use approximate rate for error case
          const double approximateRate = 83.0;
          currentValueUsd = currentValueNative / approximateRate;
          unrealizedPnLUsd = unrealizedPnLNative / approximateRate;
        } else {
          currentValueUsd = currentValueNative;
          unrealizedPnLUsd = unrealizedPnLNative;
        }

        _positions[i] = PaperPosition(
          symbol: position.symbol,
          quantity: position.quantity,
          averagePrice: position.averagePrice,
          currentPrice: mockPrice,
          firstBought: position.firstBought,
          lastUpdated: DateTime.now(),
          unrealizedPnL: unrealizedPnLNative,
          unrealizedPnLPercent: unrealizedPnLPercent,
          totalInvested: position.averagePrice * position.quantity,
          currentValue: currentValueNative,
          stopLoss: position.stopLoss,
          takeProfit: position.takeProfit,
        );

        totalPositionValue += currentValueUsd;
        totalUnrealizedPnL += unrealizedPnLUsd;
      }
    }

    _totalValue = _cashBalance + totalPositionValue;
    _totalPnL = totalUnrealizedPnL;
    _lastUpdated = DateTime.now();
    if (!useCachedPrices) {
      _lastPriceUpdate = DateTime.now();
    }
    
    // Log portfolio calculation summary (for debugging Indian stock conversions)
    print('📊 ========== PORTFOLIO UPDATE ==========');
    print('   Cash Balance: \$${_cashBalance.toStringAsFixed(2)}');
    print('   Total Position Value (USD): \$${totalPositionValue.toStringAsFixed(2)}');
    print('   Total Portfolio Value: \$${_totalValue.toStringAsFixed(2)}');
    print('   Total P&L: \$${_totalPnL.toStringAsFixed(2)} (${totalPnLPercent.toStringAsFixed(2)}%)');
    print('   Positions: ${_positions.length}');
    for (final pos in _positions) {
      final isIndian = MarketDetector.isIndianStock(pos.symbol);
      final currency = isIndian ? '₹' : '\$';
      print('     - ${pos.symbol}: ${pos.quantity} shares @ $currency${pos.currentPrice.toStringAsFixed(2)} = $currency${pos.currentValue.toStringAsFixed(2)}');
    }
    print('=========================================');
    
    // Check if it's a new day and reset day start if needed
    _checkAndResetDayStart();
    
    // Update day change based on day start value
    _updateDayChange();
    
    // Save updated portfolio to database
    await _savePortfolioToDatabase();
    notifyListeners();
  }
  
  // Public method to manually refresh portfolio with fresh prices from API
  // Use this sparingly (e.g., on pull-to-refresh) to avoid exhausting API credits
  Future<void> refreshPortfolioPrices() async {
    print('🔄 Manual portfolio refresh requested - fetching fresh prices...');
    await _updatePortfolio(useCachedPrices: false);
  }
  
  // Calculate portfolio value using cached prices (no API calls)
  // Note: For Indian stocks, uses cached exchange rate or fallback
  // For accurate conversion with fresh quotes, use _updatePortfolio()
  Future<void> calculatePortfolioValue() async {
    double totalPositionValue = 0.0;
    double totalUnrealizedPnL = 0.0;
    
    // Use cached exchange rate for Indian stocks (or fallback)
    // Try to get cached rate, otherwise use fallback
    double usdToInrRate = 83.0; // Fallback rate
    try {
      // Try to get cached rate synchronously (it's cached, so should be fast)
      usdToInrRate = await CurrencyConverter.getUsdToInrRate();
    } catch (e) {
      print('⚠️ Using fallback exchange rate for portfolio calculation: $e');
    }
    
    for (final position in _positions) {
      final isIndian = MarketDetector.isIndianStock(position.symbol);
      
      if (isIndian) {
        // Convert INR to USD using cached rate
        // Note: This uses cached position values which are in native currency (INR)
        final valueUsd = position.currentValue / usdToInrRate;
        final pnlUsd = position.unrealizedPnL / usdToInrRate;
        totalPositionValue += valueUsd;
        totalUnrealizedPnL += pnlUsd;
        print('💰 Portfolio calc: ${position.symbol} - ₹${position.currentValue.toStringAsFixed(2)} = \$${valueUsd.toStringAsFixed(2)} (rate: $usdToInrRate)');
      } else {
        // US stock - already in USD
        totalPositionValue += position.currentValue;
        totalUnrealizedPnL += position.unrealizedPnL;
      }
    }
    
    _totalValue = _cashBalance + totalPositionValue;
    _totalPnL = totalUnrealizedPnL;
    
    print('📊 Portfolio Total: \$${_totalValue.toStringAsFixed(2)} (Cash: \$${_cashBalance.toStringAsFixed(2)} + Positions: \$${totalPositionValue.toStringAsFixed(2)})');
    print('📊 Portfolio P&L: \$${_totalPnL.toStringAsFixed(2)}');
    
    // Update day change
    _updateDayChange();
    
    // Save portfolio to database
    await _savePortfolioToDatabase();
    
    // Update leaderboard with new portfolio value (pass current totalValue)
    try {
      print('💰 Updating leaderboard with portfolio value: \$${_totalValue.toStringAsFixed(2)}');
      final gamification = GamificationService.instance;
      if (gamification != null) {
        await gamification.updateLeaderboard(portfolioValue: _totalValue);
      }
    } catch (e) {
      print('⚠️ Error updating leaderboard after portfolio calculation: $e');
    }
    
    // Track diversification challenge (check sectors when portfolio updates)
    try {
      WeeklyChallengeService().trackProgress('diversification', 0); // 0 amount, will count sectors
    } catch (e) {
      print('⚠️ Error tracking diversification: $e');
    }
    
    notifyListeners();
  }
  
  // Method to update stop loss/take profit on existing position
  Future<bool> updatePositionOrders(String symbol, {double? stopLoss, double? takeProfit}) async {
    final positionIndex = _positions.indexWhere((p) => p.symbol == symbol);
    if (positionIndex == -1) return false;
    
    final position = _positions[positionIndex];
    
    // Validate stop loss and take profit
    if (stopLoss != null && stopLoss >= position.currentPrice) {
      return false; // Invalid stop loss
    }
    if (takeProfit != null && takeProfit <= position.currentPrice) {
      return false; // Invalid take profit
    }
    
    _positions[positionIndex] = PaperPosition(
      symbol: position.symbol,
      quantity: position.quantity,
      averagePrice: position.averagePrice,
      currentPrice: position.currentPrice,
      firstBought: position.firstBought,
      lastUpdated: DateTime.now(),
      unrealizedPnL: position.unrealizedPnL,
      unrealizedPnLPercent: position.unrealizedPnLPercent,
      totalInvested: position.totalInvested,
      currentValue: position.currentValue,
      stopLoss: stopLoss ?? position.stopLoss,
      takeProfit: takeProfit ?? position.takeProfit,
    );
    
    await _savePortfolioToDatabase();
    notifyListeners();
    return true;
  }

  // Get mock price for a symbol
  double _getMockPrice(String symbol) {
    final mockPrices = {
      'AAPL': 175.20,
      'GOOGL': 142.50,
      'MSFT': 378.85,
      'AMZN': 155.30,
      'TSLA': 248.50,
      'META': 485.20,
      'NVDA': 875.30,
      'NFLX': 485.60,
      'SPY': 450.25,
      'QQQ': 380.15,
      'AMD': 125.40,
      'INTC': 45.80,
    };

    final basePrice = mockPrices[symbol] ?? 100.0;
    // Add some realistic volatility
    final now = DateTime.now();
    final volatility = (now.millisecondsSinceEpoch % 1000) / 10000;
    return basePrice * (1 + (volatility - 0.5) * 0.05);
  }

  // Get position for a symbol
  PaperPosition? getPosition(String symbol) {
    try {
      return _positions.firstWhere((p) => p.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  // Get recent trades
  List<PaperTrade> getRecentTrades({int limit = 10}) {
    return _tradeHistory.take(limit).toList();
  }

  // Get trades by symbol
  List<PaperTrade> getTradesBySymbol(String symbol) {
    return _tradeHistory.where((t) => t.symbol == symbol).toList();
  }

  // Calculate portfolio performance
  Map<String, double> getPerformanceMetrics() {
    if (_tradeHistory.isEmpty) {
      return {
        'totalReturn': 0.0,
        'totalReturnPercent': 0.0,
        'winRate': 0.0,
        'averageWin': 0.0,
        'averageLoss': 0.0,
        'profitFactor': 0.0,
      };
    }

    double totalReturn = 0.0;
    int winningTrades = 0;
    int losingTrades = 0;
    double totalWins = 0.0;
    double totalLosses = 0.0;

    for (final trade in _tradeHistory) {
      if (trade.action == 'sell') {
        // Find corresponding buy trade
        final buyTrades = _tradeHistory.where((t) => 
          t.symbol == trade.symbol && 
          t.action == 'buy' && 
          t.timestamp.isBefore(trade.timestamp)
        ).toList();
        
        if (buyTrades.isNotEmpty) {
          final buyTrade = buyTrades.last;
          final profit = (trade.price - buyTrade.price) * trade.quantity;
          totalReturn += profit;
          
          if (profit > 0) {
            winningTrades++;
            totalWins += profit;
          } else if (profit < 0) {
            losingTrades++;
            totalLosses += profit.abs();
          }
        }
      }
    }

    final totalTrades = winningTrades + losingTrades;
    final winRate = totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0.0;
    final averageWin = winningTrades > 0 ? totalWins / winningTrades : 0.0;
    final averageLoss = losingTrades > 0 ? totalLosses / losingTrades : 0.0;
    final profitFactor = totalLosses > 0 ? totalWins / totalLosses : 0.0;

    return {
      'totalReturn': totalReturn,
      'totalReturnPercent': (_totalValue / _initialBalance - 1) * 100,
      'winRate': winRate,
      'averageWin': averageWin,
      'averageLoss': averageLoss,
      'profitFactor': profitFactor,
    };
  }

  // Reset portfolio
  void resetPortfolio() {
    _stopPeriodicPriceUpdates();
    initializePortfolio();
  }
  
  // Dispose resources
  void dispose() {
    _stopPeriodicPriceUpdates();
  }

  // Save portfolio to storage
  Map<String, dynamic> toJson() {
    return {
      'cashBalance': _cashBalance,
      'positions': _positions.map((p) => p.toJson()).toList(),
      'tradeHistory': _tradeHistory.map((t) => t.toJson()).toList(),
      'totalValue': _totalValue,
      'totalPnL': _totalPnL,
      'dayChange': _dayChange,
      'dayChangePercent': _dayChangePercent,
      'dayStartValue': _dayStartValue,
      'dayStartDate': _dayStartDate?.toIso8601String(),
      'lastUpdated': _lastUpdated.toIso8601String(),
      'lastPriceUpdate': _lastPriceUpdate?.toIso8601String(),
    };
  }

  // Load portfolio from storage
  void fromJson(Map<String, dynamic> json) {
    _cashBalance = (json['cashBalance'] ?? _initialBalance).toDouble();
    _positions = (json['positions'] as List<dynamic>? ?? [])
        .map((p) => PaperPosition.fromJson(p))
        .toList();
    _tradeHistory = (json['tradeHistory'] as List<dynamic>? ?? [])
        .map((t) => PaperTrade.fromJson(t))
        .toList();
    _totalValue = (json['totalValue'] ?? _initialBalance).toDouble();
    _totalPnL = (json['totalPnL'] ?? 0.0).toDouble();
    _dayChange = (json['dayChange'] ?? 0.0).toDouble();
    _dayChangePercent = (json['dayChangePercent'] ?? 0.0).toDouble();
    _dayStartValue = (json['dayStartValue'] ?? _totalValue).toDouble();
    _lastUpdated = DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String());
    
    // Parse day start date
    if (json['dayStartDate'] != null) {
      try {
        _dayStartDate = DateTime.parse(json['dayStartDate']);
      } catch (e) {
        _dayStartDate = null;
      }
    }
    
    // Parse last price update
    if (json['lastPriceUpdate'] != null) {
      try {
        _lastPriceUpdate = DateTime.parse(json['lastPriceUpdate']);
      } catch (e) {
        _lastPriceUpdate = null;
      }
    }
    
    notifyListeners();
  }
}
