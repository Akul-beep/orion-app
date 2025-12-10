import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/daily_goals_service.dart';
import '../services/gamification_service.dart';

class DailyGoalsWidget extends StatefulWidget {
  final bool compact;
  
  const DailyGoalsWidget({
    Key? key,
    this.compact = false,
  }) : super(key: key);

  @override
  State<DailyGoalsWidget> createState() => _DailyGoalsWidgetState();
}

class _DailyGoalsWidgetState extends State<DailyGoalsWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DailyGoalsService, GamificationService>(
      builder: (context, goalsService, gamification, child) {
        final summary = goalsService.getDailyGoalsSummary();
        final streakAtRisk = goalsService.isStreakAtRisk(gamification);
        
        if (widget.compact) {
          return _buildCompactView(goalsService, summary, streakAtRisk, gamification);
        }
        
        return _buildFullView(goalsService, summary, streakAtRisk, gamification);
      },
    );
  }

  Widget _buildCompactView(
    DailyGoalsService goalsService, 
    Map<String, dynamic> summary, 
    bool streakAtRisk,
    GamificationService gamification,
  ) {
    final allComplete = summary['allComplete'] as bool;
    final xpProgress = goalsService.xpProgress;
    final tradeProgress = goalsService.tradeProgress;
    final lessonProgress = goalsService.lessonProgress;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: allComplete 
                ? const Color(0xFF10B981) 
                : const Color(0xFFE5E7EB),
            width: allComplete ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (allComplete ? const Color(0xFF10B981) : Colors.black).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: allComplete 
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    allComplete ? Icons.check_circle : Icons.track_changes,
                    color: allComplete ? const Color(0xFF10B981) : const Color(0xFF1E3A8A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        allComplete ? 'Daily Goals Complete' : 'Daily Goals',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (streakAtRisk && !allComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department, size: 12, color: Colors.orange[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Streak at risk',
                                style: GoogleFonts.poppins(
                                  color: Colors.orange[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (allComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, size: 14, color: const Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          '${gamification.streak}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Bars
            _buildCompactProgressBar(
              'XP',
              goalsService.todayXP,
              goalsService.dailyXPGoal,
              xpProgress,
              const Color(0xFF3B82F6),
              goalsService.isXPGoalComplete,
            ),
            const SizedBox(height: 10),
            _buildCompactProgressBar(
              'Trades',
              goalsService.todayTrades,
              goalsService.dailyTradeGoal,
              tradeProgress,
              const Color(0xFF10B981),
              goalsService.isTradeGoalComplete,
            ),
            const SizedBox(height: 10),
            _buildCompactProgressBar(
              'Lessons',
              goalsService.todayLessons,
              goalsService.dailyLessonGoal,
              lessonProgress,
              const Color(0xFFF59E0B),
              goalsService.isLessonGoalComplete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactProgressBar(
    String label,
    int current,
    int goal,
    double progress,
    Color color,
    bool complete,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '$current/$goal',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: complete ? color : const Color(0xFF6B7280),
            ),
          ),
        ),
        if (complete)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: color,
            ),
          ),
      ],
    );
  }

  Widget _buildFullView(DailyGoalsService goalsService, Map<String, dynamic> summary, bool streakAtRisk, GamificationService gamification) {
    final allComplete = summary['allComplete'] as bool;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: allComplete
                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                : [Colors.white, const Color(0xFFF9FAFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: allComplete
              ? null
              : Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: (allComplete ? const Color(0xFF10B981) : Colors.black).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: allComplete
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    allComplete ? Icons.emoji_events : Icons.track_changes,
                    color: allComplete ? Colors.white : const Color(0xFF1E3A8A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allComplete ? 'All Goals Complete!' : 'Daily Goals',
                        style: GoogleFonts.poppins(
                          color: allComplete ? Colors.white : const Color(0xFF111827),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (streakAtRisk && !allComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department, size: 14, color: Colors.orange[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Streak at risk! Complete goals to keep it alive',
                                style: GoogleFonts.poppins(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // XP Goal
            _buildGoalItem(
              icon: Icons.diamond,
              label: 'Earn XP',
              current: goalsService.todayXP,
              goal: goalsService.dailyXPGoal,
              progress: goalsService.xpProgress,
              complete: goalsService.isXPGoalComplete,
              color: const Color(0xFF3B82F6),
              allComplete: allComplete,
            ),
            const SizedBox(height: 12),
            
            // Trade Goal
            _buildGoalItem(
              icon: Icons.trending_up,
              label: 'Make Trades',
              current: goalsService.todayTrades,
              goal: goalsService.dailyTradeGoal,
              progress: goalsService.tradeProgress,
              complete: goalsService.isTradeGoalComplete,
              color: const Color(0xFF10B981),
              allComplete: allComplete,
            ),
            const SizedBox(height: 12),
            
            // Lesson Goal
            _buildGoalItem(
              icon: Icons.school,
              label: 'Complete Lessons',
              current: goalsService.todayLessons,
              goal: goalsService.dailyLessonGoal,
              progress: goalsService.lessonProgress,
              complete: goalsService.isLessonGoalComplete,
              color: const Color(0xFFF59E0B),
              allComplete: allComplete,
            ),
            
            if (allComplete) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Streak: ${gamification.streak} days',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required String label,
    required int current,
    required int goal,
    required double progress,
    required bool complete,
    required Color color,
    required bool allComplete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allComplete
            ? Colors.white.withOpacity(0.2)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: complete && !allComplete
            ? Border.all(color: color, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (allComplete ? Colors.white : color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: allComplete ? Colors.white : color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: allComplete ? Colors.white : const Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (complete)
                      Icon(
                        Icons.check_circle,
                        color: allComplete ? Colors.white : color,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: allComplete
                        ? Colors.white.withOpacity(0.3)
                        : color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      allComplete ? Colors.white : color,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$current / $goal',
                  style: GoogleFonts.poppins(
                    color: allComplete
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
