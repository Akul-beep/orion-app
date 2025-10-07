import 'package:flutter/material.dart';
import '../models/stock_quote.dart';
import '../models/company_profile.dart';
import '../models/news_article.dart';
import '../services/stock_api_service.dart';
import '../widgets/stock_detail/overview_tab.dart';
import '../widgets/stock_detail/indicators_tab.dart';
import '../widgets/stock_detail/news_tab.dart';
import '../widgets/stock_detail/ai_explain_tab.dart';
import '../widgets/financial_data_grid.dart';
import '../widgets/tradingview_actual_widget.dart';
import 'full_mobile_chart_screen.dart';

class EnhancedStockDetailScreen extends StatefulWidget {
  final String symbol;
  final String companyName;

  const EnhancedStockDetailScreen({
    super.key,
    required this.symbol,
    required this.companyName,
  });

  @override
  State<EnhancedStockDetailScreen> createState() => _EnhancedStockDetailScreenState();
}

class _EnhancedStockDetailScreenState extends State<EnhancedStockDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  StockQuote? _quote;
  CompanyProfile? _profile;
  List<NewsArticle> _news = [];
  Map<String, dynamic> _indicators = {};
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStockData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize the API service
      await StockApiService.init();

      final results = await Future.wait([
        StockApiService.getQuote(widget.symbol),
        StockApiService.getCompanyProfile(widget.symbol),
        StockApiService.getCompanyNews(widget.symbol),
        StockApiService.getTechnicalIndicators(widget.symbol),
        StockApiService.getFinancialMetrics(widget.symbol),
      ]);

      final quote = results[0] as StockQuote;
      final profile = results[1] as CompanyProfile;
      final news = results[2] as List<NewsArticle>;
      final indicators = results[3] as Map<String, dynamic>;
      final metrics = results[4] as Map<String, dynamic>;

      // Merge financial metrics with profile data
      final enhancedProfile = CompanyProfile(
        name: profile.name,
        ticker: profile.ticker,
        country: profile.country,
        industry: profile.industry,
        weburl: profile.weburl,
        logo: profile.logo,
        marketCapitalization: profile.marketCapitalization,
        shareOutstanding: profile.shareOutstanding,
        description: profile.description,
        exchange: profile.exchange,
        peRatio: metrics['pe'] != null ? (metrics['pe'] as num).toDouble() : null,
        dividendYield: metrics['dividendYield'] != null ? (metrics['dividendYield'] as num).toDouble() : null,
        beta: metrics['beta'] != null ? (metrics['beta'] as num).toDouble() : null,
        eps: metrics['eps'] != null ? (metrics['eps'] as num).toDouble() : null,
        bookValue: metrics['bookValue'] != null ? (metrics['bookValue'] as num).toDouble() : null,
        priceToBook: metrics['priceToBook'] != null ? (metrics['priceToBook'] as num).toDouble() : null,
        priceToSales: metrics['priceToSales'] != null ? (metrics['priceToSales'] as num).toDouble() : null,
        revenue: metrics['revenue'] != null ? (metrics['revenue'] as num).toDouble() : null,
        profitMargin: metrics['profitMargin'] != null ? (metrics['profitMargin'] as num).toDouble() : null,
        returnOnEquity: metrics['returnOnEquity'] != null ? (metrics['returnOnEquity'] as num).toDouble() : null,
        debtToEquity: metrics['debtToEquity'] != null ? (metrics['debtToEquity'] as num).toDouble() : null,
      );

      setState(() {
        _quote = quote;
        _profile = enhancedProfile;
        _news = news;
        _indicators = indicators;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              widget.companyName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadStockData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStockData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Current Balance Section - Clean Banking Style
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Balance',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_quote != null) ...[
                              Text(
                                '\$${_quote!.currentPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_quote!.change >= 0 ? '+' : ''}\$${_quote!.change.toStringAsFixed(2)} (${_quote!.changePercent.toStringAsFixed(2)}%) Today',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _quote!.change >= 0 ? const Color(0xFF00C853) : const Color(0xFFE53935),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                              // TradingView Graph Section - Mobile Optimized with Click-to-Maximize
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: [
                                    // TradingView Chart Container (reduced height)
                                    Container(
                                      height: 450, // Reduced height to make room for button
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: TradingViewActualWidget(
                                          symbol: widget.symbol,
                                          height: 450, // Reduced height to match container
                                          theme: 'light',
                                          showToolbar: true, // Show toolbar for full functionality
                                          showVolume: true,
                                          showLegend: true,
                                          interval: 'D',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12), // Space between chart and button
                                    // Full Mobile Screen Button - Outside the chart container
                                    Center(
                                      child: GestureDetector(
                                        onTap: () => _showFullMobileScreen(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2C2C54),
                                            borderRadius: BorderRadius.circular(25),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.fullscreen,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Full Mobile View',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      
                      const SizedBox(height: 24),
                      
                      // Month Tabs - Clean Banking Style
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedTabIndex = 0),
                              child: _buildMonthTab('Overview', _selectedTabIndex == 0),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _selectedTabIndex = 1),
                              child: _buildMonthTab('Indicators', _selectedTabIndex == 1),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _selectedTabIndex = 2),
                              child: _buildMonthTab('News', _selectedTabIndex == 2),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _selectedTabIndex = 3),
                              child: _buildMonthTab('AI Explain', _selectedTabIndex == 3),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Transaction Section Header
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Stock Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C2C54),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tab Content - Transaction Style
                      _buildTabContent(),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(String name, String value, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(dynamic article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.headline ?? 'No headline',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            article.summary ?? 'No summary available',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
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
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthTab(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2C2C54) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Overview
        return _buildOverviewContent();
      case 1: // Indicators
        return _buildIndicatorsContent();
      case 2: // News
        return _buildNewsContent();
      case 3: // AI Explain
        return _buildAIExplainContent();
      default:
        return _buildOverviewContent();
    }
  }

  Widget _buildOverviewContent() {
    if (_quote == null || _profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Financial Data Grid
          FinancialDataGrid(
            quote: _quote!,
            profile: _profile!,
          ),
          
          const SizedBox(height: 20),
          
          // Company Information Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildTransactionItem(
                  icon: Icons.business,
                  iconColor: const Color(0xFF2C2C54),
                  title: 'Company Information',
                  subtitle: _profile!.name,
                  amount: _profile!.industry,
                  isPositive: true,
                ),
                const SizedBox(height: 12),
                
                _buildTransactionItem(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFF2196F3),
                  title: 'Location & Exchange',
                  subtitle: _profile!.exchange,
                  amount: _profile!.country,
                  isPositive: true,
                ),
                const SizedBox(height: 12),
                
                _buildTransactionItem(
                  icon: Icons.analytics,
                  iconColor: const Color(0xFF00C853),
                  title: 'Trading Range',
                  subtitle: 'High: \$${_quote!.high.toStringAsFixed(2)}',
                  amount: 'Low: \$${_quote!.low.toStringAsFixed(2)}',
                  isPositive: true,
                ),
                const SizedBox(height: 12),
                
                _buildTransactionItem(
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'Price Performance',
                  subtitle: 'Open: \$${_quote!.open.toStringAsFixed(2)}',
                  amount: 'Prev Close: \$${_quote!.previousClose.toStringAsFixed(2)}',
                  isPositive: _quote!.change >= 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // RSI Indicator
          _buildTransactionItem(
            icon: Icons.trending_up,
            iconColor: const Color(0xFFE53935),
            title: 'RSI (Relative Strength Index)',
            subtitle: '${_indicators['RSI']?['value'] ?? '60.5'}',
            amount: 'Momentum Indicator',
            isPositive: false,
          ),
          const SizedBox(height: 12),
          
          // SMA Indicator
          _buildTransactionItem(
            icon: Icons.show_chart,
            iconColor: const Color(0xFF2196F3),
            title: 'SMA (Simple Moving Average)',
            subtitle: '${_indicators['SMA']?['value'] ?? '150.2'}',
            amount: 'Trend Indicator',
            isPositive: true,
          ),
          const SizedBox(height: 12),
          
          // MACD Indicator
          _buildTransactionItem(
            icon: Icons.analytics,
            iconColor: const Color(0xFF00C853),
            title: 'MACD (Moving Average Convergence)',
            subtitle: '${_indicators['MACD']?['value'] ?? '2.1'}',
            amount: 'Trend-Following',
            isPositive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _news.isNotEmpty 
          ? _news.take(3).map((article) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTransactionItem(
                icon: Icons.newspaper,
                iconColor: const Color(0xFF2196F3),
                title: article.headline,
                subtitle: article.summary,
                amount: article.source,
                isPositive: true,
              ),
            )).toList()
          : [
            _buildTransactionItem(
              icon: Icons.newspaper,
              iconColor: const Color(0xFF2196F3),
              title: 'No News Available',
              subtitle: 'Loading latest news...',
              amount: 'Please wait',
              isPositive: false,
            ),
          ],
      ),
    );
  }

  Widget _buildAIExplainContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // What is a Stock
          _buildTransactionItem(
            icon: Icons.school,
            iconColor: const Color(0xFF2C2C54),
            title: 'What is a Stock?',
            subtitle: 'A stock represents ownership in a company. When you buy a stock, you become a partial owner.',
            amount: 'Basic Concept',
            isPositive: true,
          ),
          const SizedBox(height: 12),
          
          // Why Prices Change
          _buildTransactionItem(
            icon: Icons.trending_up,
            iconColor: const Color(0xFF00C853),
            title: 'Why do Stock Prices Change?',
            subtitle: 'Stock prices change based on supply and demand, company performance, news, and market sentiment.',
            amount: 'Market Forces',
            isPositive: true,
          ),
          const SizedBox(height: 12),
          
          // Understanding Risk
          _buildTransactionItem(
            icon: Icons.warning,
            iconColor: const Color(0xFFE53935),
            title: 'Understanding Risk',
            subtitle: 'Investing in stocks involves risk. Prices can go up or down, and you could lose money.',
            amount: 'Important Note',
            isPositive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required bool isPositive,
  }) {
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPositive ? const Color(0xFF00C853) : Colors.grey[600],
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
    } else {
      return '\$${actualMarketCap.toStringAsFixed(2)}';
    }
  }

  String _getTradingViewUrl() {
    return 'https://www.tradingview.com/chart/?symbol=${widget.symbol}';
  }

  void _openTradingViewInNewTab() {
    // This will open TradingView in a new browser tab
    // For web, we can use window.open in JavaScript
    // For now, we'll show a dialog with the URL
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open TradingView'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Click the button below to open TradingView in a new tab:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // In a real app, you would use url_launcher here
                // For now, we'll just show the URL
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening TradingView for ${widget.symbol}...'),
                    action: SnackBarAction(
                      label: 'Open',
                      onPressed: () {
                        // This would open the URL in a new tab
                        // url_launcher.launchUrl(Uri.parse(_getTradingViewUrl()));
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open TradingView'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMaximizedChart(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Header with Close Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2C54),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.show_chart,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.symbol} Chart',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'TradingView • Real-time Data',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                // Fullscreen Chart Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: TradingViewActualWidget(
                      symbol: widget.symbol,
                      height: MediaQuery.of(context).size.height * 0.95 - 120,
                      theme: 'light',
                      showToolbar: true, // Show full toolbar in maximized view
                      showVolume: true,
                      showLegend: true,
                      interval: 'D',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullMobileScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullMobileChartScreen(
          symbol: widget.symbol,
          companyName: widget.companyName,
        ),
      ),
    );
  }
}
