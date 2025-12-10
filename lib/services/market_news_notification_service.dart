import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'paper_trading_service.dart';
import 'stock_api_service.dart';
import 'push_notification_service.dart';
import '../models/news_article.dart';

/// Service to check for market news about user's portfolio stocks and send notifications
class MarketNewsNotificationService {
  static final MarketNewsNotificationService _instance = MarketNewsNotificationService._internal();
  factory MarketNewsNotificationService() => _instance;
  MarketNewsNotificationService._internal();

  Timer? _checkTimer;
  SharedPreferences? _prefs;
  Set<String> _notifiedNewsIds = {}; // Track which news we've already notified about
  DateTime? _lastCheckTime;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadNotifiedNews();
    print('✅ Market News Notification Service initialized');
  }

  /// Start periodic checks for market news
  void startPeriodicChecks(PaperTradingService tradingService) {
    // Cancel existing timer if any
    _checkTimer?.cancel();

    // Check every 2 hours during market hours (9 AM - 4 PM)
    _checkTimer = Timer.periodic(const Duration(hours: 2), (timer) async {
      final now = DateTime.now();
      final hour = now.hour;
      
      // Only check during market hours (9 AM - 4 PM)
      if (hour >= 9 && hour <= 16) {
        await checkForPortfolioNews(tradingService);
      }
    });

    // Also check immediately
    checkForPortfolioNews(tradingService);
  }

  /// Stop periodic checks
  void stopPeriodicChecks() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check for news about stocks in user's portfolio
  Future<void> checkForPortfolioNews(PaperTradingService tradingService) async {
    if (!(await PushNotificationService().isMarketNewsEnabled())) {
      return;
    }

    final positions = tradingService.positions;
    if (positions.isEmpty) {
      print('📰 No positions to check news for');
      return;
    }

    print('📰 Checking for news on ${positions.length} portfolio stocks...');

    // Get unique symbols from positions
    final symbols = positions.map((p) => p.symbol).toSet().toList();

    // Check news for each symbol (limit to avoid API rate limits)
    final symbolsToCheck = symbols.take(5).toList(); // Check max 5 stocks at a time

    for (final symbol in symbolsToCheck) {
      try {
        await _checkNewsForSymbol(symbol);
        // Add delay to respect rate limits
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        print('⚠️ Error checking news for $symbol: $e');
      }
    }

    _lastCheckTime = DateTime.now();
    await _saveNotifiedNews();
  }

  /// Check news for a specific symbol
  Future<void> _checkNewsForSymbol(String symbol) async {
    try {
      // Get news from last 24 hours
      final news = await StockApiService.getCompanyNews(symbol);
      
      if (news.isEmpty) {
        return;
      }

      // Filter for news from last 24 hours
      final now = DateTime.now();
      final recentNews = news.where((article) {
        final published = article.datetime;
        final hoursSincePublished = now.difference(published).inHours;
        return hoursSincePublished <= 24;
      }).toList();

      if (recentNews.isEmpty) {
        return;
      }

      // Get the most important/recent news
      final importantNews = recentNews.take(3).toList();

      for (final article in importantNews) {
        // Check if we've already notified about this news
        final newsId = '${article.id}_${symbol}_${article.headline}';
        if (_notifiedNewsIds.contains(newsId)) {
          continue;
        }

        // Only notify about significant news (headline length, keywords, etc.)
        if (_isSignificantNews(article)) {
          await PushNotificationService().showMarketNewsNotification(
            symbol,
            article.headline,
          );
          
          // Mark as notified
          _notifiedNewsIds.add(newsId);
          
          // Limit to last 100 notified items to prevent memory issues
          if (_notifiedNewsIds.length > 100) {
            final oldest = _notifiedNewsIds.toList().first;
            _notifiedNewsIds.remove(oldest);
          }
        }
      }
    } catch (e) {
      print('⚠️ Error fetching news for $symbol: $e');
    }
  }

  /// Determine if news is significant enough to notify
  bool _isSignificantNews(NewsArticle article) {
    final headline = article.headline.toLowerCase();
    
    // Keywords that indicate significant news
    final significantKeywords = [
      'earnings', 'revenue', 'profit', 'loss', 'beat', 'miss',
      'acquisition', 'merger', 'deal', 'partnership',
      'launch', 'release', 'announcement',
      'upgrade', 'downgrade', 'rating', 'analyst',
      'lawsuit', 'regulation', 'fda', 'approval',
      'ceo', 'executive', 'resignation', 'hire',
      'guidance', 'forecast', 'outlook',
    ];

    // Check if headline contains significant keywords
    for (final keyword in significantKeywords) {
      if (headline.contains(keyword)) {
        return true;
      }
    }

    // Also notify if it's from a major source
    final source = article.source.toLowerCase();
    final majorSources = ['reuters', 'bloomberg', 'cnbc', 'wsj', 'financial times', 'yahoo finance'];
    for (final majorSource in majorSources) {
      if (source.contains(majorSource)) {
        return true;
      }
    }

    return false;
  }

  /// Load notified news IDs from storage
  Future<void> _loadNotifiedNews() async {
    try {
      final json = _prefs?.getString('notified_news_ids');
      if (json != null) {
        final List<dynamic> list = jsonDecode(json);
        _notifiedNewsIds = list.map((e) => e.toString()).toSet();
        print('📰 Loaded ${_notifiedNewsIds.length} notified news IDs');
      }
    } catch (e) {
      print('⚠️ Error loading notified news: $e');
    }
  }

  /// Save notified news IDs to storage
  Future<void> _saveNotifiedNews() async {
    try {
      final json = jsonEncode(_notifiedNewsIds.toList());
      await _prefs?.setString('notified_news_ids', json);
    } catch (e) {
      print('⚠️ Error saving notified news: $e');
    }
  }

  /// Clear old notified news (older than 7 days)
  Future<void> clearOldNotifiedNews() async {
    // For simplicity, we'll just limit the size
    // In a production app, you'd track timestamps
    if (_notifiedNewsIds.length > 100) {
      final list = _notifiedNewsIds.toList();
      _notifiedNewsIds = list.skip(list.length - 50).toSet();
      await _saveNotifiedNews();
    }
  }
}

