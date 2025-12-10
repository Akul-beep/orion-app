import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/weekly_challenge_service.dart';
import '../services/gamification_service.dart';
import '../services/referral_service.dart';
import 'package:share_plus/share_plus.dart';

class WeeklyChallengeWidget extends StatefulWidget {
  const WeeklyChallengeWidget({Key? key}) : super(key: key);

  @override
  State<WeeklyChallengeWidget> createState() => _WeeklyChallengeWidgetState();
}

class _WeeklyChallengeWidgetState extends State<WeeklyChallengeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasShownCompletion = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _shareChallengeCompletion() async {
    try {
      final challengeService = Provider.of<WeeklyChallengeService>(context, listen: false);
      final challenge = challengeService.currentChallenge!;
      final referralLink = await ReferralService.getMyReferralLink();
      
      final shareText = '🎉 Just completed "${challenge.title}" on Orion! '
          'Earned ${challenge.reward} XP! 🚀\n\n'
          'Join me and start learning trading: $referralLink';
      
      await Share.share(shareText);
      
      // Award bonus XP for sharing
      try {
        final gamification = GamificationService.instance;
        if (gamification != null) {
          gamification.addXP(50, 'challenge_share');
        }
      } catch (e) {
        print('⚠️ Error awarding share bonus: $e');
      }
    } catch (e) {
      print('⚠️ Error sharing challenge: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklyChallengeService>(
      builder: (context, challengeService, child) {
        if (!challengeService.isChallengeActive || challengeService.isLoading) {
          return const SizedBox.shrink();
        }

        final challenge = challengeService.currentChallenge!;
        final progress = challengeService.progressPercentage;
        final current = challengeService.progress[challenge.id] ?? 0;
        final daysLeft = (7 - DateTime.now().difference(challengeService.challengeStartDate ?? DateTime.now()).inDays).clamp(0, 7);
        final isCompleted = challengeService.isCompleted;

        // Animate on completion
        if (isCompleted && !_hasShownCompletion) {
          _hasShownCompletion = true;
          _animationController.repeat(reverse: true);
        } else if (!isCompleted) {
          _hasShownCompletion = false;
          _animationController.stop();
          _animationController.reset();
        }

        return ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: isCompleted ? _shareChallengeCompletion : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? const Color(0xFF10B981).withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCompleted 
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE5E7EB),
                  width: isCompleted ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCompleted
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : Colors.black.withOpacity(0.03),
                    blurRadius: isCompleted ? 8 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon with completion animation
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : const Color(0xFF0052FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : challenge.icon,
                      color: isCompleted 
                          ? const Color(0xFF10B981)
                          : const Color(0xFF0052FF),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Challenge info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                challenge.title,
                                style: GoogleFonts.inter(
                                  color: isCompleted
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF111827),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: const Color(0xFF10B981),
                                      size: 11,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Done!',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF10B981),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Progress bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted 
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF6366F1),
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$current/${challenge.target}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6B7280),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (isCompleted)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Tap to share your win! 🎉',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF10B981),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Right side - reward and days
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reward badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted ? Icons.star : Icons.diamond,
                              color: isCompleted 
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              size: 11,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '+${challenge.reward}',
                              style: GoogleFonts.inter(
                                color: isCompleted
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6B7280),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$daysLeft left',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
