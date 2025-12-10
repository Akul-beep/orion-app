import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
              'Terms of Service',
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
              title: '1. Acceptance of Terms',
              content: 'By accessing and using the Orion app ("Service"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            
            _buildSection(
              title: '2. Description of Service',
              content: 'Orion is a financial education and paper trading application that provides users with educational content about stock trading, investment strategies, and financial markets. The app includes a paper trading feature that allows users to practice trading with virtual money.',
            ),
            
            _buildSection(
              title: '3. User Accounts',
              content: 'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. We reserve the right to suspend or terminate your account if you violate these terms.',
            ),
            
            _buildSection(
              title: '4. Paper Trading Disclaimer',
              content: 'The paper trading feature is for educational purposes only. Virtual trading does not involve real money or real financial risk. Past performance in paper trading does not guarantee future results in real trading. You should never invest more than you can afford to lose.',
            ),
            
            _buildSection(
              title: '5. Educational Content',
              content: 'All educational content provided in the app is for informational purposes only and does not constitute financial, investment, or trading advice. We are not licensed financial advisors, and you should consult with a qualified financial professional before making any investment decisions.',
            ),
            
            _buildSection(
              title: '6. User Conduct',
              content: 'You agree not to use the Service to:\n• Violate any laws or regulations\n• Infringe on the rights of others\n• Transmit harmful or malicious code\n• Attempt to gain unauthorized access to the Service\n• Use the Service for any illegal or unauthorized purpose',
            ),
            
            _buildSection(
              title: '7. Intellectual Property',
              content: 'All content, features, and functionality of the Service are owned by Orion and are protected by international copyright, trademark, and other intellectual property laws. You may not reproduce, distribute, or create derivative works without our express written permission.',
            ),
            
            _buildSection(
              title: '8. Data and Privacy',
              content: 'Your use of the Service is also governed by our Privacy Policy. By using the Service, you consent to the collection and use of your information as described in the Privacy Policy.',
            ),
            
            _buildSection(
              title: '9. Limitation of Liability',
              content: 'To the fullest extent permitted by law, Orion shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses.',
            ),
            
            _buildSection(
              title: '10. Modifications to Terms',
              content: 'We reserve the right to modify these terms at any time. We will notify users of any material changes by posting the new Terms of Service on this page. Your continued use of the Service after such modifications constitutes acceptance of the updated terms.',
            ),
            
            _buildSection(
              title: '11. Termination',
              content: 'We may terminate or suspend your account and access to the Service immediately, without prior notice, for any reason, including if you breach these Terms of Service.',
            ),
            
            _buildSection(
              title: '12. Governing Law',
              content: 'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which Orion operates, without regard to its conflict of law provisions.',
            ),
            
            _buildSection(
              title: '13. Contact Information',
              content: 'If you have any questions about these Terms of Service, please contact us through the app\'s Help & FAQ section or via email at orionai34@gmail.com',
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
                    Icons.info_outline,
                    color: Color(0xFF1E3A8A),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using Orion, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
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

