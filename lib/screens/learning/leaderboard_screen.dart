import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../../services/gamification_service.dart';
import '../../services/user_progress_service.dart';
import '../../services/paper_trading_service.dart';
import '../../utils/responsive_layout.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _leaderboard = [];
  String _selectedTab = 'XP';
  bool _isLoading = true;
  Map<String, dynamic>? _currentUserEntry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    // Ensure portfolio is loaded and updated before loading leaderboard
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Refresh portfolio value to ensure it's current
        final paperTrading = Provider.of<PaperTradingService>(context, listen: false);
        await paperTrading.calculatePortfolioValue();
        
        // Update leaderboard with current portfolio value
        final gamification = Provider.of<GamificationService>(context, listen: false);
        await gamification.updateLeaderboard(portfolioValue: paperTrading.totalValue);
      } catch (e) {
        print('⚠️ Could not refresh portfolio before loading leaderboard: $e');
      }
      
      // Now load the leaderboard
      _loadLeaderboard();
      
      // Track screen visit
      UserProgressService().trackScreenVisit(
        screenName: 'LeaderboardScreen',
        screenType: 'main',
        metadata: {'section': 'leaderboard'},
      );
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Map UI tab to database sort field
      String sortBy = _selectedTab.toLowerCase();
      if (_selectedTab == 'Portfolio') {
        sortBy = 'portfolio';
      }
      
      // Load leaderboard from database (with caching unless force refresh)
      final leaderboard = await DatabaseService.getLeaderboard(
        sortBy: sortBy,
        limit: 50,
        forceRefresh: forceRefresh,
      );
      
      // Get current user entry
      final userEntry = await DatabaseService.getUserLeaderboardEntry();
      
      // If no data, create default entry for current user
      if (userEntry == null || userEntry.isEmpty) {
        final gamification = Provider.of<GamificationService>(context, listen: false);
        // Get user's display name from profile or auth
        final profile = await DatabaseService.loadUserProfile();
        String displayName = 'User';
        
        // Try to get name from Supabase auth first
        try {
          final supabase = Supabase.instance.client;
          final user = supabase.auth.currentUser;
          if (user != null) {
            // Try email username or metadata
            displayName = user.userMetadata?['display_name'] ?? 
                        user.userMetadata?['name'] ??
                        (user.email != null ? user.email!.split('@')[0] : 'User');
          }
        } catch (e) {
          print('Could not get name from auth: $e');
        }
        
        // Fallback to profile
        if (displayName == 'User') {
          displayName = profile?['displayName'] ?? 
                       profile?['name'] ?? 
                       'User';
        }
        
        // Get portfolio value - ensure it's never null or 0 (default to $10,000 starting balance)
        double portfolioValue = 10000.0; // Default starting balance
        try {
          final paperTrading = Provider.of<PaperTradingService>(context, listen: false);
          final value = paperTrading.totalValue;
          // Only use if it's a valid positive value
          if (value != null && value > 0) {
            portfolioValue = value;
          } else {
            print('⚠️ Portfolio value is null or 0, using default \$10,000');
          }
        } catch (e) {
          print('⚠️ Could not get portfolio value: $e, using default \$10,000');
        }
        
        await DatabaseService.updateLeaderboardEntry(
          userId: await DatabaseService.getOrCreateLocalUserId(),
          displayName: displayName,
          xp: gamification.totalXP,
          streak: gamification.streak,
          level: gamification.level,
          badges: gamification.badges.length,
          portfolioValue: portfolioValue,
        );
        _currentUserEntry = {
          'userId': await DatabaseService.getOrCreateLocalUserId(),
          'displayName': displayName,
          'xp': gamification.totalXP,
          'streak': gamification.streak,
          'level': gamification.level,
          'badges': gamification.badges.length,
          'avatar': profile?['avatar'] ?? '🎯',
          'portfolio_value': portfolioValue,
          'portfolioValue': portfolioValue,
          'isCurrentUser': true,
        };
      } else {
        _currentUserEntry = userEntry;
        _currentUserEntry!['isCurrentUser'] = true;
        
        // Always update portfolio value from PaperTradingService to ensure it's current
        // Ensure it's never null or 0 (default to $10,000 starting balance)
        double portfolioValue = 10000.0; // Default starting balance
        try {
          final paperTrading = Provider.of<PaperTradingService>(context, listen: false);
          final value = paperTrading.totalValue;
          // Only use if it's a valid positive value
          if (value != null && value > 0) {
            portfolioValue = value;
          } else {
            print('⚠️ Portfolio value is null or 0, using default \$10,000');
          }
          // Update the entry with current portfolio value
          _currentUserEntry!['portfolio_value'] = portfolioValue;
          _currentUserEntry!['portfolioValue'] = portfolioValue;
        } catch (e) {
          print('⚠️ Could not get portfolio value: $e, using default \$10,000');
        }
        
        // Ensure displayName is set - update if missing
        if (_currentUserEntry!['displayName'] == null || _currentUserEntry!['displayName'] == 'User') {
          String displayName = 'User';
          
          // Try to get name from Supabase auth first
          try {
            final supabase = Supabase.instance.client;
            final user = supabase.auth.currentUser;
            if (user != null) {
              displayName = user.userMetadata?['display_name'] ?? 
                          user.userMetadata?['name'] ??
                          (user.email != null ? user.email!.split('@')[0] : 'User');
            }
          } catch (e) {
            print('Could not get name from auth: $e');
          }
          
          // Fallback to profile
          if (displayName == 'User') {
            final profile = await DatabaseService.loadUserProfile();
            displayName = profile?['displayName'] ?? 
                         profile?['name'] ?? 
                         'User';
          }
          
          // Update the entry and database
          _currentUserEntry!['displayName'] = displayName;
          await DatabaseService.updateLeaderboardEntry(
            userId: _currentUserEntry!['userId'],
            displayName: displayName,
            xp: _currentUserEntry!['xp'] ?? 0,
            streak: _currentUserEntry!['streak'] ?? 0,
            level: _currentUserEntry!['level'] ?? 1,
            badges: _currentUserEntry!['badges'] ?? 0,
            portfolioValue: portfolioValue,
          );
        } else if (portfolioValue != null) {
          // Update portfolio value in database even if displayName is fine
          await DatabaseService.updateLeaderboardEntry(
            userId: _currentUserEntry!['userId'],
            displayName: _currentUserEntry!['displayName'] ?? 'User',
            xp: _currentUserEntry!['xp'] ?? 0,
            streak: _currentUserEntry!['streak'] ?? 0,
            level: _currentUserEntry!['level'] ?? 1,
            badges: _currentUserEntry!['badges'] ?? 0,
            portfolioValue: portfolioValue,
          );
        }
      }
      
      // Use real leaderboard data (even if empty - no fake data!)
      _leaderboard = leaderboard;
      
      // Mark current user in leaderboard
      if (_currentUserEntry != null) {
        final currentUserId = _currentUserEntry!['userId'] ?? _currentUserEntry!['user_id'];
        for (var entry in _leaderboard) {
          final entryUserId = entry['userId'] ?? entry['user_id'];
          if (entryUserId == currentUserId) {
            entry['isCurrentUser'] = true;
            // Update entry with current user data if needed
            entry['displayName'] = _currentUserEntry!['displayName'] ?? entry['displayName'];
            entry['display_name'] = _currentUserEntry!['displayName'] ?? entry['display_name'];
          }
        }
        
        // If current user not in top 50, add them at the end
        if (!_leaderboard.any((e) => e['isCurrentUser'] == true)) {
          _leaderboard.add(_currentUserEntry!);
        }
      }
      
      print('✅ Loaded ${_leaderboard.length} real leaderboard entries');
    } catch (e, stackTrace) {
      print('❌ Error loading leaderboard: $e');
      print('Stack trace: $stackTrace');
      // Don't generate fake data - show empty state instead
      _leaderboard = [];
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _generateSampleLeaderboard() {
    // Generate 20 sample users for demonstration
    final names = [
      'Alex', 'Jordan', 'Sam', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Quinn',
      'Avery', 'Blake', 'Cameron', 'Dakota', 'Emery', 'Finley', 'Harper',
      'Hayden', 'Jamie', 'Kendall', 'Logan', 'Parker'
    ];
    
    return List.generate(20, (index) {
      final baseValue = 10000 - (index * 400);
      return {
        'userId': 'user_$index',
        'displayName': names[index % names.length],
        'xp': baseValue + (index * 50),
        'streak': 30 - index,
        'level': 10 - (index ~/ 3),
        'badges': 5 - (index ~/ 4),
        'avatar': '👤',
        'isCurrentUser': false,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh by clearing cache and reloading
          await _loadLeaderboard(forceRefresh: true);
        },
        color: const Color(0xFF0052FF),
        child: CustomScrollView(
        slivers: [
          // Coinbase-style Header
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
              onPressed: () => Navigator.pop(context),
            ),
            title: ResponsiveLayout(
              maxWidth: kIsWeb ? 1000 : double.infinity,
              padding: EdgeInsets.zero,
              child: Text(
              'Leaderboard',
              style: GoogleFonts.inter(
                color: const Color(0xFF111827),
                  fontSize: kIsWeb ? 24 : 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                ),
              ),
            ),
            centerTitle: false,
          ),
          
          // Tab Bar
          SliverToBoxAdapter(
            child: ResponsiveLayout(
              maxWidth: kIsWeb ? 1000 : double.infinity,
              padding: EdgeInsets.zero,
            child: Padding(
                padding: EdgeInsets.fromLTRB(
                  kIsWeb ? 32 : 20,
                  kIsWeb ? 16 : 8,
                  kIsWeb ? 32 : 20,
                  kIsWeb ? 24 : 16,
                ),
              child: _buildTabBar(),
              ),
            ),
          ),
          
          // Top 3 Podium
          if (!_isLoading && _leaderboard.length >= 3)
            SliverToBoxAdapter(
              child: ResponsiveLayout(
                maxWidth: kIsWeb ? 1000 : double.infinity,
                padding: EdgeInsets.zero,
              child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: kIsWeb ? 32 : 20,
                    vertical: kIsWeb ? 16 : 8,
                  ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildPodium(),
                  ),
                ),
              ),
            ),
          
          // Rest of Top 20 Leaderboard
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                ),
              ),
            )
          else if (_leaderboard.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No leaderboard data yet',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to compete!',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Skip top 3 if podium is shown, show rest up to 20
                  final displayIndex = _leaderboard.length >= 3 ? index + 3 : index;
                  if (displayIndex >= _leaderboard.length || displayIndex >= 20) return null;
                  
                  final user = _getSortedLeaderboard()[displayIndex];
                  final rank = displayIndex + 1;
                  final isCurrentUser = user['isCurrentUser'] == true;
                  
                  return ResponsiveLayout(
                    maxWidth: kIsWeb ? 1000 : double.infinity,
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 32 : 20,
                        vertical: kIsWeb ? 6 : 4,
                      ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildLeaderboardItem(user, rank, isCurrentUser),
                      ),
                    ),
                  );
                },
                childCount: _leaderboard.length >= 3 
                    ? (_leaderboard.length - 3).clamp(0, 17) // Up to 20 total (3 podium + 17 list)
                    : _leaderboard.length.clamp(0, 20),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab('XP', 'XP'),
          ),
          Expanded(
            child: _buildTab('Streak', 'Streak'),
          ),
          Expanded(
            child: _buildTab('Level', 'Level'),
          ),
          Expanded(
            child: _buildTab('Portfolio', 'Portfolio'),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String value) {
    final isSelected = _selectedTab == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
        _loadLeaderboard();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: isSelected ? const Color(0xFF0052FF) : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPodium() {
    final sorted = _getSortedLeaderboard();
    if (sorted.length < 3) return const SizedBox.shrink();
    
    final top3 = sorted.take(3).toList();
    
    return Container(
      padding: EdgeInsets.all(kIsWeb ? 28 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 24 : 20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kIsWeb ? 0.08 : 0.05),
            blurRadius: kIsWeb ? 16 : 10,
            offset: Offset(0, kIsWeb ? 4 : 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          Expanded(
            child: _buildPodiumItem(top3[1], 2, const Color(0xFF6B7280), 100),
          ),
          const SizedBox(width: 12),
          // 1st Place
          Expanded(
            child: _buildPodiumItem(top3[0], 1, const Color(0xFF0052FF), 130),
          ),
          const SizedBox(width: 12),
          // 3rd Place
          Expanded(
            child: _buildPodiumItem(top3[2], 3, const Color(0xFF9CA3AF), 80),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int rank, Color color, double height) {
    final isCurrentUser = user['isCurrentUser'] == true;
    
    return Column(
      children: [
        // Trophy for 1st place
        if (rank == 1)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Icon(
              Icons.emoji_events,
              color: const Color(0xFF0052FF),
              size: 32,
            ),
          ),
        
        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrentUser ? const Color(0xFF0052FF) : color,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFF3F4F6),
            child: Text(
              ((user['displayName'] ?? user['display_name'] ?? 'U') as String)[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Name
        Text(
          (user['displayName'] ?? user['display_name'] ?? user['name'] ?? 'User') as String,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Value
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getValueForTab(user),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        
        // Podium Base
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getValueForTab(Map<String, dynamic> user) {
    switch (_selectedTab) {
      case 'XP':
        return '${_formatNumber(user['xp'] ?? 0)}';
      case 'Streak':
        return '${user['streak'] ?? 0} days';
      case 'Level':
        return 'Level ${user['level'] ?? 1}';
      case 'Portfolio':
        final value = (user['portfolio_value'] ?? user['portfolioValue'] ?? 10000.0) as num;
        // Ensure value is never 0 or negative (default to starting balance)
        final portfolioValue = value.toDouble() > 0 ? value.toDouble() : 10000.0;
        return '\$${_formatCurrency(portfolioValue)}';
      default:
        return '0';
    }
  }
  
  String _formatCurrency(double amount) {
    // Leaderboard display: whole dollars only, no decimals
    // Keep underlying values precise; this is purely visual
    final rounded = amount.round(); // round to nearest whole dollar
    final integerPart = rounded.toString();
    
    // Add commas to integer part
    String formattedInteger = '';
    for (int i = integerPart.length - 1, count = 0; i >= 0; i--, count++) {
      if (count > 0 && count % 3 == 0) {
        formattedInteger = ',' + formattedInteger;
      }
      formattedInteger = integerPart[i] + formattedInteger;
    }
    
    return formattedInteger;
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user, int rank, bool isCurrentUser) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 20 : 16,
        vertical: kIsWeb ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFF0F4FF) : Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
        border: Border.all(
          color: isCurrentUser ? const Color(0xFF0052FF) : const Color(0xFFE5E7EB),
          width: isCurrentUser ? (kIsWeb ? 2 : 1.5) : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isCurrentUser ? (kIsWeb ? 0.06 : 0.04) : (kIsWeb ? 0.03 : 0.01)),
            blurRadius: kIsWeb ? 8 : 4,
            offset: Offset(0, kIsWeb ? 2 : 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Text(
              '#$rank',
              style: GoogleFonts.inter(
                color: isCurrentUser ? const Color(0xFF0052FF) : const Color(0xFF6B7280),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isCurrentUser ? Border.all(color: const Color(0xFF0052FF), width: 2) : null,
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF3F4F6),
              child: Text(
                ((user['displayName'] ?? user['display_name'] ?? 'U') as String)[0].toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        (user['displayName'] ?? user['display_name'] ?? user['name'] ?? 'User') as String,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF111827),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOU',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _getValueForTab(user),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0052FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lv.${user['level'] ?? 1}',
              style: GoogleFonts.inter(
                color: const Color(0xFF0052FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  List<Map<String, dynamic>> _getSortedLeaderboard() {
    List<Map<String, dynamic>> sorted = List.from(_leaderboard);
    sorted.sort((a, b) {
      switch (_selectedTab) {
        case 'XP':
          final aValue = (a['xp'] as int? ?? 0);
          final bValue = (b['xp'] as int? ?? 0);
          return bValue.compareTo(aValue);
        case 'Streak':
          final aValue = (a['streak'] as int? ?? 0);
          final bValue = (b['streak'] as int? ?? 0);
          return bValue.compareTo(aValue);
        case 'Level':
          final aValue = (a['level'] as int? ?? 0);
          final bValue = (b['level'] as int? ?? 0);
          return bValue.compareTo(aValue);
        case 'Portfolio':
          // Ensure values are never 0 (default to starting balance $10,000)
          final aValue = ((a['portfolio_value'] ?? a['portfolioValue'] ?? 10000.0) as num).toDouble();
          final bValue = ((b['portfolio_value'] ?? b['portfolioValue'] ?? 10000.0) as num).toDouble();
          // Ensure positive values for comparison
          final aFinal = aValue > 0 ? aValue : 10000.0;
          final bFinal = bValue > 0 ? bValue : 10000.0;
          return bFinal.compareTo(aFinal);
        default:
          return 0;
      }
    });
    return sorted;
  }

  int _getUserRank(Map<String, dynamic> user) {
    final sorted = _getSortedLeaderboard();
    final userId = user['userId'] ?? user['user_id'];
    return sorted.indexWhere((u) => 
      (u['userId'] ?? u['user_id']) == userId
    ) + 1;
  }
}
