import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A8A),
                    const Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.help_outline,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How can we help?',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find answers to common questions',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Categories
            _buildSection(
              title: 'Getting Started',
              children: [
                _buildFAQItem(
                  question: 'How do I start trading?',
                  answer:
                      'Complete your first lesson to unlock trading. Then go to the Trading tab and search for a stock. Click "Buy" or "Sell" and enter the quantity. You start with \$10,000 virtual money!',
                ),
                _buildFAQItem(
                  question: 'What is paper trading?',
                  answer:
                      'Paper trading lets you practice trading stocks with virtual money. You can buy, sell, set stop losses, and track your portfolio - all without risking real money. Perfect for learning!',
                ),
                _buildFAQItem(
                  question: 'How do lessons work?',
                  answer:
                      'New lessons unlock daily. Complete a lesson by reading the content and passing the quiz. Each lesson teaches real trading concepts and rewards XP. "Take Action" tasks let you practice what you learned!',
                ),
              ],
            ),

            _buildSection(
              title: 'Gamification',
              children: [
                _buildFAQItem(
                  question: 'How do I earn XP?',
                  answer:
                      'Earn XP by completing lessons, making trades, finishing daily goals, maintaining streaks, and completing learning actions. Daily login bonuses give extra XP!',
                ),
                _buildFAQItem(
                  question: 'What are badges?',
                  answer:
                      'Badges unlock when you reach milestones like completing your first trade, maintaining a 7-day streak, or reaching certain levels. Check your profile to see all your badges!',
                ),
                _buildFAQItem(
                  question: 'How do streaks work?',
                  answer:
                      'Maintain your streak by completing at least one daily goal each day. The longer your streak, the more bonuses you get! Use streak freeze to protect your streak if you miss a day.',
                ),
              ],
            ),

            _buildSection(
              title: 'Trading',
              children: [
                _buildFAQItem(
                  question: 'What is a stop loss?',
                  answer:
                      'A stop loss automatically sells your stock if it drops to a certain price. This helps limit your losses. Set stop losses on your positions to protect your portfolio!',
                ),
                _buildFAQItem(
                  question: 'What is take profit?',
                  answer:
                      'Take profit automatically sells your stock when it reaches a target price. This helps lock in profits. Set take profit orders to secure your gains!',
                ),
                _buildFAQItem(
                  question: 'Can I cancel an order?',
                  answer:
                      'Currently, orders execute immediately as market orders. This ensures your trades are executed at the current market price right away.',
                ),
              ],
            ),

            _buildSection(
              title: 'Social Features',
              children: [
                _buildFAQItem(
                  question: 'How do I add friends?',
                  answer:
                      'Go to the Social tab and tap "Add Friends". Search by username or send an invite link. Friend requests will be approved soon!',
                ),
                _buildFAQItem(
                  question: 'What is the leaderboard?',
                  answer:
                      'The leaderboard shows top players ranked by XP, level, and streak. Compete with friends and see who\'s leading the pack!',
                ),
                _buildFAQItem(
                  question: 'How do challenges work?',
                  answer:
                      'Weekly challenges give you goals to complete. Challenge friends to see who can earn the most XP or complete the most trades!',
                ),
              ],
            ),

            _buildSection(
              title: 'Troubleshooting',
              children: [
                _buildFAQItem(
                  question: 'Stock prices not updating?',
                  answer:
                      'Stock prices update every 60 seconds. If prices aren\'t loading, check your internet connection and try pulling down to refresh.',
                ),
                _buildFAQItem(
                  question: 'App crashes or freezes?',
                  answer:
                      'Try closing and reopening the app. If problems persist, go to Settings and clear app cache. Make sure you have the latest version!',
                ),
                _buildFAQItem(
                  question: 'Can\'t place a trade?',
                  answer:
                      'Make sure you have enough cash (for buys) or shares (for sells). Check that you entered a valid stock symbol and quantity. Trades must be at least 1 share.',
                ),
              ],
            ),

            // Contact Support
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 48,
                    color: Color(0xFF1E3A8A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Still need help?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact our support team for assistance',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Support: orionai34@gmail.com'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Contact Support'),
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

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
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
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
        iconColor: const Color(0xFF1E3A8A),
        collapsedIconColor: const Color(0xFF1E3A8A),
      ),
    );
  }
}






