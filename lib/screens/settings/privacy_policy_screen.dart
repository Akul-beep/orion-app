import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSection(
              title: '1. Introduction',
              content: 'Orion ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
            ),
            
            _buildSection(
              title: '2. Information We Collect',
              content: 'We collect information that you provide directly to us, including:\n\n• Account Information: Email address, display name, and profile information\n• Trading Data: Paper trading transactions, portfolio holdings, and trading history\n• Learning Progress: Completed lessons, achievements, badges, and XP\n• Usage Data: App usage patterns, features accessed, and interaction data\n• Device Information: Device type, operating system, and unique device identifiers',
            ),
            
            _buildSection(
              title: '3. How We Use Your Information',
              content: 'We use the information we collect to:\n\n• Provide and maintain our Service\n• Process your transactions and manage your account\n• Track your learning progress and gamification achievements\n• Improve and personalize your experience\n• Send you notifications and updates (with your consent)\n• Analyze usage patterns to enhance our Service\n• Ensure security and prevent fraud',
            ),
            
            _buildSection(
              title: '4. Data Storage and Security',
              content: 'Your data is stored securely using Supabase, a cloud-based database service. We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
            ),
            
            _buildSection(
              title: '5. Data Sharing and Disclosure',
              content: 'We do not sell your personal information. We may share your information only in the following circumstances:\n\n• With your explicit consent\n• To comply with legal obligations\n• To protect our rights and safety\n• With service providers who assist us in operating our Service (under strict confidentiality agreements)\n• In connection with a business transfer or merger',
            ),
            
            _buildSection(
              title: '6. Leaderboard and Social Features',
              content: 'Your display name, XP, level, and achievements may be visible to other users on the leaderboard. You can control your privacy settings through your profile. We do not share your email address or personal trading data with other users.',
            ),
            
            _buildSection(
              title: '7. Third-Party Services',
              content: 'Our Service uses third-party services that may collect information used to identify you:\n\n• Supabase: For authentication and database storage\n• Google Sign-In: For OAuth authentication (if you choose to use it)\n• Stock Market APIs: For real-time market data\n\nThese services have their own privacy policies governing the collection and use of your information.',
            ),
            
            _buildSection(
              title: '8. Your Rights and Choices',
              content: 'You have the right to:\n\n• Access your personal data\n• Correct inaccurate data\n• Request deletion of your data\n• Opt-out of certain data collection\n• Export your data\n• Withdraw consent for data processing\n\nYou can exercise these rights through the app settings or by contacting us.',
            ),
            
            _buildSection(
              title: '9. Data Retention',
              content: 'We retain your personal information for as long as your account is active or as needed to provide you with our Service. If you delete your account, we will delete or anonymize your personal information, except where we are required to retain it for legal purposes.',
            ),
            
            _buildSection(
              title: '10. Children\'s Privacy',
              content: 'Our Service is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
            ),
            
            _buildSection(
              title: '11. International Data Transfers',
              content: 'Your information may be transferred to and processed in countries other than your country of residence. These countries may have data protection laws that differ from those in your country. We take appropriate safeguards to ensure your data is protected.',
            ),
            
            _buildSection(
              title: '12. Changes to This Privacy Policy',
              content: 'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. You are advised to review this Privacy Policy periodically.',
            ),
            
            _buildSection(
              title: '13. Cookies and Tracking',
              content: 'We may use cookies and similar tracking technologies to track activity on our Service and hold certain information. You can instruct your device to refuse all cookies or to indicate when a cookie is being sent.',
            ),
            
            _buildSection(
              title: '14. Contact Us',
              content: 'If you have any questions about this Privacy Policy or our data practices, please contact us:\n\n• Through the app\'s Help & FAQ section\n• Email: orionai34@gmail.com\n• Support: orionai34@gmail.com',
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF1E3A8A),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your privacy is important to us. We are committed to protecting your personal information and being transparent about how we use it.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF111827),
                      ),
                    ),
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

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

