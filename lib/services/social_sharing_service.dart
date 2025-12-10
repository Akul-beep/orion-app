import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'gamification_service.dart';

class SocialSharingService {
  static final SocialSharingService _instance = SocialSharingService._internal();
  factory SocialSharingService() => _instance;
  SocialSharingService._internal();

  Future<void> shareAchievement(String badgeName, String description) async {
    final text = '🏆 I just unlocked "$badgeName" on Orion! $description\n\nDownload Orion to start your financial learning journey!';
    await Share.share(text);
  }

  Future<void> shareStreak(int streak) async {
    final text = '🔥 I have a $streak-day streak on Orion! Learning finance has never been this fun!\n\nJoin me on Orion!';
    await Share.share(text);
  }

  Future<void> shareLevelUp(int level) async {
    final text = '⭐ I just reached Level $level on Orion! Leveling up my financial knowledge one day at a time!\n\nStart your journey today!';
    await Share.share(text);
  }

  Future<void> shareWeeklyChallenge(String challengeName, int reward) async {
    final text = '🎯 I completed the "$challengeName" weekly challenge on Orion and earned $reward XP!\n\nChallenge yourself on Orion!';
    await Share.share(text);
  }

  Future<void> sharePortfolioPerformance(double returnPercent) async {
    final emoji = returnPercent >= 0 ? '📈' : '📉';
    final text = '$emoji My paper trading portfolio on Orion is ${returnPercent >= 0 ? 'up' : 'down'} ${returnPercent.abs().toStringAsFixed(1)}%!\n\nStart paper trading on Orion!';
    await Share.share(text);
  }

  Future<void> shareMilestone(String milestone) async {
    final text = '🎉 $milestone on Orion!\n\nJoin me on this amazing financial learning journey!';
    await Share.share(text);
  }
}






