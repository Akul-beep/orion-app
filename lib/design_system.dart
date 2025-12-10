import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrionDesignSystem {
  // Professional Color Palette - Cohesive & Modern
  // Primary: Deep professional blue (trading app feel)
  static const Color primaryBlue = Color(0xFF1E3A8A); // Rich, professional blue
  static const Color primaryBlueLight = Color(0xFF3B82F6); // Lighter accent
  static const Color primaryBlueDark = Color(0xFF1E40AF); // Darker shade
  
  // Trading: Professional deep emerald green (serious, financial)
  static const Color tradingGreen = Color(0xFF059669); // Deep emerald - professional trading green
  static const Color tradingGreenLight = Color(0xFF10B981); // Lighter for accents
  static const Color tradingGreenDark = Color(0xFF047857); // Darker shade
  
  // Learning: Duolingo green (familiar, gamified)
  static const Color learningGreen = Color(0xFF58CC02); // Duolingo green - bright, familiar
  static const Color learningGreenLight = Color(0xFF6EE7B7); // Lighter
  static const Color learningGreenDark = Color(0xFF4CAF50); // Darker
  
  // Legacy support - map to trading green
  static const Color successGreen = tradingGreen;
  static const Color successGreenLight = tradingGreenLight;
  static const Color successGreenDark = tradingGreenDark;
  
  // Warning/Error: Professional orange-red
  static const Color warningOrange = Color(0xFFF59E0B); // Professional orange
  static const Color errorRed = Color(0xFFEF4444); // Professional red
  
  // Info: Professional blue
  static const Color infoBlue = Color(0xFF3B82F6); // Info blue
  
  // Accent: Gold for achievements
  static const Color gold = Color(0xFFFBBF24); // Professional gold
  static const Color goldLight = Color(0xFFFCD34D);
  
  // Neutrals: Professional grays
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF9FAFB); // Very light gray
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color mediumGrey = Color(0xFF9CA3AF);
  static const Color darkGrey = Color(0xFF6B7280);
  static const Color textPrimary = Color(0xFF111827); // Almost black
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  
  // Gradients - Professional & Modern
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient tradingGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient learningGradient = LinearGradient(
    colors: [Color(0xFF58CC02), Color(0xFF6EE7B7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFFCD34D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Legacy support
  static const LinearGradient successGradient = tradingGradient;
  
  // Spacing Constants (for consistent mobile spacing)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Border Radius Constants
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;

  // Typography - Professional & Readable
  // Using Inter for better readability (modern, professional)
  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static TextStyle heading2 = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static TextStyle heading3 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );
  
  static TextStyle successText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: successGreen,
  );
  
  static TextStyle errorText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: errorRed,
  );
  
  // Mobile-optimized text sizes
  static TextStyle heading1Mobile = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static TextStyle heading2Mobile = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.3,
  );

  // Card Styles - Professional with proper shadows
  static BoxDecoration primaryCard = BoxDecoration(
    color: backgroundWhite,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration elevatedCard = BoxDecoration(
    color: backgroundWhite,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration gradientCard = BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: primaryBlue.withOpacity(0.25),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
  
  static BoxDecoration successCard = BoxDecoration(
    gradient: successGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: successGreen.withOpacity(0.25),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
  
  // Completion badge - Very prominent
  static BoxDecoration completionBadge = BoxDecoration(
    color: successGreen,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: successGreen.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Button Styles - Professional & Touch-friendly
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: successGreen,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    minimumSize: const Size(120, 48), // Touch-friendly minimum
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );
  
  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    minimumSize: const Size(120, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );
  
  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: primaryBlue,
    side: const BorderSide(color: primaryBlue, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    minimumSize: const Size(120, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
  
  // Input Field Styles
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      filled: true,
      fillColor: backgroundGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightGrey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightGrey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: successGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: bodyMedium.copyWith(color: textSecondary),
      hintStyle: bodyMedium.copyWith(color: mediumGrey),
    );
  }

  // Progress Ring (Duolingo-style)
  static Widget buildProgressRing({
    required double progress,
    required double size,
    required Color color,
    required Widget child,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(child: child),
        ],
      ),
    );
  }

  // XP Badge
  static Widget buildXPBadge(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: gold, size: 16),
          const SizedBox(width: 4),
          Text(
            '$xp XP',
            style: GoogleFonts.poppins(
              color: gold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Streak Badge
  static Widget buildStreakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: warningOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warningOrange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: warningOrange, size: 16),
          const SizedBox(width: 4),
          Text(
            '$streak day streak',
            style: GoogleFonts.poppins(
              color: warningOrange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Live Price Ticker
  static Widget buildLivePriceTicker({
    required String symbol,
    required double price,
    required double change,
    required double changePercent,
  }) {
    final isPositive = change >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            symbol,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${isPositive ? '+' : ''}\$${change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%)',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isPositive ? successGreen : warningOrange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Card
  static Widget buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Mission Card
  static Widget buildMissionCard({
    required String title,
    required String description,
    required String progress,
    required VoidCallback onContinue,
    required VoidCallback onSkip,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: successCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: successGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue Learning',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Skip to Trading',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Position Card
  static Widget buildPositionCard({
    required String symbol,
    required int quantity,
    required double averagePrice,
    required double currentPrice,
    required double profitLoss,
    required double profitLossPercent,
  }) {
    final isProfit = profitLoss >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: primaryCard,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantity shares @ \$${averagePrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: darkGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${currentPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isProfit ? '+' : ''}\$${profitLoss.toStringAsFixed(2)} (${isProfit ? '+' : ''}${profitLossPercent.toStringAsFixed(1)}%)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isProfit ? successGreen : warningOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Empty State
  static Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: darkGrey),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onButtonPressed,
            style: primaryButton,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
  
  // Completion Badge - Very Prominent
  static Widget buildCompletionBadge({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: completionBadge,
      child: const Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 20,
      ),
    );
  }
  
  // Completion Indicator with Animation
  static Widget buildCompletionIndicator({
    required bool isCompleted,
    double size = 40,
  }) {
    if (!isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: lightGrey,
          shape: BoxShape.circle,
        ),
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: successGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: successGreen.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
