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
            childAspectRatio: 2.2, // Even better aspect ratio to prevent overflow
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildMetricCard(
                'Market Cap',
                _formatMarketCap(profile.marketCapitalization, profile.currency),
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
                profile.eps != null ? _formatCurrency(profile.eps!, profile.currency) : 'N/A',
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
                profile.revenue != null && profile.revenue! > 0 
                    ? _formatRevenue(profile.revenue!, profile.currency) 
                    : 'N/A',
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

  String _getCurrencySymbol(String currency) {
    return currency == 'INR' ? '₹' : '\$';
  }

  String _formatCurrency(double value, String currency) {
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${value.toStringAsFixed(2)}';
  }

  String _formatMarketCap(double marketCap, String currency) {
    final symbol = _getCurrencySymbol(currency);
    final isIndian = currency == 'INR';
    
    // marketCap is stored in millions (from NSE/Finnhub APIs)
    // For Indian stocks, we can optionally use lakh crores, but for consistency, use T/B/M
    // Convert to appropriate unit for display
    
    if (marketCap >= 1e6) {
      // Trillions (11,400,000 millions = 11.4T)
      return '$symbol${(marketCap / 1e6).toStringAsFixed(2)}T';
    } else if (marketCap >= 1e3) {
      // Billions (1,000 millions = 1B)
      return '$symbol${(marketCap / 1e3).toStringAsFixed(2)}B';
    } else if (marketCap >= 1) {
      // Millions
      return '$symbol${marketCap.toStringAsFixed(2)}M';
    } else if (marketCap >= 0.001) {
      // Thousands
      return '$symbol${(marketCap * 1e3).toStringAsFixed(2)}K';
    } else {
      return '$symbol${(marketCap * 1e6).toStringAsFixed(2)}';
    }
  }

  String _formatRevenue(double revenue, String currency) {
    final symbol = _getCurrencySymbol(currency);
    final isIndian = currency == 'INR';
    
    // Revenue is expected to be in billions (for both US and Indian stocks)
    // For Indian stocks, revenue might come in crores, but we convert to billions for consistency
    if (revenue >= 1000) {
      // Trillions
      return '$symbol${(revenue / 1000).toStringAsFixed(2)}T';
    } else if (revenue >= 1) {
      // Billions
      return '$symbol${revenue.toStringAsFixed(2)}B';
    } else if (revenue >= 0.001) {
      // If less than 1 billion, show in millions
      return '$symbol${(revenue * 1000).toStringAsFixed(2)}M';
    } else {
      return '$symbol${(revenue * 1e6).toStringAsFixed(2)}';
    }
  }
}
