import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_manager.dart';
import '../../services/push_notification_service.dart';
import '../../services/web_notification_service.dart';
import '../../services/notification_scheduler.dart';
import '../../services/gamification_service.dart';
import '../../services/daily_goals_service.dart';
import '../../design_system.dart';
import '../../utils/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
import '../auth_wrapper.dart';
import '../help/help_faq_screen.dart';
import '../feedback/feedback_board_screen.dart';
import 'profile_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _streakRemindersEnabled = true;
  bool _marketNewsEnabled = true;
  bool _learningRemindersEnabled = true;
  String _reminderTime = '20:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't reload here - it causes infinite loops
    // Settings will reload when screen is opened via initState
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('📥 ========== LOADING SETTINGS ==========');
      
      // Wait a bit to ensure Supabase auth is ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check authentication status
      final supabase = Supabase.instance.client;
      final isAuthenticated = supabase.auth.currentUser != null;
      final userId = supabase.auth.currentUser?.id;
      
      print('   Authentication check:');
      print('   - Is authenticated: $isAuthenticated');
      print('   - User ID: $userId');
      
      // Load profile from database
      print('   Calling DatabaseService.loadUserProfile...');
      final profile = await DatabaseService.loadUserProfile();
      
      print('   Profile loaded: ${profile != null ? "YES" : "NO"}');
      if (profile != null) {
        print('   Profile keys: ${profile.keys.toList()}');
        print('   Notifications enabled: ${profile['notificationsEnabled']}');
        print('   Reminder time: ${profile['reminderTime']}');
      }
      
      // Load notification preferences from PushNotificationService (before setState)
      // For web: ALWAYS check ACTUAL browser permission status first
      bool notificationsEnabled = false;
      if (kIsWeb) {
        final webNotification = WebNotificationService();
        final browserPermission = webNotification.getPermissionStatus();
        // Only enable if browser permission is actually granted
        notificationsEnabled = browserPermission == 'granted';
        print('   Web browser permission: $browserPermission');
        print('   Notifications enabled (from browser): $notificationsEnabled');
        
        // If browser permission is granted but not scheduled, schedule them
        if (notificationsEnabled) {
          final gamification = Provider.of<GamificationService>(context, listen: false);
          final dailyGoals = Provider.of<DailyGoalsService>(context, listen: false);
          await webNotification.scheduleDailyNotifications(
            gamification: gamification,
            dailyGoals: dailyGoals,
          );
        }
      } else {
        notificationsEnabled = await PushNotificationService().areNotificationsEnabled();
      }
      
      final streakRemindersEnabled = await PushNotificationService().isStreakRemindersEnabled();
      final marketNewsEnabled = await PushNotificationService().isMarketNewsEnabled();
      final learningRemindersEnabled = await PushNotificationService().isLearningRemindersEnabled();
      final preferredTime = await PushNotificationService().getPreferredNotificationTime();
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          // Only use defaults if profile is null AND we're not authenticated
          // If authenticated but profile is null, use defaults but log it
          // Set notification preferences from PushNotificationService (which syncs from database)
          // BUT for web, ALWAYS use actual browser permission status (it's the source of truth)
          if (kIsWeb) {
            // For web, browser permission is the source of truth
            _notificationsEnabled = notificationsEnabled;
          } else {
            // For mobile, use app preference
            _notificationsEnabled = notificationsEnabled;
          }
          _streakRemindersEnabled = streakRemindersEnabled;
          _marketNewsEnabled = marketNewsEnabled;
          _learningRemindersEnabled = learningRemindersEnabled;
          
          // Use preferred time from service (synced from database) or profile, or default
          if (preferredTime != null) {
            _reminderTime = '${preferredTime.hour.toString().padLeft(2, '0')}:${preferredTime.minute.toString().padLeft(2, '0')}';
          } else if (profile?['reminderTime'] != null) {
            _reminderTime = profile!['reminderTime'].toString();
          } else {
            _reminderTime = '20:00';
          }
          
          // Also load from profile if available (in case database has different values)
          // BUT for web, browser permission ALWAYS takes precedence - don't override
          if (profile != null && !kIsWeb) {
            if (profile['notificationsEnabled'] != null) {
              final enabled = profile['notificationsEnabled'] == true || 
                             profile['notificationsEnabled'] == 'true' ||
                             profile['notificationsEnabled'] == 1;
              _notificationsEnabled = enabled;
            }
            if (profile['streakRemindersEnabled'] != null) {
              final enabled = profile['streakRemindersEnabled'] == true || 
                             profile['streakRemindersEnabled'] == 'true' ||
                             profile['streakRemindersEnabled'] == 1;
              _streakRemindersEnabled = enabled;
            }
            if (profile['marketNewsEnabled'] != null) {
              final enabled = profile['marketNewsEnabled'] == true || 
                             profile['marketNewsEnabled'] == 'true' ||
                             profile['marketNewsEnabled'] == 1;
              _marketNewsEnabled = enabled;
            }
            if (profile['learningRemindersEnabled'] != null) {
              final enabled = profile['learningRemindersEnabled'] == true || 
                             profile['learningRemindersEnabled'] == 'true' ||
                             profile['learningRemindersEnabled'] == 1;
              _learningRemindersEnabled = enabled;
            }
          }
          
          if (profile != null) {
            print('✅ Settings loaded from database');
            print('   Set reminder time to: $_reminderTime');
          } else {
            if (isAuthenticated) {
              print('⚠️ Authenticated but no profile found - using defaults');
              print('   This might mean the profile hasn\'t been created yet');
            } else {
              print('⚠️ Not authenticated - using defaults');
            }
          }
          _isLoading = false;
        });
      }
      
      print('📥 ========== LOAD COMPLETE ==========');
      print('   Final reminder time: $_reminderTime');
      print('   Final notifications: $_notificationsEnabled');
    } catch (e, stackTrace) {
      print('❌ ========== ERROR LOADING SETTINGS ==========');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      print('❌ ===========================================');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Use defaults on error
          _notificationsEnabled = true;
          _reminderTime = '20:00';
        });
      }
    }
  }

  Future<String> _getAppVersion() async {
    try {
      // Try to get version from package_info_plus if available
      // For now, return static version
      return '1.0.0';
    } catch (e) {
      return '1.0.0';
    }
  }

  Future<void> _saveNotificationSettings() async {
    if (!mounted) return;
    try {
      print('💾 ========== SAVING NOTIFICATION SETTINGS ==========');
      print('   Notifications enabled: $_notificationsEnabled');
      print('   Reminder time: $_reminderTime');

      // Create update map with only the fields we want to change
      // The saveUserProfileData function will merge this with existing data
      final profileUpdate = {
        'notificationsEnabled': _notificationsEnabled,
        'reminderTime': _reminderTime,
        'streakRemindersEnabled': _streakRemindersEnabled,
        'marketNewsEnabled': _marketNewsEnabled,
        'learningRemindersEnabled': _learningRemindersEnabled,
      };
      
      print('   Profile update keys: ${profileUpdate.keys.toList()}');
      
      // Check authentication status
      final supabase = Supabase.instance.client;
      final isAuthenticated = supabase.auth.currentUser != null;
      final userId = supabase.auth.currentUser?.id;
      
      print('   Authentication check:');
      print('   - Is authenticated: $isAuthenticated');
      print('   - User ID: $userId');

      // Save to database (Supabase + local)
      // The saveUserProfileData function will merge this with existing profile
      print('   Calling DatabaseService.saveUserProfileData...');
      await DatabaseService.saveUserProfileData(profileUpdate);
      print('   DatabaseService.saveUserProfileData completed');
      // Update local state immediately so UI feels instant
      if (mounted) {
        setState(() {
          _userProfile = {
            ...?_userProfile,
            ...profileUpdate,
          };
        });
      }
      
      // Update push notification service with new settings
      // These methods will sync to database automatically
      await PushNotificationService().setNotificationsEnabled(_notificationsEnabled);
      await PushNotificationService().setStreakRemindersEnabled(_streakRemindersEnabled);
      await PushNotificationService().setMarketNewsEnabled(_marketNewsEnabled);
      await PushNotificationService().setLearningRemindersEnabled(_learningRemindersEnabled);
      
      final timeParts = _reminderTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      await PushNotificationService().setPreferredNotificationTime(TimeOfDay(hour: hour, minute: minute));
      
      // Also sync settings to database and reschedule notifications in the background
      // so we don't block the UI with long-running work
      // ignore: unawaited_futures
      PushNotificationService()
          .syncSettingsToDatabase()
          .then((_) => NotificationScheduler().rescheduleAllNotifications(context))
          .catchError((e) {
        print('⚠️ Error during background notification reschedule: $e');
      });
      
      print('📅 Notification preferences saved; background reschedule started');
      
      // Show success message (no blocking loader)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_notificationsEnabled 
                ? '✅ Settings saved! Daily reminder at $_reminderTime'
                : '✅ Notifications disabled'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      print('💾 ========== SAVE COMPLETE ==========');
    } catch (e, stackTrace) {
      print('❌ ========== ERROR SAVING SETTINGS ==========');
      print('   Error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      print('❌ ===========================================');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving settings: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveNotificationSettings(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      try {
        // Sign out from Supabase using AuthService for consistency
        await AuthService.signOut();
        
        // Wait and verify session is cleared - keep checking until it's actually gone
        int attempts = 0;
        while (Supabase.instance.client.auth.currentSession != null && attempts < 5) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (Supabase.instance.client.auth.currentSession != null) {
            print('⚠️ Session still exists, attempting sign out again (attempt ${attempts + 1})...');
            await Supabase.instance.client.auth.signOut();
          }
          attempts++;
        }
        
        // Final verification
        final finalSession = Supabase.instance.client.auth.currentSession;
        if (finalSession != null) {
          print('❌ WARNING: Session still exists after multiple sign out attempts!');
        } else {
          print('✅ Session confirmed cleared');
        }
        
        if (mounted) {
          // Close loading dialog
          Navigator.of(context).pop();
          
          // Navigate directly to LoginScreen and clear entire stack
          // This is the most reliable way to ensure logout works
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
            (route) => false, // Remove ALL previous routes
          );
        }
      } catch (e) {
        print('Error logging out: $e');
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSettings();
            },
            tooltip: 'Refresh settings',
          ),
        ],
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: ListView(
        children: [
          // Profile Section
          _buildSection(
            title: 'Profile',
            children: [
              _buildSettingsTile(
                leading: const Icon(Icons.person_outline, color: Color(0xFF1E3A8A)),
                title: 'Edit Profile',
                subtitle: 'Update your profile information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),

          // Notifications Section
          _buildSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined, color: Color(0xFF1E3A8A)),
                title: const Text('Enable Notifications'),
                subtitle: const Text('Get reminders and updates'),
                value: _notificationsEnabled,
                onChanged: (value) async {
                  if (value) {
                    // User wants to enable - ALWAYS request permission first for web
                    bool permissionGranted = false;
                    
                    if (kIsWeb) {
                      final webNotification = WebNotificationService();
                      
                      // Check if browser supports notifications
                      if (!webNotification.isSupported()) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your browser does not support notifications'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        return; // Don't enable if not supported
                      }
                      
                      // ALWAYS check current permission status FIRST
                      final currentPermission = webNotification.getPermissionStatus();
                      
                      if (currentPermission == 'granted') {
                        // Already granted - schedule notifications and enable
                        permissionGranted = true;
                      } else if (currentPermission == 'denied') {
                        // Previously denied - show message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications were previously blocked. Please enable them in your browser settings.'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                        // Don't update toggle - it should stay OFF
                        return;
                      } else {
                        // Permission is 'default' - REQUEST IT NOW
                        // This will show the browser permission dialog immediately
                        permissionGranted = await webNotification.requestPermission();
                        
                        if (!permissionGranted) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Permission denied. Please allow notifications to enable them.'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                          // Don't update toggle - it should stay OFF
                          return;
                        }
                      }
                      
                      // Permission granted - schedule notifications
                      if (permissionGranted) {
                        final gamification = Provider.of<GamificationService>(context, listen: false);
                        final dailyGoals = Provider.of<DailyGoalsService>(context, listen: false);
                        await webNotification.scheduleDailyNotifications(
                          gamification: gamification,
                          dailyGoals: dailyGoals,
                        );
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Notifications enabled!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        
                        // Update state to reflect granted permission
                        setState(() {
                          _notificationsEnabled = true;
                        });
                      }
                    } else {
                      // Mobile: request permissions
                      permissionGranted = await PushNotificationService().requestPermissions();
                      if (!permissionGranted) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enable notifications in your device settings'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        return;
                      }
                      
                      // For mobile, update state after permission granted
                      setState(() {
                        _notificationsEnabled = true;
                      });
                    }
                    
                    // Save settings only after permission is granted
                    if (permissionGranted) {
                      await PushNotificationService().setNotificationsEnabled(true);
                      _saveNotificationSettings();
                    }
                  } else {
                    // User wants to disable - just disable
                    setState(() {
                      _notificationsEnabled = false;
                    });
                    await PushNotificationService().setNotificationsEnabled(false);
                    _saveNotificationSettings();
                  }
                },
              ),
              if (_notificationsEnabled) ...[
                SwitchListTile(
                  secondary: const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B)),
                  title: const Text('Streak Reminders'),
                  subtitle: const Text('Get notified to maintain your learning streak'),
                  value: _streakRemindersEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _streakRemindersEnabled = value;
                    });
                    await PushNotificationService().setStreakRemindersEnabled(value);
                    _saveNotificationSettings();
                    await NotificationScheduler().rescheduleAllNotifications(context);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.trending_up, color: Color(0xFF059669)),
                  title: const Text('Market News'),
                  subtitle: const Text('Get notified about news for your portfolio stocks'),
                  value: _marketNewsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _marketNewsEnabled = value;
                    });
                    await PushNotificationService().setMarketNewsEnabled(value);
                    _saveNotificationSettings();
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.school, color: Color(0xFF58CC02)),
                  title: const Text('Learning Reminders'),
                  subtitle: const Text('Daily reminders to complete lessons'),
                  value: _learningRemindersEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _learningRemindersEnabled = value;
                    });
                    await PushNotificationService().setLearningRemindersEnabled(value);
                    _saveNotificationSettings();
                    await NotificationScheduler().rescheduleAllNotifications(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Color(0xFF1E3A8A)),
                  title: const Text('Preferred Notification Time'),
                  subtitle: Text(_reminderTime),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.parse(_reminderTime.split(':')[0]),
                        minute: int.parse(_reminderTime.split(':')[1]),
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _reminderTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      });
                      await PushNotificationService().setPreferredNotificationTime(picked);
                      await NotificationScheduler().rescheduleAllNotifications(context);
                      _saveNotificationSettings();
                    }
                  },
                ),
              ],
            ],
          ),

          // Account Section
          _buildSection(
            title: 'Account',
            children: [
              _buildSettingsTile(
                leading: const Icon(Icons.lock_outline, color: Color(0xFF1E3A8A)),
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => _showPasswordResetDialog(context),
              ),
              _buildSettingsTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                titleColor: Colors.red,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),

          // App Section
          _buildSection(
            title: 'App',
            children: [
              // iOS App Download (show on web or if not on iOS)
              if (kIsWeb || (!kIsWeb && !Platform.isIOS)) ...[
                _buildSettingsTile(
                  leading: const Icon(Icons.phone_iphone, color: Color(0xFF1E3A8A)),
                  title: 'Download iOS App',
                  subtitle: 'Get the native iOS app from the App Store',
                  onTap: () => _openIOSAppStore(),
                ),
              ],
              _buildSettingsTile(
                leading: const Icon(Icons.feedback_outlined, color: Color(0xFF1E3A8A)),
                title: 'Feedback Board',
                subtitle: 'Submit and vote on feature requests',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedbackBoardScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                leading: const Icon(Icons.help_outline, color: Color(0xFF1E3A8A)),
                title: 'Help & FAQ',
                subtitle: 'Get help and answers',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpFaqScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                leading: const Icon(Icons.description_outlined, color: Color(0xFF1E3A8A)),
                title: 'Terms of Service',
                subtitle: 'Read our terms and conditions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF1E3A8A)),
                title: 'Privacy Policy',
                subtitle: 'How we protect your data',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFF1E3A8A)),
                title: const Text('Version'),
                subtitle: FutureBuilder<String>(
                  future: _getAppVersion(),
                  builder: (context, snapshot) {
                    return Text(snapshot.data ?? '1.0.0');
                  },
                ),
              ),
            ],
          ),

          // Logout Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text(
              'This action will permanently:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text('• Delete all your portfolio data', style: TextStyle(fontSize: 14)),
            Text('• Delete all your trade history', style: TextStyle(fontSize: 14)),
            Text('• Delete all your progress and achievements', style: TextStyle(fontSize: 14)),
            Text('• Delete your profile information', style: TextStyle(fontSize: 14)),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      try {
        await AuthService.deleteAccount();

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to login screen
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        print('Error deleting account: $e');
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showPasswordResetDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email associated with your account. Cannot reset password.'),
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We\'ll send a password reset link to:\n${user!.email}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Check your email and follow the instructions to reset your password.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          user!.email!,
          redirectTo: 'com.orion.app://reset-password',
        );
        
        if (context.mounted) {
          ErrorHandler.showSuccess(
            context,
            'Password reset email sent! Check your inbox.',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(
            context,
            ErrorHandler.getErrorMessage(e),
          );
        }
      }
    }
  }

  Future<void> _openAppSettings() async {
    await PushNotificationService().openAppSettings();
  }

  /// Open iOS App Store to download the app
  Future<void> _openIOSAppStore() async {
    try {
      const String appStoreId = '6755752931'; // Orion Finance App Store ID
      
      // Try to open App Store app directly (works on iOS devices)
      final String appStoreUrl = 'itms-apps://apps.apple.com/app/id$appStoreId';
      final Uri appStoreUri = Uri.parse(appStoreUrl);
      
      if (await canLaunchUrl(appStoreUri)) {
        await launchUrl(appStoreUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web App Store link
        final String webAppStoreUrl = 'https://apps.apple.com/app/id$appStoreId';
        final Uri webAppStoreUri = Uri.parse(webAppStoreUrl);
        if (await canLaunchUrl(webAppStoreUri)) {
          await launchUrl(webAppStoreUri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open App Store. Please search for "Orion StockSense" in the App Store.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error opening App Store: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening App Store: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSettingsTile({
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? const Color(0xFF111827),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

