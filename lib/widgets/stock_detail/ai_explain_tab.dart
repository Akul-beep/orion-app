import 'package:flutter/material.dart';
import '../../models/stock_quote.dart';
import '../../models/company_profile.dart';

class AIExplainTab extends StatefulWidget {
  final String symbol;
  final StockQuote quote;
  final CompanyProfile profile;

  const AIExplainTab({
    super.key,
    required this.symbol,
    required this.quote,
    required this.profile,
  });

  @override
  State<AIExplainTab> createState() => _AIExplainTabState();
}

class _AIExplainTabState extends State<AIExplainTab> {
  bool _isGenerating = false;
  String _aiExplanation = '';

  @override
  void initState() {
    super.initState();
    _generateExplanation();
  }

  Future<void> _generateExplanation() async {
    setState(() {
      _isGenerating = true;
    });

    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _aiExplanation = _createAIExplanation();
      _isGenerating = false;
    });
  }

  String _createAIExplanation() {
    final changePercent = widget.quote.changePercent;
    final isPositive = changePercent >= 0;
    final marketCap = widget.profile.marketCapitalization;
    
    String sentiment = isPositive ? 'positive' : 'negative';
    String trendDirection = isPositive ? 'upward' : 'downward';
    
    String marketCapCategory;
    if (marketCap >= 1e12) {
      marketCapCategory = 'mega-cap';
    } else if (marketCap >= 1e9) {
      marketCapCategory = 'large-cap';
    } else if (marketCap >= 1e6) {
      marketCapCategory = 'mid-cap';
    } else {
      marketCapCategory = 'small-cap';
    }

    return '''
📊 **Stock Analysis for ${widget.symbol}**

**Current Performance:**
${widget.symbol} is currently trading at \$${widget.quote.currentPrice.toStringAsFixed(2)}, showing a ${sentiment} movement of ${changePercent.toStringAsFixed(2)}% today. This ${trendDirection} trend suggests ${_getTrendExplanation(changePercent)}.

**Company Overview:**
${widget.profile.name} operates in the ${widget.profile.industry} industry and is a ${marketCapCategory} company with a market capitalization of \$${_formatMarketCap(marketCap)}. ${_getIndustryInsight(widget.profile.industry)}

**Key Metrics Explained:**
• **Current Price**: \$${widget.quote.currentPrice.toStringAsFixed(2)} - This is what you would pay to buy one share right now
• **Day's Range**: \$${widget.quote.low.toStringAsFixed(2)} - \$${widget.quote.high.toStringAsFixed(2)} - Shows the lowest and highest prices today
• **Previous Close**: \$${widget.quote.previousClose.toStringAsFixed(2)} - Yesterday's closing price
• **Change**: \$${widget.quote.change.toStringAsFixed(2)} - How much the price moved from yesterday

**What This Means for You:**
${_getInvestmentAdvice(changePercent, marketCapCategory)}

**Risk Assessment:**
${_getRiskAssessment(widget.profile.industry, marketCapCategory)}

**Learning Tip:**
As a high schooler, remember that stock prices can be volatile. This ${sentiment} movement today doesn't guarantee future performance. Always do your research and consider your risk tolerance before investing.
    ''';
  }

  String _getTrendExplanation(double changePercent) {
    if (changePercent.abs() < 1) {
      return 'relatively stable trading with minimal price movement';
    } else if (changePercent.abs() < 3) {
      return 'moderate price movement that could indicate market sentiment changes';
    } else {
      return 'significant price movement that may attract attention from traders';
    }
  }

  String _getIndustryInsight(String industry) {
    switch (industry.toLowerCase()) {
      case 'technology':
        return 'The technology sector is known for innovation and growth potential, but can be volatile.';
      case 'healthcare':
        return 'Healthcare companies often provide stable returns and are less affected by economic cycles.';
      case 'finance':
        return 'Financial companies are sensitive to interest rates and economic conditions.';
      case 'energy':
        return 'Energy companies are influenced by oil prices and environmental policies.';
      default:
        return 'This industry has its own unique characteristics and market dynamics.';
    }
  }

  String _getInvestmentAdvice(double changePercent, String marketCapCategory) {
    if (changePercent > 5) {
      return 'The significant positive movement suggests strong investor confidence, but be cautious of potential overvaluation.';
    } else if (changePercent < -5) {
      return 'The significant negative movement might present a buying opportunity, but ensure you understand why the stock is declining.';
    } else {
      return 'The moderate price movement indicates normal market activity. This could be a good time to research the company further.';
    }
  }

  String _getRiskAssessment(String industry, String marketCapCategory) {
    String riskLevel;
    String explanation;
    
    if (marketCapCategory == 'mega-cap' || marketCapCategory == 'large-cap') {
      riskLevel = 'Lower Risk';
      explanation = 'Large companies tend to be more stable and less volatile.';
    } else if (marketCapCategory == 'mid-cap') {
      riskLevel = 'Medium Risk';
      explanation = 'Mid-cap companies offer growth potential with moderate risk.';
    } else {
      riskLevel = 'Higher Risk';
      explanation = 'Small-cap companies can be more volatile but offer higher growth potential.';
    }
    
    return '$riskLevel: $explanation';
  }

  String _formatMarketCap(double marketCap) {
    if (marketCap >= 1e12) {
      return '${(marketCap / 1e12).toStringAsFixed(2)}T';
    } else if (marketCap >= 1e9) {
      return '${(marketCap / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap >= 1e6) {
      return '${(marketCap / 1e6).toStringAsFixed(2)}M';
    } else {
      return marketCap.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C2C54), Color(0xFF40407a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Stock Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Simplified explanations for beginners',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // AI Explanation
          if (_isGenerating)
            _buildLoadingState()
          else
            _buildExplanationCard(),
          
          const SizedBox(height: 20),
          
          // Educational Tips
          _buildEducationalTips(),
          
          const SizedBox(height: 20),
          
          // Refresh Button
          Center(
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateExplanation,
              icon: const Icon(Icons.refresh),
              label: const Text('Generate New Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C2C54)),
            ),
            const SizedBox(height: 16),
            Text(
              'AI is analyzing ${widget.symbol}...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C54),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF2C2C54), size: 24),
                SizedBox(width: 8),
                Text(
                  'AI Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _aiExplanation,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalTips() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, color: Color(0xFF2C2C54), size: 24),
                SizedBox(width: 8),
                Text(
                  'Learning Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              '📚 Start Small',
              'Begin with small amounts you can afford to lose. This is called "paper trading" - practice with virtual money first.',
            ),
            _buildTipItem(
              '🔍 Do Your Research',
              'Always research a company before investing. Look at their financial reports, news, and understand what they do.',
            ),
            _buildTipItem(
              '⏰ Think Long-term',
              'Stock investing is usually a long-term game. Don\'t panic over daily price movements.',
            ),
            _buildTipItem(
              '💡 Diversify',
              'Don\'t put all your money in one stock. Spread your investments across different companies and industries.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



