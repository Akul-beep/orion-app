import 'package:flutter/material.dart';
import '../../models/stock_quote.dart';
import '../../models/company_profile.dart';

class OverviewTab extends StatelessWidget {
  final StockQuote quote;
  final CompanyProfile profile;

  const OverviewTab({
    super.key,
    required this.quote,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Information
          _buildSectionCard(
            context,
            'Company Information',
            [
              _buildInfoRow('Name', profile.name),
              _buildInfoRow('Industry', profile.industry),
              _buildInfoRow('Country', profile.country),
              _buildInfoRow('Website', profile.weburl, isUrl: true),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Key Statistics
          _buildSectionCard(
            context,
            'Key Statistics',
            [
              _buildInfoRow('Market Cap', _formatMarketCap(profile.marketCapitalization)),
              _buildInfoRow('Shares Outstanding', _formatNumber(profile.shareOutstanding)),
              _buildInfoRow('Current Price', '\$${quote.currentPrice.toStringAsFixed(2)}'),
              _buildInfoRow('Previous Close', '\$${quote.previousClose.toStringAsFixed(2)}'),
              _buildInfoRow('Day High', '\$${quote.high.toStringAsFixed(2)}'),
              _buildInfoRow('Day Low', '\$${quote.low.toStringAsFixed(2)}'),
              _buildInfoRow('Open', '\$${quote.open.toStringAsFixed(2)}'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Performance Summary
          _buildSectionCard(
            context,
            'Today\'s Performance',
            [
              _buildInfoRow(
                'Change',
                '\$${quote.change.toStringAsFixed(2)}',
                valueColor: quote.change >= 0 ? const Color(0xFF00D09C) : Colors.red,
              ),
              _buildInfoRow(
                'Change %',
                '${quote.changePercent.toStringAsFixed(2)}%',
                valueColor: quote.change >= 0 ? const Color(0xFF00D09C) : Colors.red,
              ),
            ],
          ),
          
          if (profile.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              'About ${profile.name}',
              [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    profile.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isUrl = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMarketCap(double marketCap) {
    if (marketCap >= 1e12) {
      return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    } else if (marketCap >= 1e9) {
      return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap >= 1e6) {
      return '\$${(marketCap / 1e6).toStringAsFixed(2)}M';
    } else {
      return '\$${marketCap.toStringAsFixed(0)}';
    }
  }

  String _formatNumber(double number) {
    if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(2)}M';
    } else if (number >= 1e3) {
      return '${(number / 1e3).toStringAsFixed(2)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }
}

