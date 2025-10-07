import 'package:flutter/material.dart';
import '../models/stock_quote.dart';
import '../models/company_profile.dart';

class FinancialDataGrid extends StatelessWidget {
  final StockQuote quote;
  final CompanyProfile profile;

  const FinancialDataGrid({
    super.key,
    required this.quote,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3.0, // Increased aspect ratio to prevent overflow
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMetricCard(
                'Market Cap',
                _formatMarketCap(profile.marketCapitalization),
                Icons.account_balance,
                const Color(0xFF2C2C54),
              ),
              _buildMetricCard(
                'P/E Ratio',
                profile.peRatio != null ? '${profile.peRatio!.toStringAsFixed(2)}' : 'N/A',
                Icons.trending_up,
                const Color(0xFF00C853),
              ),
              _buildMetricCard(
                'Dividend Yield',
                profile.dividendYield != null ? '${(profile.dividendYield! * 100).toStringAsFixed(2)}%' : 'N/A',
                Icons.payments,
                const Color(0xFF2196F3),
              ),
              _buildMetricCard(
                'Beta',
                profile.beta != null ? profile.beta!.toStringAsFixed(2) : 'N/A',
                Icons.speed,
                const Color(0xFFFF9800),
              ),
              _buildMetricCard(
                'EPS',
                profile.eps != null ? '\$${profile.eps!.toStringAsFixed(2)}' : 'N/A',
                Icons.analytics,
                const Color(0xFF9C27B0),
              ),
              _buildMetricCard(
                'Price to Book',
                profile.priceToBook != null ? profile.priceToBook!.toStringAsFixed(2) : 'N/A',
                Icons.book,
                const Color(0xFFE91E63),
              ),
              _buildMetricCard(
                'Revenue',
                profile.revenue != null ? _formatRevenue(profile.revenue!) : 'N/A',
                Icons.attach_money,
                const Color(0xFF4CAF50),
              ),
              _buildMetricCard(
                'Profit Margin',
                profile.profitMargin != null ? '${(profile.profitMargin! * 100).toStringAsFixed(1)}%' : 'N/A',
                Icons.trending_up,
                const Color(0xFF607D8B),
              ),
              _buildMetricCard(
                'ROE',
                profile.returnOnEquity != null ? '${(profile.returnOnEquity! * 100).toStringAsFixed(1)}%' : 'N/A',
                Icons.show_chart,
                const Color(0xFF795548),
              ),
              _buildMetricCard(
                'Debt/Equity',
                profile.debtToEquity != null ? profile.debtToEquity!.toStringAsFixed(2) : 'N/A',
                Icons.balance,
                const Color(0xFF3F51B5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding to prevent overflow
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMarketCap(double marketCap) {
    // The API returns market cap in millions, so we need to multiply by 1e6 first
    final actualMarketCap = marketCap * 1e6;
    
    if (actualMarketCap >= 1e12) {
      return '\$${(actualMarketCap / 1e12).toStringAsFixed(2)}T';
    } else if (actualMarketCap >= 1e9) {
      return '\$${(actualMarketCap / 1e9).toStringAsFixed(2)}B';
    } else if (actualMarketCap >= 1e6) {
      return '\$${(actualMarketCap / 1e6).toStringAsFixed(2)}M';
    } else if (actualMarketCap >= 1e3) {
      return '\$${(actualMarketCap / 1e3).toStringAsFixed(2)}K';
    } else {
      return '\$${actualMarketCap.toStringAsFixed(2)}';
    }
  }

  String _formatRevenue(double revenue) {
    if (revenue >= 1e12) {
      return '\$${(revenue / 1e12).toStringAsFixed(2)}T';
    } else if (revenue >= 1e9) {
      return '\$${(revenue / 1e9).toStringAsFixed(2)}B';
    } else if (revenue >= 1e6) {
      return '\$${(revenue / 1e6).toStringAsFixed(2)}M';
    } else if (revenue >= 1e3) {
      return '\$${(revenue / 1e3).toStringAsFixed(2)}K';
    } else {
      return '\$${revenue.toStringAsFixed(2)}';
    }
  }
}
