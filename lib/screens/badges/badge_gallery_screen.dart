import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/gamification_service.dart';
import '../../models/badge_definition.dart';

class BadgeGalleryScreen extends StatelessWidget {
  const BadgeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge Gallery'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: Consumer<GamificationService>(
        builder: (context, gamification, child) {
          final unlockedBadgeIds = gamification.badges;
          final allBadges = BadgeDefinitions.allBadges;
          final unlockedCount = unlockedBadgeIds.length;
          
          return Column(
            children: [
              // Stats Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E3A8A),
                      const Color(0xFF3B82F6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '$unlockedCount / ${allBadges.length}',
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Badges Unlocked',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: unlockedCount / allBadges.length,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
              
              // Badge Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: allBadges.length,
                  itemBuilder: (context, index) {
                    final badge = allBadges[index];
                    final isUnlocked = unlockedBadgeIds.contains(badge.id);
                    
                    return _buildBadgeCard(badge, isUnlocked);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgeCard(BadgeDefinition badge, bool isUnlocked) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked 
              ? const Color(0xFF1E3A8A) 
              : Colors.grey[300]!,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked 
            ? [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? const Color(0xFF1E3A8A).withOpacity(0.1)
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isUnlocked ? badge.emoji : '🔒',
                style: TextStyle(
                  fontSize: isUnlocked ? 32 : 24,
                  color: isUnlocked ? null : Colors.grey[600],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Badge Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              badge.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isUnlocked 
                    ? const Color(0xFF111827)
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              badge.description,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isUnlocked 
                    ? Colors.grey[600]
                    : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}






