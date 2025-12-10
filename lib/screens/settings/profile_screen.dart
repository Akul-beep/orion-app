import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/gamification_service.dart';
import '../../design_system.dart';
import '../../models/badge_definition.dart';
import '../badges/badge_gallery_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String _selectedAvatar = '🎯';

  final List<String> _avatarOptions = [
    '🎯', '🚀', '💰', '📈', '📊', '🎓', '🏆', '🔥',
    '💎', '⭐', '🌟', '⚡', '🎮', '🎨', '🎵', '🎪'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await DatabaseService.loadUserProfile();
      setState(() {
        _userProfile = profile;
        _displayNameController.text = profile?['displayName'] ?? profile?['name'] ?? '';
        _bioController.text = profile?['bio'] ?? '';
        _selectedAvatar = profile?['avatar'] ?? '🎯';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      // CRITICAL FIX: Load existing profile first to preserve notification settings
      final existingProfile = await DatabaseService.loadUserProfile();
      
      // Create update map with only the fields we want to change
      // The saveUserProfileData function will merge this with existing data
      // Ensure all string fields are actually strings
      final displayName = _displayNameController.text.trim();
      final bio = _bioController.text.trim();
      
      final profileUpdate = <String, dynamic>{
        'displayName': displayName.isNotEmpty ? displayName : (existingProfile?['displayName'] ?? 'User'),
        'name': displayName.isNotEmpty ? displayName : (existingProfile?['name'] ?? 'User'),
        'bio': bio,
        'avatar': _selectedAvatar.toString(),
      };
      
      // Preserve notification settings if they exist (ensure correct types)
      if (existingProfile != null) {
        if (existingProfile['notificationsEnabled'] != null) {
          final notifEnabled = existingProfile['notificationsEnabled'];
          profileUpdate['notificationsEnabled'] = notifEnabled is bool 
              ? notifEnabled 
              : (notifEnabled == true || notifEnabled == 'true' || notifEnabled == 1);
        }
        if (existingProfile['reminderTime'] != null) {
          profileUpdate['reminderTime'] = existingProfile['reminderTime'].toString();
        }
      }

      await DatabaseService.saveUserProfileData(profileUpdate);

      // Update leaderboard with new display name
      // Use the displayName variable already declared above
      if (displayName.isNotEmpty) {
        try {
          final gamificationService = Provider.of<GamificationService>(context, listen: false);
          final userId = await DatabaseService.getOrCreateLocalUserId();
          
          // Ensure all values are the correct types
          await DatabaseService.updateLeaderboardEntry(
            userId: userId.toString(),
            displayName: displayName,
            xp: gamificationService.xp,
            streak: gamificationService.streak,
            level: gamificationService.level,
            badges: gamificationService.badges.length,
          );
        } catch (e) {
          print('⚠️ Error updating leaderboard: $e');
          // Don't fail profile save if leaderboard update fails
        }
      }

      // Reload profile from database to get the merged result
      final updatedProfile = await DatabaseService.loadUserProfile();
      
      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final gamificationService = Provider.of<GamificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _isEditing ? _showAvatarPicker : null,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1E3A8A),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _selectedAvatar,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Display Name
                  if (_isEditing)
                    TextField(
                      controller: _displayNameController,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Your Name',
                      ),
                    )
                  else
                    Text(
                      _displayNameController.text.isEmpty 
                          ? 'Your Name' 
                          : _displayNameController.text,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem('Level', '${gamificationService.level}'),
                      const SizedBox(width: 24),
                      _buildStatItem('XP', '${gamificationService.xp}'),
                      const SizedBox(width: 24),
                      _buildStatItem('Streak', '${gamificationService.streak}'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bio Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BIO',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    TextField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Tell us about yourself...',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    Text(
                      _bioController.text.isEmpty 
                          ? 'No bio yet. Tap edit to add one!' 
                          : _bioController.text,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF111827),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Achievements Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BADGES (${gamificationService.badges.length})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BadgeGalleryScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (gamificationService.badges.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No badges yet. Complete lessons and trades to earn badges!',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: gamificationService.unlockedBadgeDefinitions.map((badge) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF1E3A8A),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${badge.emoji} ${badge.name}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Avatar',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatarOptions.length,
              itemBuilder: (context, index) {
                final avatar = _avatarOptions[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedAvatar == avatar
                          ? const Color(0xFF1E3A8A).withOpacity(0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedAvatar == avatar
                            ? const Color(0xFF1E3A8A)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        avatar,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

