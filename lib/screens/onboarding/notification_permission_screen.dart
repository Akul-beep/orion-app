import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/push_notification_service.dart';
import '../../services/web_notification_service.dart';
import '../../services/gamification_service.dart';
import '../../services/daily_goals_service.dart';
import '../../design_system.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

/// Notification Permission Screen - Shown after onboarding (like Duolingo)
/// Explains why notifications are important before requesting permission
class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends State<NotificationPermissionScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      bool granted = false;
      
      if (kIsWeb) {
        // Web: Use WebNotificationService
        final webNotification = WebNotificationService();
        
        // Check if browser supports notifications
        if (!webNotification.isSupported()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your browser does not support notifications'),
              backgroundColor: Colors.orange,
            ),
          );
          granted = false;
        } else {
          granted = await webNotification.requestPermission();
          
          if (granted) {
            // Schedule daily notifications
            final gamification = Provider.of<GamificationService>(context, listen: false);
            final dailyGoals = Provider.of<DailyGoalsService>(context, listen: false);
            await webNotification.scheduleDailyNotifications(
              gamification: gamification,
              dailyGoals: dailyGoals,
            );
          }
        }
      } else {
        // Mobile: Use PushNotificationService
        granted = await PushNotificationService().requestPermissions();
      }
      
      if (mounted) {
        if (granted) {
          // Permissions granted - navigate to main app
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          // Permissions denied - show explanation screen (only for mobile)
          if (!kIsWeb) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const NotificationPermissionDeniedScreen(),
            ),
          );
          } else {
            // For web, just continue to app
            Navigator.of(context).pushReplacementNamed('/main');
          }
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      if (mounted) {
        // On error, still allow user to continue
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _skipForNow() async {
    // User can skip - navigate to main app
    // They can enable notifications later in settings
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Ory Character Icon (placeholder - replace with actual image)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      '🦉',
                      style: TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  'Stay on Track with Ory',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'Get friendly reminders to maintain your streak and never miss a learning opportunity.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Benefits list
                _buildBenefit(
                  icon: Icons.local_fire_department,
                  title: 'Maintain Your Streak',
                  description: 'Get reminders to keep your learning streak alive',
                ),
                const SizedBox(height: 20),
                _buildBenefit(
                  icon: Icons.notifications_active,
                  title: 'Daily Learning Reminders',
                  description: 'Never miss a chance to learn and earn XP',
                ),
                const SizedBox(height: 20),
                _buildBenefit(
                  icon: Icons.trending_up,
                  title: 'Market News Updates',
                  description: 'Stay informed about your portfolio stocks',
                ),
                
                const Spacer(),
                
                // Enable Notifications Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Enable Notifications',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Skip button
                TextButton(
                  onPressed: _isRequesting ? null : _skipForNow,
                  child: Text(
                    'Not Now',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF0052FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0052FF),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Screen shown when user denies notification permissions
/// Explains how to enable them later (like Duolingo)
class NotificationPermissionDeniedScreen extends StatefulWidget {
  const NotificationPermissionDeniedScreen({super.key});

  @override
  State<NotificationPermissionDeniedScreen> createState() => _NotificationPermissionDeniedScreenState();
}

class _NotificationPermissionDeniedScreenState extends State<NotificationPermissionDeniedScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Concerned Ory Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      '🦉',
                      style: TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  'Notifications Disabled',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'Ory can\'t remind you to maintain your streak without notifications. You can enable them anytime in Settings.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // How to enable instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to Enable Notifications:',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInstruction(
                        '1',
                        'Go to iPhone Settings',
                      ),
                      const SizedBox(height: 12),
                      _buildInstruction(
                        '2',
                        'Tap "Notifications"',
                      ),
                      const SizedBox(height: 12),
                      _buildInstruction(
                        '3',
                        'Find "Orion" and enable notifications',
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/main');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue to App',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Settings button
                TextButton(
                  onPressed: () async {
                    // Try to open app settings
                    try {
                      if (Platform.isIOS) {
                        final url = Uri.parse('app-settings:');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      } else if (Platform.isAndroid) {
                        final url = Uri.parse('package:com.orion.app');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    } catch (e) {
                      print('⚠️ Could not open settings: $e');
                    }
                    // Still navigate to main app
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/main');
                    }
                  },
                  child: Text(
                    'Open Settings',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF0052FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF0052FF).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0052FF),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

