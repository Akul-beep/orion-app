import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/social_service.dart';

class FriendActivityFeed extends StatefulWidget {
  const FriendActivityFeed({Key? key}) : super(key: key);

  @override
  State<FriendActivityFeed> createState() => _FriendActivityFeedState();
}

class _FriendActivityFeedState extends State<FriendActivityFeed> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final activities = await DatabaseService.getFriendActivities();
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading friend activities: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No friend activity yet',
              style: GoogleFonts.poppins(
                color: const Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to see their achievements!',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9CA3AF),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildActivityItem(activity);
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['activity_type'] as String? ?? 'unknown';
    final data = activity['activity_data'] as Map<String, dynamic>? ?? {};
    final createdAt = activity['created_at'] != null
        ? DateTime.parse(activity['created_at'])
        : DateTime.now();

    IconData icon;
    String title;
    String subtitle;
    Color color;

    switch (type) {
      case 'achievement':
        icon = Icons.emoji_events;
        title = '${data['friendName'] ?? 'Friend'} unlocked ${data['badgeName'] ?? 'an achievement'}!';
        subtitle = _formatTimeAgo(createdAt);
        color = const Color(0xFFF59E0B);
        break;
      case 'level_up':
        icon = Icons.star;
        title = '${data['friendName'] ?? 'Friend'} reached Level ${data['level'] ?? '?'}!';
        subtitle = _formatTimeAgo(createdAt);
        color = const Color(0xFF6366F1);
        break;
      case 'trade':
        icon = Icons.trending_up;
        title = '${data['friendName'] ?? 'Friend'} made a trade!';
        subtitle = _formatTimeAgo(createdAt);
        color = const Color(0xFF10B981);
        break;
      case 'streak':
        icon = Icons.local_fire_department;
        title = '${data['friendName'] ?? 'Friend'} has a ${data['streak'] ?? 0}-day streak!';
        subtitle = _formatTimeAgo(createdAt);
        color = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.notifications;
        title = '${data['friendName'] ?? 'Friend'} was active';
        subtitle = _formatTimeAgo(createdAt);
        color = const Color(0xFF6B7280);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}






