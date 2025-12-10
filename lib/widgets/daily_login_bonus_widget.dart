import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../services/notification_manager.dart';

class DailyLoginBonusWidget extends StatefulWidget {
  const DailyLoginBonusWidget({super.key});

  @override
  State<DailyLoginBonusWidget> createState() => _DailyLoginBonusWidgetState();
}

class _DailyLoginBonusWidgetState extends State<DailyLoginBonusWidget>
    with SingleTickerProviderStateMixin {
  bool _showBonus = false;
  int? _bonusAmount;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _checkDailyBonus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkDailyBonus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gamification = Provider.of<GamificationService>(context, listen: false);
      final bonus = gamification.awardDailyLoginBonus();
      
      if (bonus != null && mounted) {
        setState(() {
          _bonusAmount = bonus;
          _showBonus = true;
        });
        _controller.forward();

        // Add notification
        Provider.of<NotificationManager>(context, listen: false).addNotification(
          type: 'achievement',
          title: 'Daily Login Bonus! 🎉',
          message: 'You received +$bonus XP for logging in today!',
          data: {'bonus': bonus, 'days': gamification.consecutiveLoginDays},
        );

        // Auto-dismiss after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            _controller.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showBonus = false;
                });
              }
            });
          }
        });
      }
    });
  }

  void _dismissBonus() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showBonus = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBonus || _bonusAmount == null) {
      return const SizedBox.shrink();
    }

    final gamification = Provider.of<GamificationService>(context);
    
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_showBonus,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Card(
                      elevation: 24,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1E3A8A),
                              const Color(0xFF3B82F6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Close button
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: _dismissBonus,
                              ),
                            ),
                            
                            // Trophy icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Title
                            Text(
                              'Daily Login Bonus!',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Consecutive days
                            Text(
                              'Day ${gamification.consecutiveLoginDays}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Bonus amount
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.diamond,
                                    color: Color(0xFF3B82F6),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+$_bonusAmount XP',
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Message
                            Text(
                              gamification.consecutiveLoginDays >= 7
                                  ? '🔥 7+ day streak! Amazing!'
                                  : gamification.consecutiveLoginDays >= 3
                                      ? 'Keep it up! You\'re on a roll!'
                                      : 'Great start! Come back tomorrow!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}






