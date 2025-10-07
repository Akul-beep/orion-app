import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TradingViewWorkingWidget extends StatefulWidget {
  final String symbol;
  final double height;
  final String theme; // 'light' or 'dark'
  final bool showToolbar;
  final bool showVolume;
  final bool showLegend;
  final String interval; // '1', '5', '15', '30', '60', 'D', 'W', 'M'

  const TradingViewWorkingWidget({
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
  State<TradingViewWorkingWidget> createState() => _TradingViewWorkingWidgetState();
}

class _TradingViewWorkingWidgetState extends State<TradingViewWorkingWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadHtmlString(_generateTradingViewHTML());
  }

  String _generateTradingViewHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TradingView Widget</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body { 
            margin: 0; 
            padding: 0; 
            background: ${widget.theme == 'dark' ? '#0F0F0F' : '#FFFFFF'};
            overflow: hidden;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        
        .tradingview-widget-container { 
            height: 100vh; 
            width: 100%; 
            position: relative;
        }
        
        .tradingview-widget-container__widget { 
            height: calc(100% - 32px); 
            width: 100%; 
        }
        
        .tradingview-widget-copyright { 
            font-size: 10px; 
            color: ${widget.theme == 'dark' ? '#FFFFFF' : '#666666'}; 
            text-align: center; 
            padding: 8px;
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            background: ${widget.theme == 'dark' ? 'rgba(0,0,0,0.8)' : 'rgba(255,255,255,0.9)'};
            z-index: 1000;
        }
        
        .blue-text { 
            color: #2196F3; 
            text-decoration: none;
        }
        
        .trademark { 
            color: ${widget.theme == 'dark' ? '#CCCCCC' : '#999999'}; 
        }
        
        .loading-container {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            background: ${widget.theme == 'dark' ? '#0F0F0F' : '#FFFFFF'};
        }
        
        .loading-spinner {
            width: 40px;
            height: 40px;
            border: 3px solid ${widget.theme == 'dark' ? '#333' : '#f3f3f3'};
            border-top: 3px solid #2196F3;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .loading-text {
            margin-top: 16px;
            color: ${widget.theme == 'dark' ? '#FFFFFF' : '#333333'};
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="tradingview-widget-container" style="height:100%;width:100%">
        <div class="tradingview-widget-container__widget" style="height:calc(100% - 32px);width:100%"></div>
        <div class="tradingview-widget-copyright">
            <a href="https://www.tradingview.com/symbols/NASDAQ-${widget.symbol}/" rel="noopener nofollow" target="_blank">
                <span class="blue-text">${widget.symbol} stock chart</span>
            </a>
            <span class="trademark"> by TradingView</span>
        </div>
        
        <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js" async>
        {
            "allow_symbol_change": ${widget.showToolbar ? 'true' : 'false'},
            "autosize": true,
            "calendar": false,
            "details": false,
            "hide_side_toolbar": true,
            "hide_top_toolbar": ${!widget.showToolbar ? 'true' : 'false'},
            "hide_legend": ${!widget.showLegend ? 'true' : 'false'},
            "hide_volume": ${!widget.showVolume ? 'true' : 'false'},
            "hotlist": false,
            "interval": "${widget.interval}",
            "locale": "en",
            "save_image": true,
            "style": "1",
            "symbol": "NASDAQ:${widget.symbol}",
            "theme": "${widget.theme}",
            "timezone": "Etc/UTC",
            "toolbar_bg": "${widget.theme == 'dark' ? '#1e1e1e' : '#f1f3f6'}",
            "enable_publishing": false,
            "withdateranges": false,
            "range": false,
            "studies": [],
            "container_id": "tradingview_${widget.symbol.toLowerCase()}",
            "width": "100%",
            "height": "100%"
        }
        </script>
    </div>
</body>
</html>
    ''';
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
            // TradingView WebView
            if (_isLoading)
              _buildLoadingState()
            else if (_hasError)
              _buildErrorState()
            else
              _buildTradingViewWebView(),
            
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
                _initializeWebView();
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

  Widget _buildTradingViewWebView() {
    return WebViewWidget(controller: _controller);
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
              _initializeWebView();
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
                    child: TradingViewWorkingWidget(
                      symbol: widget.symbol,
                      height: MediaQuery.of(context).size.height * 0.9 - 80,
                      theme: widget.theme,
                      showToolbar: widget.showToolbar,
                      showVolume: widget.showVolume,
                      showLegend: widget.showLegend,
                      interval: widget.interval,
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
