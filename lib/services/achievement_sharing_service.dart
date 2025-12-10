import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/badge_definition.dart';

/// Achievement Sharing Service - Duolingo-style sharing
/// No friends needed - just share to social media or copy links
class AchievementSharingService {
  /// Share a badge achievement (like Duolingo)
  static Future<void> shareBadge(BadgeDefinition badge) async {
    final message = '${badge.emoji} I just unlocked "${badge.name}" on Orion!\n\n${badge.description}\n\nJoin me and start your financial learning journey! 🚀\n\n#OrionApp #FinanceLearning';
    await Share.share(message);
  }
  
  /// Share level up achievement
  static Future<void> shareLevelUp(int level) async {
    final message = '⭐ I just reached Level $level on Orion! 🎉\n\nLeveling up my financial knowledge one day at a time!\n\nStart your journey today! 🚀\n\n#OrionApp #FinanceLearning';
    await Share.share(message);
  }
  
  /// Share streak achievement
  static Future<void> shareStreak(int streak) async {
    final message = '🔥 I have a $streak-day streak on Orion!\n\nLearning finance has never been this fun! 💪\n\nJoin me on Orion! 🚀\n\n#OrionApp #FinanceLearning';
    await Share.share(message);
  }
  
  /// Share XP milestone
  static Future<void> shareXPMilestone(int xp) async {
    final formattedXP = _formatXP(xp);
    final message = '💎 I just hit $formattedXP XP on Orion! 🎉\n\nEarning gems while learning finance!\n\nStart earning today! 🚀\n\n#OrionApp #FinanceLearning';
    await Share.share(message);
  }
  
  /// Share lesson completion
  static Future<void> shareLessonCompletion(String lessonName) async {
    final message = '✅ I just completed "$lessonName" on Orion! 📚\n\nLearning finance one lesson at a time!\n\nStart learning today! 🚀\n\n#OrionApp #FinanceLearning';
    await Share.share(message);
  }
  
  /// Share trading achievement
  static Future<void> shareTradingAchievement(String achievement) async {
    final message = '📈 $achievement on Orion! 💼\n\nPracticing trading with paper money!\n\nStart trading today! 🚀\n\n#OrionApp #PaperTrading';
    await Share.share(message);
  }
  
  /// Copy achievement text to clipboard
  static Future<void> copyAchievementText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
  
  /// Generate shareable text for any achievement
  static String generateShareText({
    required String type, // 'badge', 'level', 'streak', 'xp', 'lesson', 'trade'
    required String title,
    String? description,
    String? emoji,
    Map<String, dynamic>? extraData,
  }) {
    final defaultEmoji = _getEmojiForType(type);
    final mainEmoji = emoji ?? defaultEmoji;
    
    String message = '$mainEmoji $title on Orion! 🎉\n\n';
    
    if (description != null) {
      message += '$description\n\n';
    }
    
    // Add extra context based on type
    switch (type) {
      case 'badge':
        message += 'Unlocking achievements while learning finance!\n\n';
        break;
      case 'level':
        message += 'Leveling up my financial knowledge!\n\n';
        break;
      case 'streak':
        message += 'Building my learning habit one day at a time!\n\n';
        break;
      case 'xp':
        message += 'Earning gems while mastering finance!\n\n';
        break;
      case 'lesson':
        message += 'Completing lessons and growing my knowledge!\n\n';
        break;
      case 'trade':
        message += 'Practicing trading strategies!\n\n';
        break;
    }
    
    message += 'Join me on Orion! 🚀\n\n#OrionApp #FinanceLearning';
    
    return message;
  }
  
  static String _getEmojiForType(String type) {
    switch (type) {
      case 'badge': return '🏆';
      case 'level': return '⭐';
      case 'streak': return '🔥';
      case 'xp': return '💎';
      case 'lesson': return '✅';
      case 'trade': return '📈';
      default: return '🎉';
    }
  }
  
  static String _formatXP(int xp) {
    if (xp >= 1000000) {
      return '${(xp / 1000000).toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }
}

