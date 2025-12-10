import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../services/daily_goals_service.dart';
import '../services/user_engagement_service.dart';
import '../services/web_notification_service.dart';
import '../screens/learning/duolingo_home_screen.dart';
import '../services/user_progress_service.dart';

/// Daily Engagement Hook Widget
/// Designed to hook users and get them back every day
/// Implements strategies from AppsFlyer retention video
class DailyEngagementHookWidget extends StatefulWidget {
  const DailyEngagementHookWidget({super.key});

  @override
  State<DailyEngagementHookWidget> createState() => _DailyEngagementHookWidgetState();
}

class _DailyEngagementHookWidgetState extends State<DailyEngagementHookWidget> {
  String? _personalizedMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonalizedMessage();
  }

  Future<void> _loadPersonalizedMessage() async {
    final engagementService = UserEngagementService();
    final gamification = Provider.of<GamificationService>(context, listen: false);
    final dailyGoals = Provider.of<DailyGoalsService>(context, listen: false);
    
    final message = await engagementService.getPersonalizedMessage(
      gamification: gamification,
      dailyGoals: dailyGoals,
    );
    
    if (mounted) {
      setState(() {
        _personalizedMessage = message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GamificationService, DailyGoalsService>(
      builder: (context, gamification, dailyGoals, child) {
        if (_isLoading) {
          return const SizedBox.shrink();
        }

        final allGoalsComplete = dailyGoals.isLessonGoalComplete &&
                                 dailyGoals.isTradeGoalComplete &&
                                 dailyGoals.isXPGoalComplete;
        
        final streak = gamification.streak;
        final streakAtRisk = dailyGoals.isStreakAtRisk(gamification);

        // Different hooks based on state
        if (allGoalsComplete) {
          return _buildCelebrationHook(streak);
        } else if (streakAtRisk) {
          return _buildStreakAtRiskHook(streak, dailyGoals);
        } else if (streak > 0) {
          return _buildStreakHook(streak, dailyGoals);
        } else {
          return _buildMotivationHook(_personalizedMessage ?? 'Start your trading journey today!');
        }
      },
    );
  }

  Widget _buildCelebrationHook(int streak) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Goals Complete! 🎉',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your $streak-day streak is safe!',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Great job today! Come back tomorrow for a new lesson!',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.95),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakAtRiskHook(int streak, DailyGoalsService dailyGoals) {
    final remainingGoals = [];
    if (!dailyGoals.isLessonGoalComplete) remainingGoals.add('Complete a lesson');
    if (!dailyGoals.isTradeGoalComplete) remainingGoals.add('Make a trade');
    if (!dailyGoals.isXPGoalComplete) {
      final xpNeeded = dailyGoals.dailyXPGoal - dailyGoals.todayXP;
      remainingGoals.add('Earn $xpNeeded more XP');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Streak At Risk!',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your $streak-day streak needs attention!',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...remainingGoals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await UserProgressService().trackNavigation(
                  fromScreen: 'Dashboard',
                  toScreen: 'DuolingoHomeScreen',
                  navigationMethod: 'push',
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DuolingoHomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Complete Goals Now',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakHook(int streak, DailyGoalsService dailyGoals) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak-Day Streak! 🔥',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep it going! Complete your daily goals.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            onPressed: () async {
              await UserProgressService().trackNavigation(
                fromScreen: 'Dashboard',
                toScreen: 'DuolingoHomeScreen',
                navigationMethod: 'push',
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DuolingoHomeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationHook(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0052FF),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Color(0xFF0052FF), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await UserProgressService().trackNavigation(
                  fromScreen: 'Dashboard',
                  toScreen: 'DuolingoHomeScreen',
                  navigationMethod: 'push',
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DuolingoHomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Start Learning',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


