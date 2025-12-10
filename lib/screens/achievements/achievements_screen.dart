import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/gamification_service.dart';
import '../../services/achievement_sharing_service.dart';
import '../../models/badge_definition.dart';
import 'package:share_plus/share_plus.dart';

/// Achievements Screen - Duolingo-style badge showcase
/// Users can view all badges and share their achievements
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Achievements',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ),
      body: Consumer<GamificationService>(
        builder: (context, gamification, child) {
          final earnedBadges = gamification.badges;
          final allBadges = BadgeDefinitions.allBadges;
          
          return Column(
            children: [
              // Stats Header
              _buildStatsHeader(gamification),
              
              // Category Filter
              _buildCategoryFilter(),
              
              // Badges Grid
              Expanded(
                child: _buildBadgesGrid(allBadges, earnedBadges, gamification),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(GamificationService gamification) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0052FF),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${gamification.badges.length}',
            'Badges',
            Icons.emoji_events,
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            '${gamification.level}',
            'Level',
            Icons.star,
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            '${gamification.streak}',
            'Streak',
            Icons.local_fire_department,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'name': 'All', 'emoji': '🎯'},
      {'id': 'learning', 'name': 'Learning', 'emoji': '📚'},
      {'id': 'trading', 'name': 'Trading', 'emoji': '💼'},
      {'id': 'streak', 'name': 'Streak', 'emoji': '🔥'},
      {'id': 'milestone', 'name': 'Milestone', 'emoji': '⭐'},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['id'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0052FF) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    category['emoji'] as String,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgesGrid(List<BadgeDefinition> allBadges, List<String> earnedBadgeIds, GamificationService gamification) {
    // Filter by category
    List<BadgeDefinition> filteredBadges = allBadges;
    if (_selectedCategory != 'all') {
      final category = BadgeCategory.values.firstWhere(
        (c) => c.toString().split('.').last == _selectedCategory,
        orElse: () => BadgeCategory.learning,
      );
      filteredBadges = allBadges.where((b) => b.category == category).toList();
    }
    
    if (filteredBadges.isEmpty) {
      return Center(
        child: Text(
          'No badges in this category',
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 16,
          ),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredBadges.length,
      itemBuilder: (context, index) {
        final badge = filteredBadges[index];
        final isEarned = earnedBadgeIds.contains(badge.id);
        
        return _buildBadgeCard(badge, isEarned);
      },
    );
  }

  Widget _buildBadgeCard(BadgeDefinition badge, bool isEarned) {
    return GestureDetector(
      onTap: isEarned ? () => _showShareDialog(badge) : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEarned 
                ? _getRarityColor(badge.rarity).withOpacity(0.5)
                : const Color(0xFFE5E7EB),
            width: isEarned ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isEarned
                  ? _getRarityColor(badge.rarity).withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isEarned ? 12 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isEarned
                    ? _getRarityColor(badge.rarity).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isEarned
                      ? _getRarityColor(badge.rarity)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: isEarned ? 40 : 35,
                    opacity: isEarned ? 1.0 : 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Badge Name
            Text(
              badge.name,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isEarned ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Badge Description
            Text(
              badge.description,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isEarned ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isEarned) ...[
              const SizedBox(height: 8),
              // Share button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.share, size: 14, color: Color(0xFF0052FF)),
                    const SizedBox(width: 4),
                    Text(
                      'Share',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0052FF),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              // Locked indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Locked',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return const Color(0xFF6B7280); // Gray
      case BadgeRarity.rare:
        return const Color(0xFF3B82F6); // Blue
      case BadgeRarity.epic:
        return const Color(0xFF8B5CF6); // Purple
      case BadgeRarity.legendary:
        return const Color(0xFFF59E0B); // Gold
    }
  }

  void _showShareDialog(BadgeDefinition badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Display
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _getRarityColor(badge.rarity).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRarityColor(badge.rarity),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  badge.emoji,
                  style: const TextStyle(fontSize: 60),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              badge.name,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Share Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AchievementSharingService.shareBadge(badge);
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share to Social Media'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final text = AchievementSharingService.generateShareText(
                    type: 'badge',
                    title: 'I just unlocked "${badge.name}"',
                    description: badge.description,
                    emoji: badge.emoji,
                  );
                  await Clipboard.setData(ClipboardData(text: text));
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Achievement text copied!'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 20),
                label: const Text('Copy Text'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0052FF),
                  side: const BorderSide(color: Color(0xFF0052FF)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

