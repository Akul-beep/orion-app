import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/gamification_service.dart';
import '../../services/paper_trading_service.dart';
import '../../services/push_notification_service.dart';
import '../../design_system.dart';
import '../learning/duolingo_home_screen.dart';
import '../professional_stocks_screen.dart';
import '../main_screen.dart';
import 'notification_permission_screen.dart';
import 'personalized_onboarding_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasSeenPortfolioSetup = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Orion',
      subtitle: 'The Duolingo of Finance',
      description: 'Learn trading like you learn a language. Master stocks through interactive lessons, practice with paper trading, and compete with friends.',
      icon: Icons.trending_up,
      color: const Color(0xFF0052FF),
      image: '📊',
    ),
    OnboardingPage(
      title: 'Learn & Master',
      subtitle: 'Daily Lessons That Stick',
      description: 'Unlock one lesson per day. Each lesson teaches real trading concepts with interactive quizzes and practical examples.',
      icon: Icons.school_rounded,
      color: const Color(0xFF0052FF),
      image: '🎓',
      features: [
        '5-minute bite-sized lessons',
        'Interactive quizzes & challenges',
        'Real trading concepts explained',
        'Earn badges & XP rewards',
      ],
    ),
    OnboardingPage(
      title: 'Practice Trading',
      subtitle: '\$10,000 Virtual Portfolio',
      description: 'Apply what you learn in our paper trading simulator. Trade real stocks with virtual money—no risk, all reward.',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF0052FF),
      image: '💰',
      features: [
        '\$10,000 virtual starting balance',
        'Real-time stock prices',
        'Buy & sell like a pro',
        'Track your profits & losses',
      ],
    ),
    OnboardingPage(
      title: 'Compete & Grow',
      subtitle: 'Gamification That Works',
      description: 'Earn XP, unlock badges, build daily streaks, and climb the leaderboard. Make learning trading fun and addictive!',
      icon: Icons.emoji_events,
      color: const Color(0xFF0052FF),
      image: '🏆',
      features: [
        'Level up with XP & achievements',
        'Daily streak challenges',
        'Compete with friends',
        'Unlock exclusive badges',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      // Mark onboarding as completed
      await DatabaseService.saveUserProgress({
        'onboarding_completed': true,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
      });

      // Initialize portfolio if not already done
      if (!_hasSeenPortfolioSetup) {
        final paperTradingService = Provider.of<PaperTradingService>(context, listen: false);
        if (paperTradingService.cashBalance == 0) {
          paperTradingService.initializePortfolio();
        }
        _hasSeenPortfolioSetup = true;
      }

      // Check if we've already requested notification permissions
      final pushService = PushNotificationService();
      final hasRequested = await pushService.hasRequestedPermissions();
      
      // Navigate to notification permission screen if not requested yet
      // (like Duolingo does after onboarding)
      if (mounted) {
        if (!hasRequested) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const NotificationPermissionScreen(),
            ),
          );
        } else {
          // Already requested - go to main app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      // Still navigate even if save fails
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF8F9FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              if (_currentPage < _pages.length - 1)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_pages[index]);
                  },
                ),
              ),
              
              // Page indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildPageIndicator(index == _currentPage),
                  ),
                ),
              ),
              
              // Next/Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: const Color(0xFF0052FF).withOpacity(0.3),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started 🚀' : 'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Logo at the top of first page, icon/image for others
            if (_currentPage == 0)
              _buildLogo()
            else
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF0052FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFF0052FF).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: page.image != null
                      ? Text(
                          page.image!,
                          style: const TextStyle(fontSize: 72),
                        )
                      : Icon(
                          page.icon,
                          size: 72,
                          color: const Color(0xFF0052FF),
                        ),
                ),
              ),
            
            const SizedBox(height: 48),
            
            // Title
            Text(
              page.title,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              page.subtitle,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0052FF),
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Description
            Text(
              page.description,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF6B7280),
                height: 1.6,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Features list with modern cards
            if (page.features != null && page.features!.isNotEmpty) ...[
              const SizedBox(height: 40),
              ...page.features!.map((feature) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF0052FF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0052FF) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/logo/app_logo.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0052FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF0052FF).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              size: 60,
              color: Color(0xFF0052FF),
            ),
          );
        },
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String? image;
  final List<String>? features;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.image,
    this.features,
  });
}

