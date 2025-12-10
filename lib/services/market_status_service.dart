import 'package:flutter/material.dart';

class MarketStatusService {
  static final MarketStatusService _instance = MarketStatusService._internal();
  factory MarketStatusService() => _instance;
  MarketStatusService._internal();

  bool get isMarketOpen {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    
    // Market is open Monday-Friday, 9:30 AM - 4:00 PM ET
    // For simplicity, we'll use 9:30 AM - 4:00 PM local time
    // This is a basic implementation - in production you'd use proper timezone conversion
    
    // Check if it's a weekday (Monday = 1, Friday = 5)
    if (weekday < 1 || weekday > 5) {
      return false;
    }
    
    final hour = now.hour;
    final minute = now.minute;
    final currentTime = hour * 60 + minute;
    
    // Market hours: 9:30 AM to 4:00 PM (570 minutes to 960 minutes)
    final marketOpenTime = 9 * 60 + 30; // 9:30 AM = 570 minutes
    final marketCloseTime = 16 * 60; // 4:00 PM = 960 minutes
    
    return currentTime >= marketOpenTime && currentTime < marketCloseTime;
  }

  String get marketStatusMessage {
    if (isMarketOpen) {
      return "Market is OPEN! 🟢 Live prices are updating in real-time.";
    } else {
      return "Market is CLOSED 🔴 You'll see yesterday's closing prices.";
    }
  }

  String get marketStatusEmoji {
    return isMarketOpen ? "🟢" : "🔴";
  }

  String getMarketGuidance(String actionType) {
    if (isMarketOpen) {
      switch (actionType) {
        case 'watch':
          return "Watch live price movements as they happen!";
        case 'trade':
          return "You can make real trades right now!";
        case 'analyze':
          return "Analyze current market conditions and live data.";
        default:
          return "Market is open - perfect time for live analysis!";
      }
    } else {
      switch (actionType) {
        case 'watch':
          return "Watch yesterday's price movements and analyze patterns.";
        case 'trade':
          return "Plan your trades for when market opens tomorrow.";
        case 'analyze':
          return "Analyze historical data and prepare for tomorrow.";
        default:
          return "Use this time to research and plan your strategy.";
      }
    }
  }
}
