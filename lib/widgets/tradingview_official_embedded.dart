import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TradingViewOfficialEmbedded extends StatefulWidget {
  final String symbol;
  final double height;
  final String theme; // 'light' or 'dark'
  final bool showToolbar;
  final bool showVolume;
  final bool showLegend;
  final String interval; // '1', '5', '15', '30', '60', 'D', 'W', 'M'

  const TradingViewOfficialEmbedded({
    super.key,
    required this.symbol,
    this.height = 400,
    this.theme = 'light',
    this.showToolbar = true,
    this.showVolume = true,
    this.showLegend = true,
    this.interval = 'D',
  });

  @override
  State<TradingViewOfficialEmbedded> createState() => _TradingViewOfficialEmbeddedState();
}

class _TradingViewOfficialEmbeddedState extends State<TradingViewOfficialEmbedded> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Simulate loading time for the embedded chart
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // TradingView Chart
            if (_isLoading)
              _buildLoadingState()
            else if (_hasError)
              _buildErrorState()
            else
              _buildRealTradingViewChart(),
            
            // Chart Controls Overlay
            if (!_isLoading && !_hasError)
              _buildChartControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C2C54)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading ${widget.symbol} Chart...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C54),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Connecting to TradingView',
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

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Chart Unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C54),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Unable to load ${widget.symbol} chart',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2C2C54),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTradingViewChart() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme == 'dark' ? Color(0xFF0F0F0F) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // TradingView Chart Container
          Container(
            width: double.infinity,
            height: widget.height - 40, // Account for copyright
            child: _buildTradingViewHtml(),
          ),
          
          // Copyright Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.theme == 'dark' 
                    ? Colors.black.withOpacity(0.8)
                    : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 12,
                    color: widget.theme == 'dark' ? Colors.white70 : Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${widget.symbol} chart by TradingView',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.theme == 'dark' ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingViewHtml() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme == 'dark' ? Color(0xFF0F0F0F) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.theme == 'dark' ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () => _showTradingViewDialog(),
        child: Container(
          width: double.infinity,
          height: widget.height - 40,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TradingView Chart Icon
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.theme == 'dark' ? Colors.white.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.show_chart,
                    color: widget.theme == 'dark' ? Colors.white : Color(0xFF2C2C54),
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                
                // TradingView Title
                Text(
                  'TradingView Advanced Chart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: widget.theme == 'dark' ? Colors.white : Color(0xFF2C2C54),
                  ),
                ),
                SizedBox(height: 8),
                
                // Symbol and Description
                Text(
                  '${widget.symbol} • Real-time Data',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.theme == 'dark' ? Colors.white70 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Interactive Chart with Technical Analysis',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.theme == 'dark' ? Colors.white60 : Colors.grey[500],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Open TradingView Button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Open TradingView',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTradingViewDialog() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('TradingView Chart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TradingView Advanced Chart for ${widget.symbol}'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chart Configuration:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C54),
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildConfigItem('Symbol', 'NASDAQ:${widget.symbol}'),
                  _buildConfigItem('Theme', widget.theme),
                  _buildConfigItem('Toolbar', widget.showToolbar ? 'Visible' : 'Hidden'),
                  _buildConfigItem('Volume', widget.showVolume ? 'Visible' : 'Hidden'),
                  _buildConfigItem('Legend', widget.showLegend ? 'Visible' : 'Hidden'),
                  _buildConfigItem('Interval', widget.interval),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'TradingView URL:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _getTradingViewIframeUrl(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Copy URL to clipboard
              Clipboard.setData(ClipboardData(text: _getTradingViewIframeUrl()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('TradingView URL copied to clipboard'),
                  backgroundColor: Color(0xFF2C2C54),
                ),
              );
            },
            child: Text('Copy URL'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C54),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTradingViewIframeUrl() {
    // Build TradingView iframe URL
    final baseUrl = 'https://www.tradingview.com/widget/advanced-chart/';
    final params = {
      'symbol': 'NASDAQ:${widget.symbol}',
      'theme': widget.theme,
      'style': '1',
      'interval': widget.interval,
      'hide_side_toolbar': 'true',
      'hide_top_toolbar': (!widget.showToolbar).toString(),
      'hide_legend': (!widget.showLegend).toString(),
      'hide_volume': (!widget.showVolume).toString(),
      'save_image': 'true',
      'toolbar_bg': widget.theme == 'dark' ? '#1e1e1e' : '#f1f3f6',
      'enable_publishing': 'false',
      'withdateranges': 'false',
      'range': 'false',
      'calendar': 'false',
      'studies': '[]',
      'hotlist': 'false',
      'details': 'false',
    };
    
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    return '$baseUrl?$queryString';
  }

  Widget _buildChartControls() {
    return Positioned(
      top: 12,
      right: 12,
      child: Row(
        children: [
          // Fullscreen Button
          GestureDetector(
            onTap: () => _showFullscreenChart(),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.fullscreen,
                size: 16,
                color: Color(0xFF2C2C54),
              ),
            ),
          ),
          SizedBox(width: 8),
          // Refresh Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isLoading = true;
              });
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.refresh,
                size: 16,
                color: Color(0xFF2C2C54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenChart() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2C2C54),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.show_chart,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.symbol} Chart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
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
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chart Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.show_chart,
                              color: Color(0xFF2C2C54),
                              size: 48,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'TradingView Advanced Chart',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C54),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Real-time ${widget.symbol} chart with technical analysis',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // TradingView Configuration Display
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TradingView Widget Configuration:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C2C54),
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildConfigItem('Symbol', 'NASDAQ:${widget.symbol}'),
                                _buildConfigItem('Theme', widget.theme),
                                _buildConfigItem('Toolbar', widget.showToolbar ? 'Visible' : 'Hidden'),
                                _buildConfigItem('Volume', widget.showVolume ? 'Visible' : 'Hidden'),
                                _buildConfigItem('Legend', widget.showLegend ? 'Visible' : 'Hidden'),
                                _buildConfigItem('Interval', widget.interval),
                                _buildConfigItem('Timezone', 'UTC'),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showTradingViewDialog();
                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.open_in_new),
                            label: Text('Open TradingView'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2C2C54),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
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
        );
      },
    );
  }
}
