import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'daily_challenge_screen.dart';
// import '../widgets/learning/web_swipe_card.dart';
// import '../data/teenager_trading_plan.dart';
import 'simple_learning_screen.dart';
import 'micro_learning_screen.dart';
import 'leaderboard_screen.dart';
import '../../services/gamification_service.dart';
import '../../services/user_progress_service.dart';
import 'package:provider/provider.dart';

class LearningHomeScreen extends StatefulWidget {
  const LearningHomeScreen({Key? key}) : super(key: key);

  @override
  _LearningHomeScreenState createState() => _LearningHomeScreenState();
}

class _LearningHomeScreenState extends State<LearningHomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
    
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'LearningHomeScreen',
        screenType: 'main',
        metadata: {'section': 'learning'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildProgressCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildDailyChallenge(),
                    const SizedBox(height: 24),
                    _buildMoneyPlan(),
                    const SizedBox(height: 24),
                    _buildLearningModules(),
                    const SizedBox(height: 24),
                    _buildRecentAchievements(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to learn?',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(24),
          ),
          child: IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.blue),
            onPressed: () => _showLeaderboard(),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Consumer<GamificationService>(
      builder: (context, gamification, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level ${gamification.level}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressItem(
                      'XP',
                      '${gamification.totalXP}',
                      Icons.bolt,
                      Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _buildProgressItem(
                      'Streak',
                      '${gamification.streak}',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildProgressItem(
                      'Days',
                      '7',
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildXPProgressBar(gamification),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildXPProgressBar(GamificationService gamification) {
    final currentLevelXP = (gamification.level - 1) * 1000;
    final nextLevelXP = gamification.level * 1000;
    final progress = (gamification.totalXP - currentLevelXP) / (nextLevelXP - currentLevelXP);
    final clampedProgress = progress.clamp(0.0, 1.0);
    final xpToNext = nextLevelXP - gamification.totalXP;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress to Level ${gamification.level + 1}',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              '$xpToNext/1000 XP',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: clampedProgress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            'Continue Learning',
            'Resume your progress',
            Icons.play_arrow,
            Colors.green,
            () => _continueLearning(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickActionCard(
            'Daily Challenge',
            'Today\'s special',
            Icons.emoji_events,
            Colors.purple,
            () => _startDailyChallenge(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallenge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Challenge',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Complete 5 swipe cards in 2 minutes',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+100 XP',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startDailyChallenge(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Challenge',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyPlan() {
    final plan = _get30DayTradingPlan();
    final currentWeek = plan[0]; // Start with week 1
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C54), Color(0xFF40407A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                '30-Day Money Plan',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentWeek['title'],
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Focus: Making money from day 1 with dopamine-driven learning',
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Show first 3 days
          ...currentWeek['days'].take(3).map<Widget>((day) => 
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${day['day']}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day['title'],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day['focus'],
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Goal: ${day['earning_goal']} | Time: ${day['duration']}',
                              style: GoogleFonts.poppins(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to detailed plan
                _showMoneyPlanDetails();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'View Full 30-Day Plan',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2C2C54),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoneyPlanDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '30-Day Money Plan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: _get30DayTradingPlan().map((week) => 
              ExpansionTile(
                title: Text(
                  week['title'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                children: week['days'].map<Widget>((day) => 
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2C2C54),
                      child: Text(
                        '${day['day']}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    title: Text(
                      day['title'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(day['focus']),
                    onTap: () {
                      // Show day details
                      _showDayDetails(day);
                    },
                  ),
                ).toList(),
              ),
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(Map<String, dynamic> day) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Day ${day['day']}: ${day['title']}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: day['lessons'].map<Widget>((lesson) => 
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getLessonIcon(lesson['type']),
                            color: _getLessonColor(lesson['type']),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lesson['title'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lesson['content'],
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Earning: ${lesson['earning_potential']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Time: ${lesson['time_required']}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'concept': return Icons.lightbulb;
      case 'immediate': return Icons.flash_on;
      case 'trading': return Icons.trending_up;
      case 'mindset': return Icons.psychology;
      case 'business': return Icons.business;
      case 'risk': return Icons.warning;
      case 'passive': return Icons.nightlight_round;
      case 'compound': return Icons.trending_up;
      case 'real_money': return Icons.attach_money;
      default: return Icons.school;
    }
  }

  Color _getLessonColor(String type) {
    switch (type) {
      case 'concept': return Colors.blue;
      case 'immediate': return Colors.orange;
      case 'trading': return Colors.green;
      case 'mindset': return Colors.purple;
      case 'business': return Colors.indigo;
      case 'risk': return Colors.red;
      case 'passive': return Colors.teal;
      case 'compound': return Colors.green;
      case 'real_money': return Colors.amber;
      default: return Colors.grey;
    }
  }

  Widget _buildLearningModules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Modules',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildModuleCard(
          'Stock Basics',
          'Learn the fundamentals',
          Icons.school,
          Colors.blue,
          0.8,
          true,
        ),
        const SizedBox(height: 12),
        _buildModuleCard(
          'Trading Strategies',
          'Master different approaches',
          Icons.trending_up,
          Colors.green,
          0.3,
          true,
        ),
        const SizedBox(height: 12),
        _buildModuleCard(
          'Advanced Analysis',
          'Deep dive into markets',
          Icons.analytics,
          Colors.purple,
          0.0,
          false,
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    double progress,
    bool isUnlocked,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.black : Colors.grey,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUnlocked)
                const Icon(Icons.lock, color: Colors.grey),
              if (isUnlocked && progress > 0)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          if (isUnlocked) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '15 min',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Achievements',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Achievement ${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLeaderboard() {
    // Show leaderboard modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leaderboard', style: GoogleFonts.poppins()),
        content: const Text('Leaderboard coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _continueLearning() {
    // Navigate to simple learning
    // Track interaction and navigation
    UserProgressService().trackWidgetInteraction(
      screenName: 'LearningHomeScreen',
      widgetType: 'button',
      actionType: 'tap',
      widgetId: 'simple_learning',
    );
    UserProgressService().trackNavigation(
      fromScreen: 'LearningHomeScreen',
      toScreen: 'SimpleLearningScreen',
      navigationMethod: 'push',
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleLearningScreen(),
      ),
    );
  }

  void _startDailyChallenge() {
    // Navigate to daily challenge
    // Track interaction and navigation
    UserProgressService().trackWidgetInteraction(
      screenName: 'LearningHomeScreen',
      widgetType: 'button',
      actionType: 'tap',
      widgetId: 'daily_challenge',
    );
    UserProgressService().trackNavigation(
      fromScreen: 'LearningHomeScreen',
      toScreen: 'DailyChallengeScreen',
      navigationMethod: 'push',
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DailyChallengeScreen(),
      ),
    );
  }

  Future<void> _loadUserProgress() async {
    // Load from database via GamificationService
    final gamification = Provider.of<GamificationService>(context, listen: false);
    await gamification.loadFromDatabase();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _get30DayTradingPlan() {
    return [
      {
        'title': 'Week 1: Basics',
        'lessons': ['What is a stock?', 'How markets work', 'Reading stock prices']
      },
      {
        'title': 'Week 2: Analysis',
        'lessons': ['Technical analysis', 'Fundamental analysis', 'Reading charts']
      },
      {
        'title': 'Week 3: Trading',
        'lessons': ['Buy and sell orders', 'Risk management', 'Portfolio building']
      },
      {
        'title': 'Week 4: Advanced',
        'lessons': ['Options basics', 'Market psychology', 'Building wealth']
      }
    ];
  }
}
