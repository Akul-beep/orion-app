import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/stock_quote.dart';
import '../../models/company_profile.dart';
import '../../models/news_article.dart';
import '../../services/ai_stock_analysis_service.dart';

class AIExplainTab extends StatefulWidget {
  final String symbol;
  final StockQuote quote;
  final CompanyProfile profile;
  final List<NewsArticle>? recentNews;
  final Map<String, dynamic>? indicators;
  final Map<String, dynamic>? metrics;
  final ValueChanged<bool>? onGeneratingChanged; // Callback to notify parent of generating state

  const AIExplainTab({
    super.key,
    required this.symbol,
    required this.quote,
    required this.profile,
    this.recentNews,
    this.indicators,
    this.metrics,
    this.onGeneratingChanged,
  });

  @override
  State<AIExplainTab> createState() => _AIExplainTabState();
}

class _AIExplainTabState extends State<AIExplainTab> with AutomaticKeepAliveClientMixin {
  bool _isGenerating = false;
  String _aiExplanation = '';
  String? _error;
  Map<String, dynamic>? _parsedAnalysis;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    // Ensure keep alive is set up immediately
    updateKeepAlive();
  }

  Future<void> _generateExplanation() async {
    // Don't regenerate if already generating or already has content
    if (_isGenerating || (_parsedAnalysis != null && _parsedAnalysis!.isNotEmpty)) {
      return;
    }
    
    // Update state to show generating - this will persist even if we switch tabs
    if (mounted) {
      setState(() {
        _isGenerating = true;
        _error = null;
        // Don't clear existing content - keep it if switching tabs
        if (_aiExplanation.isEmpty) {
          _aiExplanation = '';
          _parsedAnalysis = null;
        }
      });
      // Notify parent that generation started
      widget.onGeneratingChanged?.call(true);
      // Ensure widget stays alive during async operation
      updateKeepAlive();
    }

    try {
      // Start async operation - this will continue even if widget is not visible
      // because AutomaticKeepAliveClientMixin keeps the widget alive
      final analysis = await AIStockAnalysisService.generateStockAnalysis(
        quote: widget.quote,
        profile: widget.profile,
        recentNews: widget.recentNews,
        indicators: widget.indicators,
        metrics: widget.metrics,
      );

      // Update state when analysis completes - widget will still be alive due to keep alive
      if (mounted) {
        // Try to parse as JSON
        try {
          String cleanedResponse = analysis.trim();
          if (cleanedResponse.startsWith('```json')) {
            cleanedResponse = cleanedResponse.substring(7);
          }
          if (cleanedResponse.startsWith('```')) {
            cleanedResponse = cleanedResponse.substring(3);
          }
          if (cleanedResponse.endsWith('```')) {
            cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
          }
          cleanedResponse = cleanedResponse.trim();
          
          final parsed = jsonDecode(cleanedResponse) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _parsedAnalysis = parsed;
              _aiExplanation = analysis;
              _isGenerating = false;
            });
            // Notify parent that generation completed
            widget.onGeneratingChanged?.call(false);
            updateKeepAlive(); // Update keep alive state
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _aiExplanation = analysis;
              _parsedAnalysis = null;
              _isGenerating = false;
            });
            // Notify parent that generation completed
            widget.onGeneratingChanged?.call(false);
            updateKeepAlive(); // Update keep alive state
          }
        }
      }
    } catch (e) {
      print('❌ Error generating AI analysis: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        String errorMessage = 'Failed to generate analysis';
        final errorStr = e.toString();
        
        // Better error messages for common issues
        if (errorStr.contains('quota') || errorStr.contains('limit: 0') || errorStr.contains('exceeded')) {
          errorMessage = 'API quota exceeded. The free tier limit has been reached. Please check your Google AI Studio quota or enable billing.';
        } else if (errorStr.contains('503') || errorStr.contains('overloaded') || errorStr.contains('UNAVAILABLE')) {
          errorMessage = 'AI service is temporarily overloaded. Please try again in a moment.';
        } else if (errorStr.contains('429') || errorStr.contains('rate limit') || errorStr.contains('resource exhausted')) {
          errorMessage = 'Rate limit exceeded. Please wait a moment and try again.';
        } else if (errorStr.contains('API key') || errorStr.contains('authentication')) {
          errorMessage = 'API authentication failed. Please check configuration.';
        } else {
          errorMessage = 'Failed to generate analysis. Please try again.';
        }
        
        setState(() {
          _error = errorMessage;
          _isGenerating = false;
        });
        // Notify parent that generation completed (with error)
        widget.onGeneratingChanged?.call(false);
        updateKeepAlive(); // Update keep alive state
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    // Update keep alive state to ensure widget stays alive when switching tabs
    updateKeepAlive();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading State - Show FIRST and prominently when generating
          // This ensures users see it's still running even after switching tabs
          if (_isGenerating) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0052FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0052FF).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Generating AI analysis...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a moment. You can switch tabs - analysis will continue in the background.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Running in background',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0052FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Simple AI Explain Button - Only show if no content, not generating, and no error
          if (_parsedAnalysis == null && _aiExplanation.isEmpty && !_isGenerating && _error == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateExplanation,
                icon: const Icon(Icons.psychology),
                label: const Text('AI Explain'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          
          // Add spacing only if button is shown
          if (_parsedAnalysis == null && _aiExplanation.isEmpty && !_isGenerating && _error == null)
            const SizedBox(height: 20),
          
          // Error State
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _generateExplanation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C54),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          
          // Parsed Analysis Display - ONLY show if we have valid JSON
          if (_parsedAnalysis != null) 
            _buildParsedAnalysis()
          else if (_aiExplanation.isNotEmpty && _parsedAnalysis == null)
            // If we got text but couldn't parse it, show error
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'AI response format error. Please try again.',
                    style: TextStyle(color: Colors.orange),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _generateExplanation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C54),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildParsedAnalysis() {
    if (_parsedAnalysis == null) return const SizedBox.shrink();
    
    final summary = _parsedAnalysis!['summary'] as Map<String, dynamic>?;
    final performance = _parsedAnalysis!['performance'] as Map<String, dynamic>?;
    final company = _parsedAnalysis!['company'] as Map<String, dynamic>?;
    final indicators = _parsedAnalysis!['indicators'] as Map<String, dynamic>?;
    final metrics = _parsedAnalysis!['metrics'] as List<dynamic>?;
    final opinion = _parsedAnalysis!['opinion'] as Map<String, dynamic>?;
    final advice = _parsedAnalysis!['advice'] as Map<String, dynamic>?;
    final risk = _parsedAnalysis!['risk'] as Map<String, dynamic>?;
    final learningTip = _parsedAnalysis!['learningTip'] as String?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary - Compact
        if (summary != null) ...[
          _buildSectionCard(
            'Summary',
            Icons.summarize,
            [
              if (summary['title'] != null)
                Text(
                  summary['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              if (summary['overview'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  summary['overview'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        // Performance - Compact
        if (performance != null) ...[
          _buildSectionCard(
            'Performance',
            Icons.trending_up,
            [
              if (performance['currentPrice'] != null)
                _buildCompactInfoRow('Current Price', performance['currentPrice'] as String),
              if (performance['priceChange'] != null)
                _buildCompactInfoRow('Price Change', performance['priceChange'] as String),
              if (performance['volatility'] != null)
                _buildCompactInfoRow('Volatility', (performance['volatility'] as String).toUpperCase()),
              if (performance['trend'] != null)
                _buildCompactInfoRow('Trend', (performance['trend'] as String).toUpperCase()),
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        // Company - Compact
        if (company != null) ...[
          _buildSectionCard(
            'Company',
            Icons.business,
            [
              if (company['description'] != null)
                Text(
                  company['description'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              if (company['industry'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  company['industry'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
              if (company['marketCap'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Market Cap Explained',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company['marketCap'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.3,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        // News Analysis (NEW SECTION!)
        if (_parsedAnalysis?['newsAnalysis'] != null) ...[
          _buildNewsAnalysisSection(_parsedAnalysis!['newsAnalysis']),
          const SizedBox(height: 16),
        ],
        
        // Technical Indicators Breakdown (NEW!)
        if (indicators != null) ...[
          _buildSectionCard(
            'Technical Indicators Explained',
            Icons.show_chart,
            [
              Text(
                'Learn what these numbers mean:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              if (indicators['rsi'] != null) 
                _buildIndicatorExplanation(
                  'RSI (Relative Strength Index)',
                  indicators['rsi']['value'] ?? 'N/A',
                  indicators['rsi']['explanation'] ?? '',
                  indicators['rsi']['whatItTellsUs'] ?? '',
                  Colors.purple,
                ),
              if (indicators['sma'] != null) 
                _buildIndicatorExplanation(
                  'SMA (Simple Moving Average)',
                  indicators['sma']['value'] ?? 'N/A',
                  indicators['sma']['explanation'] ?? '',
                  indicators['sma']['whatItTellsUs'] ?? '',
                  Colors.blue,
                ),
              if (indicators['macd'] != null) 
                _buildIndicatorExplanation(
                  'MACD (Moving Average Convergence Divergence)',
                  indicators['macd']['value'] ?? 'N/A',
                  indicators['macd']['explanation'] ?? '',
                  indicators['macd']['whatItTellsUs'] ?? '',
                  Colors.teal,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Metrics Grid - Compact 2-Column Layout like Overview
        if (metrics != null && metrics.isNotEmpty) ...[
          _buildSectionCard(
            'Key Metrics',
            Icons.analytics,
            [
              Text(
                'Tap any metric to learn more',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.0, // More compact aspect ratio
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: metrics.length,
                itemBuilder: (context, index) {
                  final metric = metrics[index] as Map<String, dynamic>;
                  return _buildCompactMetricCard(metric);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        // AI Opinion (NEW!)
        if (opinion != null) ...[
          _buildSectionCard(
            'AI Opinion',
            Icons.psychology,
            [
              // Stance Badge
              if (opinion['stance'] != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStanceColor(opinion['stance'] as String).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStanceColor(opinion['stance'] as String),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStanceIcon(opinion['stance'] as String),
                            color: _getStanceColor(opinion['stance'] as String),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (opinion['stance'] as String).toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getStanceColor(opinion['stance'] as String),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (opinion['confidence'] != null) ...[
                      const SizedBox(width: 12),
                      _buildConfidenceChip(opinion['confidence']),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              
              // Reasoning
              if (opinion['reasoning'] != null)
                Text(
                  opinion['reasoning'] as String,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              
              if (opinion['timeframe'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Timeframe: ${(opinion['timeframe'] as String).replaceAll('-', ' ').toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Advice
        if (advice != null) ...[
          _buildSectionCard(
            'Investment Advice',
            Icons.lightbulb,
            [
              if (advice['forBeginners'] != null)
                Text(
                  advice['forBeginners'] as String,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              if (advice['nextSteps'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Next Steps:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice['nextSteps'] as String,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Risk
        if (risk != null) ...[
          _buildSectionCard(
            'Risk Assessment',
            Icons.warning,
            [
              if (risk['level'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRiskColor(risk['level'] as String).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (risk['level'] as String).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRiskColor(risk['level'] as String),
                    ),
                  ),
                ),
              if (risk['explanation'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  risk['explanation'] as String,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Learning Tip
        if (learningTip != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    learningTip,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // DISCLAIMER (always show)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  opinion?['disclaimer'] as String? ?? 
                  '⚠️ This is educational analysis based on current data, NOT financial advice. Always do your own research and never invest money you can\'t afford to lose. AI analysis can be wrong!',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin for compactness
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - compact design
          Container(
            padding: const EdgeInsets.all(10), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5), // Smaller icon container
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: const Color(0xFF0052FF), size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content - compact padding
          Padding(
            padding: const EdgeInsets.all(10), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactMetricCard(Map<String, dynamic> metric) {
    final name = metric['name'] as String? ?? '';
    final value = metric['value'] as String? ?? 'N/A';
    final explanation = metric['explanation'] as String? ?? '';
    
    return GestureDetector(
      onTap: () {
        _showMetricDetailModal(metric);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C2C54),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.info_outline, size: 11, color: Colors.grey[500]),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C2C54),
              ),
            ),
            // Don't show explanation in compact card - only show on tap
            // This makes cards much more compact like overview cards
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricCard(Map<String, dynamic> metric) {
    final name = metric['name'] as String? ?? '';
    final value = metric['value'] as String? ?? 'N/A';
    final explanation = metric['explanation'] as String? ?? '';
    
    return GestureDetector(
      onTap: () {
        _showMetricDetailModal(metric);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C2C54),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C2C54),
              ),
            ),
            if (explanation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                explanation,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showMetricDetailModal(Map<String, dynamic> metric) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metric['name'] as String? ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C54),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Value
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.blue, size: 32),
                    const SizedBox(width: 16),
                    Text(
                      metric['value'] as String? ?? 'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // What it means
              if (metric['explanation'] != null) ...[
                Text(
                  'What it means:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  metric['explanation'] as String,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 16),
              ],
              
              // Significance
              if (metric['significance'] != null) ...[
                Text(
                  'Why it matters:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  metric['significance'] as String,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 16),
              ],
              
              // What good looks like
              if (metric['whatGoodLooks'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, color: Colors.green[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What\'s Good?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              metric['whatGoodLooks'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.3,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'high':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
  
  Widget _buildIndicatorExplanation(String name, String value, String explanation, String whatItTellsUs, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            explanation,
            style: GoogleFonts.inter(
              fontSize: 10,
              height: 1.2,
              color: const Color(0xFF6B7280),
            ),
            maxLines: 2, // Reduced from 3 to 2 for more compact cards
            overflow: TextOverflow.ellipsis,
          ),
          // Removed whatItTellsUs section to make cards more compact
        ],
      ),
    );
  }
  
  Color _getStanceColor(String stance) {
    switch (stance.toLowerCase()) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      case 'hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStanceIcon(String stance) {
    switch (stance.toLowerCase()) {
      case 'buy':
        return Icons.arrow_upward;
      case 'sell':
        return Icons.arrow_downward;
      case 'hold':
        return Icons.pause;
      default:
        return Icons.help_outline;
    }
  }
  
  Widget _buildNewsAnalysisSection(dynamic newsAnalysisData) {
    if (newsAnalysisData == null) return const SizedBox.shrink();
    
    final newsAnalysis = newsAnalysisData is List ? newsAnalysisData : [];
    if (newsAnalysis.isEmpty) return const SizedBox.shrink();
    
    return _buildSectionCard(
      'Market News Explained',
      Icons.newspaper,
      [
        const SizedBox(height: 4),
        ...newsAnalysis.map<Widget>((newsItem) {
          final news = newsItem as Map<String, dynamic>;
          final isGood = (news['isGoodOrBad'] as String?)?.toLowerCase() == 'good';
          final isBad = (news['isGoodOrBad'] as String?)?.toLowerCase() == 'bad';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isGood 
                  ? Colors.green[50] 
                  : isBad 
                      ? Colors.red[50] 
                      : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isGood 
                    ? Colors.green[200]! 
                    : isBad 
                        ? Colors.red[200]! 
                        : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
                Row(
                  children: [
                    Icon(
                      isGood 
                          ? Icons.trending_up 
                          : isBad 
                              ? Icons.trending_down 
                              : Icons.info_outline,
                      size: 18,
                      color: isGood 
                          ? Colors.green[700] 
                          : isBad 
                              ? Colors.red[700] 
                              : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        news['headline'] as String? ?? 'News Article',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (news['source'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          news['source'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // What it means
                if (news['whatItMeans'] != null) ...[
                  Text(
                    'What it means:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    news['whatItMeans'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                
                // Why it matters
                if (news['whyItMatters'] != null) ...[
                  Text(
                    'Why it matters:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    news['whyItMatters'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                
                // Price impact
                if (news['priceImpact'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isGood 
                            ? Colors.green[300]! 
                            : isBad 
                                ? Colors.red[300]! 
                                : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isGood 
                              ? Icons.arrow_upward 
                              : isBad 
                                  ? Icons.arrow_downward 
                                  : Icons.remove,
                          size: 16,
                          color: isGood 
                              ? Colors.green[700] 
                              : isBad 
                                  ? Colors.red[700] 
                                  : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price Impact:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                news['priceImpact'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isGood 
                                      ? Colors.green[900] 
                                      : isBad 
                                          ? Colors.red[900] 
                                          : Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Real-world example (if available)
                if (news['realWorldExample'] != null && (news['realWorldExample'] as String).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            news['realWorldExample'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildConfidenceChip(dynamic confidence) {
    // Handle both old format (string) and new format (number 1-10)
    int confidenceScore;
    String confidenceText;
    Color confidenceColor;
    
    if (confidence is int || confidence is double) {
      // New format: number 1-10
      confidenceScore = (confidence is double ? confidence.round() : confidence as int);
      confidenceScore = confidenceScore.clamp(1, 10);
      
      if (confidenceScore >= 8) {
        confidenceText = 'Very High ($confidenceScore/10)';
        confidenceColor = Colors.green;
      } else if (confidenceScore >= 6) {
        confidenceText = 'High ($confidenceScore/10)';
        confidenceColor = Colors.lightGreen;
      } else if (confidenceScore >= 4) {
        confidenceText = 'Medium ($confidenceScore/10)';
        confidenceColor = Colors.orange;
      } else {
        confidenceText = 'Low ($confidenceScore/10)';
        confidenceColor = Colors.red;
      }
    } else {
      // Old format: string (backward compatibility)
      final confStr = (confidence as String).toLowerCase();
      if (confStr == 'high') {
        confidenceText = 'High Confidence';
        confidenceColor = Colors.green;
      } else if (confStr == 'medium') {
        confidenceText = 'Medium Confidence';
        confidenceColor = Colors.orange;
      } else {
        confidenceText = 'Low Confidence';
        confidenceColor = Colors.red;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: confidenceColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: confidenceColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insights,
            size: 14,
            color: confidenceColor,
          ),
          const SizedBox(width: 6),
          Text(
            confidenceText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: confidenceColor,
            ),
          ),
        ],
      ),
    );
  }
}
