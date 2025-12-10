import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/friend_quest_service.dart';

class FriendQuestWidget extends StatelessWidget {
  const FriendQuestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendQuestService>(
      builder: (context, questService, child) {
        if (!questService.isQuestActive || questService.isLoading) {
          return const SizedBox.shrink();
        }

        final quest = questService.currentQuest!;
        final progress = questService.progressPercentage;
        final combinedProgress = questService.progress.values.fold<int>(0, (sum, p) => sum + p);
        final daysLeft = questService.daysLeft;
        final isCompleted = questService.isCompleted;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isCompleted 
                ? const Color(0xFF10B981).withOpacity(0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                  color: isCompleted 
                  ? const Color(0xFF10B981)
                  : const Color(0xFF0052FF),
              width: isCompleted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? const Color(0xFF10B981).withOpacity(0.2)
                    : const Color(0xFF6366F1).withOpacity(0.1),
                blurRadius: isCompleted ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
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
                  isCompleted ? Icons.people : quest.icon,
                  color: isCompleted 
                  ? const Color(0xFF10B981)
                  : const Color(0xFF0052FF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              
              // Quest info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            quest.title,
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
                    const SizedBox(height: 4),
                    Text(
                      'with ${quest.partnerName}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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
                          '$combinedProgress/${quest.target}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                          '+${quest.reward}',
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
        );
      },
    );
  }
}

