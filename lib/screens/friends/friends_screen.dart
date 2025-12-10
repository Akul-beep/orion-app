import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/friend_service.dart';
import '../../services/paper_trading_service.dart';
import '../../services/referral_service.dart';
import '../../services/referral_rewards_service.dart';
import '../../utils/responsive_layout.dart';
import 'friend_request_screen.dart';
import '../referral/referral_screen.dart';

/// Friends Screen - View friends, their portfolios, and compete
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize and refresh friend data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendService>(context, listen: false).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: ResponsiveLayout(
          maxWidth: kIsWeb ? 1000 : double.infinity,
          padding: EdgeInsets.zero,
          child: Text(
          'Friends',
          style: GoogleFonts.inter(
              fontSize: kIsWeb ? 24 : 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
            ),
          ),
        ),
        actions: [
          // Friend requests button with badge
          Consumer<FriendService>(
            builder: (context, friendService, child) {
              if (friendService.pendingRequestCount == 0) {
                return IconButton(
                  icon: const Icon(Icons.person_add, color: Color(0xFF111827)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FriendRequestScreen()),
                    );
                  },
                );
              }
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Color(0xFF111827)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FriendRequestScreen()),
                      );
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '${friendService.pendingRequestCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0052FF),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF0052FF),
          tabs: const [
            Tab(text: 'My Friends'),
            Tab(text: 'Add Friends'),
            Tab(text: 'Refer & Earn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildAddFriendsTab(),
          _buildReferralTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Consumer<FriendService>(
      builder: (context, friendService, child) {
        if (friendService.friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add friends to compete and compare portfolios!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Friends'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        // Get current user's portfolio value for comparison
        final currentPortfolio = Provider.of<PaperTradingService>(context, listen: false).totalValue;
        
        // Sort friends by portfolio value (descending)
        final sortedFriends = List<Friend>.from(friendService.friends)
          ..sort((a, b) {
            final aValue = a.portfolioValue ?? 0;
            final bValue = b.portfolioValue ?? 0;
            return bValue.compareTo(aValue);
          });

        return RefreshIndicator(
          onRefresh: () => friendService.refresh(),
          child: ResponsiveLayout(
            maxWidth: kIsWeb ? 1000 : double.infinity,
            padding: EdgeInsets.zero,
          child: ListView.builder(
              padding: EdgeInsets.all(kIsWeb ? 32 : 16),
            itemCount: sortedFriends.length,
            itemBuilder: (context, index) {
              final friend = sortedFriends[index];
              final rank = index + 1;
              final isCurrentUserHigher = currentPortfolio > (friend.portfolioValue ?? 0);
              
                return Padding(
                  padding: EdgeInsets.only(bottom: kIsWeb ? 16 : 12),
                  child: _buildFriendCard(friend, rank, isCurrentUserHigher, currentPortfolio),
                );
            },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendCard(Friend friend, int rank, bool isCurrentUserHigher, double currentPortfolio) {
    final portfolioValue = friend.portfolioValue ?? 0;
    final portfolioDiff = portfolioValue - currentPortfolio;
    final portfolioDiffPercent = currentPortfolio > 0 ? (portfolioDiff / currentPortfolio * 100) : 0;
    
    return Container(
      padding: EdgeInsets.all(kIsWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kIsWeb ? 0.05 : 0.03),
            blurRadius: kIsWeb ? 12 : 8,
            offset: Offset(0, kIsWeb ? 4 : 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFFD700) // Gold
                  : rank == 2
                      ? const Color(0xFFC0C0C0) // Silver
                      : rank == 3
                          ? const Color(0xFFCD7F32) // Bronze
                          : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Profile picture
          CircleAvatar(
            radius: 24,
            backgroundImage: friend.photoUrl != null ? NetworkImage(friend.photoUrl!) : null,
            backgroundColor: const Color(0xFFE5E7EB),
            child: friend.photoUrl == null
                ? Text(
                    friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : 'U',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Friend info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (friend.level != null) ...[
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${friend.level}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (friend.streak != null && friend.streak! > 0) ...[
                      Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${friend.streak} 🔥',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Portfolio value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${portfolioValue.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              if (portfolioDiff != 0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCurrentUserHigher ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isCurrentUserHigher ? Colors.green : Colors.red,
                    ),
                    Text(
                      '\$${portfolioDiff.abs().toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isCurrentUserHigher ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriendsTab() {
    return Consumer<FriendService>(
      builder: (context, friendService, child) {
        return ResponsiveLayout(
          maxWidth: kIsWeb ? 1000 : double.infinity,
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(kIsWeb ? 32 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search section
              _buildSearchSection(friendService),
                SizedBox(height: kIsWeb ? 32 : 24),
              // Friend requests section
              _buildFriendRequestsSection(friendService),
            ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performSearch(String query, FriendService friendService) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      print('🔍 Performing search for: "$query"');
      final results = await friendService.searchUsers(query.trim());
      print('✅ Search returned ${results.length} results');
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Search error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildSearchSection(FriendService friendService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find Friends',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          onChanged: (value) {
            final trimmedValue = value.trim();
            if (trimmedValue.length >= 2) {
              // Immediate search - no debounce for better UX
              _performSearch(trimmedValue, friendService);
            } else {
              setState(() {
                _searchResults = [];
                _isSearching = false;
              });
            }
          },
          onSubmitted: (query) {
            if (query.trim().length >= 2) {
              _performSearch(query, friendService);
            }
          },
        ),
        const SizedBox(height: 16),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_searchResults.isNotEmpty)
          ..._searchResults.map((user) => _buildSearchResultCard(user, friendService))
        else if (!_isSearching)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Search for friends by name or email',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Or',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendRequestScreen()),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('View Friend Requests'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> user, FriendService friendService) {
    final userId = user['user_id'] as String;
    final displayName = user['display_name'] as String? ?? user['name'] as String? ?? 'User';
    final email = user['email'] as String?;
    final photoUrl = user['photo_url'] as String?;
    
    final hasSentRequest = friendService.sentRequests.any((r) => r.toUserId == userId);

    return Container(
      margin: EdgeInsets.only(bottom: kIsWeb ? 16 : 12),
      padding: EdgeInsets.all(kIsWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kIsWeb ? 0.05 : 0.03),
            blurRadius: kIsWeb ? 12 : 8,
            offset: Offset(0, kIsWeb ? 4 : 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            backgroundColor: const Color(0xFFE5E7EB),
            child: photoUrl == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasSentRequest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Requested',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () async {
                final success = await friendService.sendFriendRequest(userId);
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Friend request sent!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    setState(() {}); // Refresh UI
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to send request'),
                        backgroundColor: Color(0xFFEF4444),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Add'),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestsSection(FriendService friendService) {
    if (friendService.sentRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sent Requests',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        ...friendService.sentRequests.map((request) => _buildSentRequestCard(request, friendService)),
      ],
    );
  }

  Widget _buildSentRequestCard(FriendRequest request, FriendService friendService) {
    return Container(
      margin: EdgeInsets.only(bottom: kIsWeb ? 16 : 12),
      padding: EdgeInsets.all(kIsWeb ? 18 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kIsWeb ? 0.03 : 0.01),
            blurRadius: kIsWeb ? 8 : 4,
            offset: Offset(0, kIsWeb ? 2 : 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE5E7EB),
            child: Text(
              request.toUserId.substring(0, 1).toUpperCase(),
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Request sent to ${request.toUserId.substring(0, 8)}...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await friendService.cancelFriendRequest(request.id);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralTab() {
    return const ReferralScreen();
  }
}

