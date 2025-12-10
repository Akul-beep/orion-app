import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_action.dart';
import '../services/learning_action_service.dart';
import '../services/gamification_service.dart';
import '../services/paper_trading_service.dart';
import '../services/learning_popup_service.dart';
import '../screens/enhanced_stock_detail_screen.dart';
import '../screens/professional_stocks_screen.dart';
import '../screens/home_screen.dart';
import '../screens/stocks_screen.dart';
import 'user_progress_service.dart';

class SmartActionHandler {
  static bool _isNavigating = false; // Prevent multiple simultaneous navigations
  
  static Future<void> executeAction(LearningAction action, BuildContext context) async {
    // Prevent multiple navigations
    if (_isNavigating) {
      print('⚠️ Navigation already in progress, ignoring duplicate request');
      return;
    }

    _isNavigating = true;
    
    try {
      final metadata = action.metadata ?? {};
      final redirectTo = metadata['redirectTo'] as String?;
      final symbol = metadata['symbol'] as String?;
      
      // Start learning popup mode (non-blocking)
      final popupService = Provider.of<LearningPopupService>(context, listen: false);
      popupService.startLearningMode(action, action.followUpQuestion ?? 'What did you observe?');
      
      // Show instruction dialog first (if needed)
      if (action.guidance != null) {
        await _showInstructionDialog(context, action.title, action.guidance!);
      }
      
      // Navigate to the appropriate screen (non-blocking for Supabase calls)
      _navigateToScreen(context, redirectTo, symbol, metadata).catchError((e) {
        print('❌ Navigation error: $e');
        _isNavigating = false;
      });
      
      // The popup will handle the follow-up question and XP rewards
    } catch (e) {
      print('❌ Error executing action: $e');
      _isNavigating = false;
      rethrow;
    }
  }
  
  static Future<void> _showInstructionDialog(BuildContext context, String title, String instruction) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFF58CC02), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF58CC02),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instruction,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Color(0xFF58CC02), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Follow the instructions on the next screen',
                      style: TextStyle(
                        color: Color(0xFF58CC02),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Got It!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  
  static Future<void> _navigateToScreen(BuildContext context, String? redirectTo, String? symbol, Map<String, dynamic> metadata) async {
    // Check if context is still mounted
    if (!context.mounted) {
      _isNavigating = false;
      return;
    }

    // Import user progress service
    final userProgress = UserProgressService();
    
    switch (redirectTo) {
      case 'stock_detail':
        if (symbol != null) {
          // Navigate immediately (non-blocking)
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EnhancedStockDetailScreen(
                  symbol: symbol,
                  companyName: _getCompanyName(symbol),
                ),
              ),
            ).then((_) {
              _isNavigating = false;
            });
            
            // Track navigation and activity in background (non-blocking)
            userProgress.trackNavigation(
              fromScreen: 'SmartActionHandler',
              toScreen: 'EnhancedStockDetailScreen',
              navigationMethod: 'push',
              navigationData: {'symbol': symbol, ...metadata},
            ).catchError((e) => print('⚠️ Track navigation error: $e'));
            
            userProgress.trackTradingActivity(
              activityType: 'view_stock',
              symbol: symbol,
              activityData: {'from': 'learning_action', ...metadata},
            ).catchError((e) => print('⚠️ Track activity error: $e'));
          }
        }
        break;
        
      case 'paper_trading':
      case 'trading_screen':
        // Determine initial tab: portfolio = 1, market = 0, watchlist = 2
        final tabName = metadata['tab'] as String?;
        int initialTab = 0; // Default to Market
        if (tabName == 'portfolio') {
          initialTab = 1;
        } else if (tabName == 'watchlist') {
          initialTab = 2;
        }
        
        // Navigate immediately (non-blocking)
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfessionalStocksScreen(
                routeArguments: {
                  'initialTab': initialTab,
                  'symbol': symbol,
                  'action': metadata['action'],
                  'focus': metadata['focus'],
                  'quantity': metadata['quantity'],
                  'orderType': metadata['orderType'],
                },
              ),
            ),
          ).then((_) {
            _isNavigating = false;
          });
          
          // Track navigation in background (non-blocking)
          userProgress.trackNavigation(
            fromScreen: 'SmartActionHandler',
            toScreen: 'ProfessionalStocksScreen',
            navigationMethod: 'push',
            navigationData: metadata,
          ).catchError((e) => print('⚠️ Track navigation error: $e'));
        }
        break;
        
      case 'home_screen':
        // Navigate immediately (non-blocking)
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          ).then((_) {
            _isNavigating = false;
          });
          
          // Track navigation in background (non-blocking)
          userProgress.trackNavigation(
            fromScreen: 'SmartActionHandler',
            toScreen: 'HomeScreen',
            navigationMethod: 'push',
            navigationData: metadata,
          ).catchError((e) => print('⚠️ Track navigation error: $e'));
        }
        break;
        
      case 'stocks_screen':
        // Navigate immediately (non-blocking)
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StocksScreen(),
            ),
          ).then((_) {
            _isNavigating = false;
          });
          
          // Track navigation in background (non-blocking)
          userProgress.trackNavigation(
            fromScreen: 'SmartActionHandler',
            toScreen: 'StocksScreen',
            navigationMethod: 'push',
            navigationData: metadata,
          ).catchError((e) => print('⚠️ Track navigation error: $e'));
        }
        break;
        
      default:
        // Default to stocks screen
        // Navigate immediately (non-blocking)
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StocksScreen(),
            ),
          ).then((_) {
            _isNavigating = false;
          });
          
          // Track navigation in background (non-blocking)
          userProgress.trackNavigation(
            fromScreen: 'SmartActionHandler',
            toScreen: 'StocksScreen',
            navigationMethod: 'push',
            navigationData: metadata,
          ).catchError((e) => print('⚠️ Track navigation error: $e'));
        }
        break;
    }
  }
  
  static Future<void> _showFollowUpQuestion(BuildContext context, String question, LearningAction action) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.quiz, color: Color(0xFF58CC02), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Quick Question',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF58CC02),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                question,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF58CC02)),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _completeAction(action, context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  
  static Future<void> _completeAction(LearningAction action, BuildContext context) async {
    // Give XP reward
    final gamificationService = Provider.of<GamificationService>(context, listen: false);
    gamificationService.addXP(action.xpReward, 'smart_action');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${action.title} completed! +${action.xpReward} XP'),
        backgroundColor: const Color(0xFF58CC02),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  static String _getCompanyName(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'AAPL':
        return 'Apple Inc.';
      case 'GOOGL':
        return 'Alphabet Inc.';
      case 'MSFT':
        return 'Microsoft Corporation';
      case 'TSLA':
        return 'Tesla Inc.';
      case 'AMZN':
        return 'Amazon.com Inc.';
      case 'META':
        return 'Meta Platforms Inc.';
      case 'NVDA':
        return 'NVIDIA Corporation';
      case 'NFLX':
        return 'Netflix Inc.';
      default:
        return symbol;
    }
  }
}
