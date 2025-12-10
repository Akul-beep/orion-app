import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/weekly_challenge_service.dart';
import '../services/friend_quest_service.dart';
import '../services/friend_service.dart';
import 'weekly_challenge_widget.dart';
import 'friend_quest_widget.dart';
import '../screens/friends/friends_screen.dart';

class ChallengesDropdownWidget extends StatefulWidget {
  const ChallengesDropdownWidget({Key? key}) : super(key: key);

  @override
  State<ChallengesDropdownWidget> createState() => _ChallengesDropdownWidgetState();
}

class _ChallengesDropdownWidgetState extends State<ChallengesDropdownWidget> {
  bool _isExpanded = false;

  int _getActiveChallengeCount() {
    int count = 0;
    final weeklyChallenge = Provider.of<WeeklyChallengeService>(context, listen: false);
    final friendQuest = Provider.of<FriendQuestService>(context, listen: false);
    final friendService = Provider.of<FriendService>(context, listen: false);
    
    if (weeklyChallenge.isChallengeActive && !weeklyChallenge.isLoading) {
      count++;
    }
    if (friendQuest.isQuestActive && !friendQuest.isLoading && friendService.friends.isNotEmpty) {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WeeklyChallengeService, FriendQuestService, FriendService>(
      builder: (context, weeklyChallenge, friendQuest, friendService, child) {
        final hasWeeklyChallenge = weeklyChallenge.isChallengeActive && !weeklyChallenge.isLoading;
        final hasFriendQuest = friendQuest.isQuestActive && !friendQuest.isLoading && friendService.friends.isNotEmpty;
        final activeCount = _getActiveChallengeCount();

        // Don't show if no challenges
        if (activeCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with badge - entire row is tappable
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Color(0xFF0052FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Challenges',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeCount == 1 
                                  ? '$activeCount active challenge'
                                  : '$activeCount active challenges',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge
                      if (activeCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0052FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$activeCount',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expanded content
              if (_isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (hasWeeklyChallenge) ...[
                        const WeeklyChallengeCard(),
                        if (hasFriendQuest) const SizedBox(height: 12),
                      ],
                      if (hasFriendQuest) ...[
                        const FriendQuestCard(),
                      ],
                      if (!hasWeeklyChallenge && !hasFriendQuest && friendService.friends.isEmpty) ...[
                        _buildNoFriendsState(context),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoFriendsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(height: 12),
          Text(
            'Add Friends to Unlock Friend Challenges!',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Team up with friends to complete challenges together and earn bonus XP!',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsScreen()),
              );
            },
            icon: const Icon(Icons.person_add, size: 18),
            label: Text(
              'Add Friends',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Separate card widgets for proper sizing
class WeeklyChallengeCard extends StatelessWidget {
  const WeeklyChallengeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: const WeeklyChallengeWidget(),
    );
  }
}

class FriendQuestCard extends StatelessWidget {
  const FriendQuestCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: const FriendQuestWidget(),
    );
  }
}

