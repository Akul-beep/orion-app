import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';

class LevelUpCelebrationWidget extends StatefulWidget {
  const LevelUpCelebrationWidget({super.key});

  @override
  State<LevelUpCelebrationWidget> createState() => _LevelUpCelebrationWidgetState();
}

class _LevelUpCelebrationWidgetState extends State<LevelUpCelebrationWidget>
    with SingleTickerProviderStateMixin {
  bool _showCelebration = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _checkLevelUp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkLevelUp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gamification = Provider.of<GamificationService>(context, listen: false);
      
      if (gamification.hasLeveledUp && mounted) {
        setState(() {
          _showCelebration = true;
        });
        _controller.forward();

        // Clear level up flag after showing
        Future.delayed(const Duration(milliseconds: 100), () {
          gamification.clearLevelUpFlag();
        });

        // Auto-dismiss after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _controller.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showCelebration = false;
                });
              }
            });
          }
        });
      }
    });
  }

  void _dismissCelebration() {
    final gamification = Provider.of<GamificationService>(context, listen: false);
    gamification.clearLevelUpFlag();
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showCelebration = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showCelebration) {
      return const SizedBox.shrink();
    }

    final gamification = Provider.of<GamificationService>(context);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_showCelebration,
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
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 0.1,
                      child: Card(
                        elevation: 24,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981),
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
                                  onPressed: _dismissCelebration,
                                ),
                              ),
                              
                              // Confetti/Stars animation area
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Rotating stars
                                    Transform.rotate(
                                      angle: _rotationAnimation.value * 2 * 3.14159,
                                      child: const Icon(
                                        Icons.star,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Level number
                                    Text(
                                      '${gamification.level}',
                                      style: GoogleFonts.inter(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Title
                              Text(
                                'LEVEL UP! 🎉',
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Subtitle
                              Text(
                                'You reached Level ${gamification.level}!',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // XP info
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.diamond,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${gamification.xp} XP',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Progress to next level
                              Text(
                                '${gamification.getXPToNextLevel()} XP to Level ${gamification.level + 1}',
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
              ),
            );
          },
        ),
      ),
    );
  }
}






