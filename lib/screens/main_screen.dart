import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'professional_dashboard.dart';
import 'professional_stocks_screen.dart';
import 'learning/duolingo_home_screen.dart';
import 'professional_ai_coach_screen.dart';
import '../widgets/learning_popup_widget.dart';
import '../services/user_progress_service.dart';
import '../services/database_service.dart';
import '../services/notification_manager.dart';
import '../utils/responsive_layout.dart';
import 'settings/settings_screen.dart';
import 'feedback/feedback_board_screen.dart';
import 'notification_center_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  static const List<Widget> _widgetOptions = <Widget>[
    ProfessionalDashboard(),
    ProfessionalStocksScreen(),
    DuolingoHomeScreen(),
    ProfessionalAICoachScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // Track initial screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'MainScreen',
        screenType: 'main',
        metadata: {'tab_index': _selectedIndex},
      );
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final newIndex = _tabController.index;
      if (newIndex != _selectedIndex) {
        final screenNames = ['ProfessionalDashboard', 'ProfessionalStocksScreen', 'DuolingoHomeScreen', 'ProfessionalAICoachScreen'];
        UserProgressService().trackNavigation(
          fromScreen: screenNames[_selectedIndex],
          toScreen: screenNames[newIndex],
          navigationMethod: 'tab_switch',
          navigationData: {'from_index': _selectedIndex, 'to_index': newIndex},
        );
        setState(() {
          _selectedIndex = newIndex;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      final screenNames = ['ProfessionalDashboard', 'ProfessionalStocksScreen', 'DuolingoHomeScreen', 'ProfessionalAICoachScreen'];
      UserProgressService().trackNavigation(
        fromScreen: screenNames[_selectedIndex],
        toScreen: screenNames[index],
        navigationMethod: 'tab_switch',
        navigationData: {'from_index': _selectedIndex, 'to_index': index},
      );
      setState(() {
        _selectedIndex = index;
      });
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web layout: sidebar navigation
      return Scaffold(
        body: Row(
          children: [
            // Sidebar Navigation
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Logo and Orion name at top
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/logo/app_logo.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.trending_up,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Orion',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Navigation Items
                    Expanded(
                      child: Column(
                        children: [
                          _buildNavItem(context, 0, Icons.home_outlined, Icons.home, 'Home'),
                          const SizedBox(height: 8),
                          _buildNavItem(context, 1, Icons.trending_up_outlined, Icons.trending_up, 'Trading'),
                          const SizedBox(height: 8),
                          _buildNavItem(context, 2, Icons.school_outlined, Icons.school, 'Learn'),
                          const SizedBox(height: 8),
                          _buildNavItem(context, 3, Icons.psychology_outlined, Icons.psychology, 'AI Coach'),
                        ],
                      ),
                    ),
                    // Notifications and Feedback Board buttons above user account
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Consumer<NotificationManager>(
                              builder: (context, notifications, child) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Center(
                                          child: const Icon(
                                            Icons.notifications_outlined,
                                            color: Color(0xFF6B7280),
                                            size: 18,
                                          ),
                                        ),
                                        if (notifications.unreadCount > 0)
                                          Positioned(
                                            right: 8,
                                            top: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEF4444),
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 12,
                                                minHeight: 12,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  notifications.unreadCount > 9 ? '9+' : '${notifications.unreadCount}',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FeedbackBoardScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.feedback_outlined,
                                    color: Color(0xFF6B7280),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // iOS App Download (for web users)
                    if (kIsWeb) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: _openIOSAppStore,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone_iphone,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Get iOS App',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Download from App Store',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // User Profile at bottom
                    FutureBuilder<Map<String, dynamic>?>(
                      future: DatabaseService.loadUserProfile(),
                      builder: (context, snapshot) {
                        final userName = snapshot.data?['displayName'] ?? snapshot.data?['name'] ?? 'User';
                        final userEmail = snapshot.data?['email'] ?? '';
                        final photoURL = snapshot.data?['photoURL'];
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: photoURL != null && photoURL.toString().isNotEmpty
                                    ? NetworkImage(photoURL.toString())
                                    : null,
                                backgroundColor: photoURL == null || photoURL.toString().isEmpty
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                child: photoURL == null || photoURL.toString().isEmpty
                                    ? Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      userName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111827),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (userEmail.isNotEmpty)
                                      Text(
                                        userEmail,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF6B7280),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.settings_outlined,
                                    color: Color(0xFF6B7280),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Main Content
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: Stack(
                  children: [
                    IndexedStack(
                      index: _selectedIndex,
                      children: _widgetOptions.map((widget) {
                        if (widget is ProfessionalDashboard) {
                          return ProfessionalDashboard(tabController: _tabController);
                        }
                        return widget;
                      }).toList(),
                    ),
                    // Learning popup overlay
                    const LearningPopupWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout: bottom navigation
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions.map((widget) {
              if (widget is ProfessionalDashboard) {
                return ProfessionalDashboard(tabController: _tabController);
              }
              return widget;
            }).toList(),
          ),
          // Learning popup overlay
          const LearningPopupWidget(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.trending_up_outlined),
                activeIcon: Icon(Icons.trending_up),
                label: 'Trading',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'Learn',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology_outlined),
                activeIcon: Icon(Icons.psychology),
                label: 'AI Coach',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF1E3A8A),
            unselectedItemColor: const Color(0xFF9CA3AF),
            onTap: _onItemTapped,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
            backgroundColor: Colors.white,
            elevation: 0,
            iconSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, IconData activeIcon, String label, VoidCallback onTap, bool isSelected) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Open iOS App Store to download the app
  Future<void> _openIOSAppStore() async {
    try {
      const String appStoreId = '6755752931'; // Orion Finance App Store ID
      
      if (kIsWeb) {
        // For web, open in new tab
        final String webAppStoreUrl = 'https://apps.apple.com/app/id$appStoreId';
        final Uri webAppStoreUri = Uri.parse(webAppStoreUrl);
        if (await canLaunchUrl(webAppStoreUri)) {
          await launchUrl(webAppStoreUri, mode: LaunchMode.externalApplication);
        }
      } else {
        // For mobile, try to open App Store app
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
}

