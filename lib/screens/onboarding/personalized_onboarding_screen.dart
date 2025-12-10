import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/gamification_service.dart';
import '../../services/paper_trading_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/web_notification_service.dart';
import '../learning/duolingo_home_screen.dart';
import '../professional_stocks_screen.dart';
import '../main_screen.dart';
import 'notification_permission_screen.dart';

/// Personalized Onboarding Screen
/// Collects user information and preferences for a tailored experience
class PersonalizedOnboardingScreen extends StatefulWidget {
  const PersonalizedOnboardingScreen({super.key});

  @override
  State<PersonalizedOnboardingScreen> createState() => _PersonalizedOnboardingScreenState();
}

class _PersonalizedOnboardingScreenState extends State<PersonalizedOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Personalization data
  String _userName = '';
  String? _selectedGoal;
  String? _selectedExperience;
  List<String> _selectedInterests = [];
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _nameController = TextEditingController();

  final List<String> _goals = [
    'Make money trading',
    'Learn financial literacy',
    'Build long-term wealth',
    'Understand the stock market',
    'Prepare for retirement',
  ];

  final List<String> _experienceLevels = [
    'Complete beginner',
    'Know the basics',
    'Some trading experience',
    'Experienced trader',
  ];

  final List<String> _interests = [
    'Stocks',
    'ETFs',
    'Options',
    'Crypto',
    'Technical analysis',
    'Fundamental analysis',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      // Save user preferences
      final preferences = {
        'displayName': _userName.isEmpty ? 'User' : _userName,
        'onboardingGoal': _selectedGoal,
        'experienceLevel': _selectedExperience,
        'interests': _selectedInterests,
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),
      };
      
      await DatabaseService.saveUserProfileData(preferences);
      await DatabaseService.saveUserProgress({
        'onboarding_completed': true,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
      });

      // Initialize portfolio if not already done
      final paperTradingService = Provider.of<PaperTradingService>(context, listen: false);
      if (paperTradingService.cashBalance == 0) {
        paperTradingService.initializePortfolio();
      }

      // Check if we've already requested notification permissions
      // For web, use WebNotificationService; for mobile, use PushNotificationService
      bool hasRequested = false;
      if (kIsWeb) {
        final webNotification = WebNotificationService();
        final permissionStatus = webNotification.getPermissionStatus();
        hasRequested = permissionStatus != 'default'; // If not default, we've requested before
      } else {
        final pushService = PushNotificationService();
        hasRequested = await pushService.hasRequestedPermissions();
      }
      
      if (mounted) {
        if (!hasRequested) {
          // Navigate to notification permission screen
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
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage == 0 && _userName.trim().isEmpty) {
      // Can't proceed without name
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your name to continue'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (_currentPage == 1 && _selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your goal'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (_currentPage < 5) {
      _fadeController.reset();
      _slideController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ).then((_) {
        _fadeController.forward();
        _slideController.forward();
      });
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _fadeController.reset();
      _slideController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ).then((_) {
        _fadeController.forward();
        _slideController.forward();
      });
    }
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
              // Progress bar
              _buildProgressBar(),
              
              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _fadeController.reset();
                    _slideController.reset();
                    _fadeController.forward();
                    _slideController.forward();
                  },
                  itemCount: 6, // Welcome, Name, Goal, Experience, Interests, Ready
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildPage(index),
                      ),
                    );
                  },
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: List.generate(6, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0052FF) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildWelcomePage();
      case 1:
        return _buildNamePage();
      case 2:
        return _buildGoalPage();
      case 3:
        return _buildExperiencePage();
      case 4:
        return _buildInterestsPage();
      case 5:
        return _buildReadyPage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            
            // Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0052FF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0052FF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 48),
            
            Text(
              'Welcome to Orion! 👋',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                letterSpacing: -1,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'The Duolingo of Finance',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0052FF),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Let\'s personalize your journey.\nThis will only take a minute!',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0052FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 50,
                color: Color(0xFF0052FF),
              ),
            ),
            
            const SizedBox(height: 40),
            
            Text(
              'What should we call you?',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'We\'ll use this to personalize your experience',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                setState(() {
                  _userName = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF0052FF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF0052FF), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0052FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_outlined,
                size: 50,
                color: Color(0xFF0052FF),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Why are you here, ${_userName.isNotEmpty ? _userName : "there"}?',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Select your main goal',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ..._goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSelectionCard(
                title: goal,
                isSelected: _selectedGoal == goal,
                onTap: () {
                  setState(() {
                    _selectedGoal = goal;
                  });
                },
              ),
            )),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExperiencePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0052FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 50,
                color: Color(0xFF0052FF),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'What\'s your experience level?',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Don\'t worry, we\'ll adjust to your level',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ..._experienceLevels.map((level) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSelectionCard(
                title: level,
                isSelected: _selectedExperience == level,
                onTap: () {
                  setState(() {
                    _selectedExperience = level;
                  });
                },
              ),
            )),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0052FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                size: 50,
                color: Color(0xFF0052FF),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'What interests you?',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Select all that apply (optional)',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _interests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF0052FF).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF0052FF),
                  labelStyle: GoogleFonts.inter(
                    color: isSelected ? const Color(0xFF0052FF) : const Color(0xFF6B7280),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 70,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 48),
            
            Text(
              'You\'re all set, ${_userName.isNotEmpty ? _userName : "there"}! 🎉',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _getPersonalizedMessage(),
              style: GoogleFonts.inter(
                fontSize: 18,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _buildReadyItem(Icons.school_rounded, 'Daily lessons tailored to you'),
                  const SizedBox(height: 16),
                  _buildReadyItem(Icons.account_balance_wallet, '\$10,000 virtual portfolio'),
                  const SizedBox(height: 16),
                  _buildReadyItem(Icons.emoji_events, 'Earn XP and build streaks'),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0052FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0052FF), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getPersonalizedMessage() {
    if (_selectedGoal != null) {
      if (_selectedGoal!.contains('money') || _selectedGoal!.contains('wealth')) {
        return 'Let\'s build your wealth together. Start your first lesson today!';
      } else if (_selectedGoal!.contains('Learn') || _selectedGoal!.contains('Understand')) {
        return 'Ready to become financially literate? Let\'s start learning!';
      }
    }
    return 'Your personalized learning journey starts now. Let\'s begin!';
  }

  Widget _buildSelectionCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF0052FF).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentPage == 5 ? 'Get Started 🚀' : 'Continue',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


