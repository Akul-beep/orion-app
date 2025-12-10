import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/company_profile.dart';
import '../utils/stock_utils.dart';
import 'web_iframe_helper.dart' if (dart.library.html) 'web_iframe_helper_web.dart';

class TradingViewMobileChart extends StatefulWidget {
  final String symbol;
  final CompanyProfile? profile; // Optional profile for ETF detection
  final double height;
  final String theme;
  final bool showToolbar;
  final bool showVolume;
  final bool showLegend;
  final String interval;
  final VoidCallback? onTap;

  const TradingViewMobileChart({
    super.key,
    required this.symbol,
    this.profile,
    this.height = 250,
    this.theme = 'light',
    this.showToolbar = true,
    this.showVolume = true,
    this.showLegend = true,
    this.interval = 'D',
    this.onTap,
  });

  @override
  State<TradingViewMobileChart> createState() => _TradingViewMobileChartState();
}

class _TradingViewMobileChartState extends State<TradingViewMobileChart> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
    } else {
      // On web, mark as loaded immediately so the widget renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = false;
          });
        }
      });
    }
  }

  void _initializeWebView() {
    if (kIsWeb) {
      // Skip WebView initialization on web
      return;
    }
    
    // Get the formatted symbol to check if it's Indian
    final formattedSymbol = _getSymbolForTradingView();
    final isIndianStock = formattedSymbol.startsWith('NSE:') || formattedSymbol.startsWith('BSE:');
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('📊 WebView page started: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            print('📊 WebView page finished: $url');
            // Give extra time for TradingView widget to render
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            print('   Error code: ${error.errorCode}');
            print('   Error type: ${error.errorType}');
            print('   Failed URL: ${error.url}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔗 Navigation request: ${request.url}');
            // Allow navigation to TradingView domains and resources
            if (request.url.contains('tradingview.com') || 
                request.url.contains('tradingview-widget.com') ||
                request.url.contains('s3.tradingview.com') ||
                request.url.startsWith('data:') || 
                request.url.startsWith('about:blank') ||
                request.url.startsWith('blob:')) {
              print('✅ Allowing navigation: ${request.url}');
              return NavigationDecision.navigate;
            }
            print('🚫 Blocking navigation: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      );
    
    // Load HTML content
    _controller.loadHtmlString(_getTradingViewMobileHTML(), baseUrl: 'https://www.tradingview.com');
    
    // Fallback timeout - increased for widget loading
    Future.delayed(Duration(seconds: isIndianStock ? 10 : 8), () {
      if (mounted && _isLoading) {
        print('⏱️ WebView loading timeout - marking as loaded');
        setState(() {
          _isLoading = false;
          // Don't set error if it's just slow loading
        });
      }
    });
  }
  
  String _getSymbolForTradingView() {
    // Use StockUtils to dynamically detect ETF and get proper exchange prefix
    // This handles both US and Indian stocks correctly
    String symbol = StockUtils.getTradingViewSymbol(widget.symbol, widget.profile);
    
    // Special handling for SPY - ensure it uses ARCA prefix
    if (widget.symbol.toUpperCase() == 'SPY') {
      // SPY trades on NYSE Arca, use ARCA prefix
      if (!symbol.startsWith('ARCA:') && !symbol.startsWith('AMEX:')) {
        symbol = 'ARCA:${widget.symbol}';
      }
    }
    
    // Debug logging
    print('📊 [TradingView Widget] Symbol conversion: ${widget.symbol} → $symbol');
    if (widget.profile != null) {
      print('   Profile exchange: ${widget.profile!.exchange}, currency: ${widget.profile!.currency}');
    } else {
      print('   No profile provided, using symbol-based detection');
    }
    
    return symbol;
  }

  String _getTradingViewMobileHTML() {
    // Get the properly formatted symbol with exchange prefix
    final formattedSymbol = _getSymbolForTradingView();
    
    print('📊 [TradingView] Using symbol: $formattedSymbol for ${widget.symbol}');
    
    // Check if this is an Indian stock (NSE/BSE)
    final isIndianStock = formattedSymbol.startsWith('NSE:') || formattedSymbol.startsWith('BSE:');
    
    if (isIndianStock) {
      // For Indian stocks, TradingView widgets don't work
      return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>TradingView Mobile Chart</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: ${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'};
            overflow: hidden;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        .error {
            display: flex;
            align-items: center;
            justify-content: center;
            height: ${widget.height}px;
            background: ${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'};
            color: #ff4444;
            text-align: center;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="error">TradingView widgets don't support Indian stocks (NSE/BSE)<br>Please use the custom chart view</div>
</body>
</html>
      ''';
    }
    
    // For US stocks, use TradingView external embedding method with full features
    // This includes the indicators/studies panel (side toolbar)
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>TradingView Mobile Chart</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        html, body {
            width: 100% !important;
            min-width: 100% !important;
            max-width: 100% !important;
            height: 100%;
            margin: 0 !important;
            padding: 0 !important;
            overflow: hidden;
            background: ${widget.theme == 'dark' ? '#0F0F0F' : '#FFFFFF'};
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            touch-action: manipulation;
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            user-select: none;
        }
        .tradingview-widget-container {
            width: 100% !important;
            min-width: 100% !important;
            max-width: 100% !important;
            height: ${widget.height}px;
            position: relative;
            background: ${widget.theme == 'dark' ? '#0F0F0F' : '#FFFFFF'};
            overflow: visible;
            margin: 0 !important;
            padding: 0 !important;
        }
        .tradingview-widget-container__widget {
            width: 100% !important;
            min-width: 100% !important;
            max-width: 100% !important;
            height: calc(100% - 32px);
            overflow: visible;
            margin: 0 !important;
            padding: 0 !important;
        }
        .tradingview-widget-copyright {
            display: none !important;
        }
        .blue-text {
            color: #2196F3;
        }
        .trademark {
            color: ${widget.theme == 'dark' ? '#CCCCCC' : '#999999'};
        }
        .loading {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100%;
            background: ${widget.theme == 'dark' ? '#0F0F0F' : '#FFFFFF'};
            color: ${widget.theme == 'dark' ? '#FFFFFF' : '#000000'};
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            z-index: 5;
        }
        .error {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100%;
            background: ${widget.theme == 'dark' ? '#0F0F0F' : '#FFFFFF'};
            color: #ff4444;
            text-align: center;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="tradingview-widget-container" style="height:${widget.height}px;width:100%!important;min-width:100%!important;max-width:100%!important;margin:0!important;padding:0!important">
        <div class="tradingview-widget-container__widget" style="height:100%;width:100%!important;min-width:100%!important;max-width:100%!important;margin:0!important;padding:0!important"></div>
        <div class="tradingview-widget-copyright">
            <a href="https://www.tradingview.com/symbols/${formattedSymbol.replaceAll(':', '-')}/" rel="noopener nofollow" target="_blank">
                <span class="blue-text">${widget.symbol} stock chart</span>
            </a>
            <span class="trademark"> by TradingView</span>
        </div>
        <div class="loading" id="loading">Loading ${widget.symbol} chart...</div>
        <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js" async>
        {
            "autosize": true,
            "symbol": "${formattedSymbol.replaceAll('"', '\\"')}",
            "interval": "${widget.interval}",
            "timezone": "exchange",
            "theme": "${widget.theme}",
            "style": "1",
            "locale": "en",
            "allow_symbol_change": false,
            "hide_top_toolbar": ${!widget.showToolbar ? 'true' : 'false'},
            "hide_legend": ${!widget.showLegend ? 'true' : 'false'},
            "hide_volume": ${!widget.showVolume ? 'true' : 'false'},
            "save_image": false,
            "calendar": false,
            "details": false,
            "hotlist": false,
            "hide_side_toolbar": true,
            "toolbar_bg": "${widget.theme == 'dark' ? '#1e1e1e' : '#f1f3f6'}",
            "enable_publishing": false,
            "withdateranges": false,
            "range": false,
            "studies": ${widget.showVolume ? '["Volume@tv-basicstudies"]' : '[]'},
            "backgroundColor": "${widget.theme == 'dark' ? '#0F0F0F' : '#FFFFFF'}",
            "gridColor": "${widget.theme == 'dark' ? 'rgba(242, 242, 242, 0.06)' : 'rgba(242, 242, 242, 0.5)'}",
            "watchlist": [],
            "compareSymbols": [],
            "width": "100%",
            "height": "100%"
        }
        </script>
    </div>
    <script type="text/javascript">
        // Hide loading message once widget loads
        window.addEventListener('load', function() {
            setTimeout(function() {
                var loadingDiv = document.getElementById('loading');
                if (loadingDiv) {
                    loadingDiv.style.display = 'none';
                }
            }, 3000);
        });
        
        // Also try to hide loading after a delay (fallback)
        setTimeout(function() {
            var loadingDiv = document.getElementById('loading');
            if (loadingDiv && loadingDiv.style.display !== 'none') {
                loadingDiv.style.display = 'none';
            }
        }, 5000);
        
        console.log('✅ TradingView widget script loaded for: $formattedSymbol');
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    // Use full screen width instead of fixed 470px
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.theme == 'dark' ? const Color(0xFF0F0F0F) : Colors.white,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth, // Use full available width
            height: widget.height,
            child: Stack(
              children: [
              // WebView Content - No overlays to ensure full interaction
              if (_isLoading)
                Container(
                  color: widget.theme == 'dark' ? const Color(0xFF1e1e1e) : Colors.white,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C2C54)),
                    ),
                  ),
                )
              else if (_hasError)
                Container(
                  color: widget.theme == 'dark' ? const Color(0xFF1e1e1e) : Colors.white,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load chart',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else if (kIsWeb)
                // For web, use HTML iframe to embed TradingView
                _buildWebChartIframe()
              else
                WebViewWidget(controller: _controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebChartIframe() {
    // For web, use iframe to embed TradingView widget
    final formattedSymbol = _getSymbolForTradingView();
    final isIndianStock = formattedSymbol.startsWith('NSE:') || formattedSymbol.startsWith('BSE:');
    
    if (isIndianStock) {
      return Container(
        color: widget.theme == 'dark' ? const Color(0xFF1e1e1e) : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'TradingView widgets don\'t support Indian stocks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please use the custom chart view',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Map interval to TradingView format
    String tradingViewInterval = '1D';
    switch (widget.interval) {
      case '1':
        tradingViewInterval = '1';
        break;
      case '5':
        tradingViewInterval = '5';
        break;
      case '15':
        tradingViewInterval = '15';
        break;
      case '30':
        tradingViewInterval = '30';
        break;
      case '60':
        tradingViewInterval = '60';
        break;
      case 'D':
        tradingViewInterval = '1D';
        break;
      case 'W':
        tradingViewInterval = '1W';
        break;
      case 'M':
        tradingViewInterval = '1M';
        break;
      default:
        tradingViewInterval = '1D';
    }
    
    // Create a unique view ID for this widget
    final viewId = 'tradingview-chart-${widget.symbol}-${DateTime.now().millisecondsSinceEpoch}';
    
    // Build the HTML content for the TradingView widget - EXACT structure from TradingView
    final htmlContent = '''
<!-- TradingView Widget BEGIN -->
<div class="tradingview-widget-container" style="height:100%;width:100%">
  <div class="tradingview-widget-container__widget" style="height:calc(100% - 32px);width:100%"></div>
  <div class="tradingview-widget-copyright"><a href="https://www.tradingview.com/symbols/${formattedSymbol.replaceAll(':', '-')}/" rel="noopener nofollow" target="_blank"><span class="blue-text">${widget.symbol} stock chart</span></a><span class="trademark"> by TradingView</span></div>
  <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js" async>
  {
  "allow_symbol_change": ${widget.showToolbar},
  "calendar": false,
  "details": false,
  "hide_side_toolbar": true,
  "hide_top_toolbar": ${!widget.showToolbar},
  "hide_legend": ${!widget.showLegend},
  "hide_volume": ${!widget.showVolume},
  "hotlist": false,
  "interval": "$tradingViewInterval",
  "locale": "en",
  "save_image": true,
  "style": "1",
  "symbol": "${formattedSymbol.replaceAll('"', '\\"')}",
  "theme": "${widget.theme}",
  "timezone": "exchange",
  "backgroundColor": "${widget.theme == 'dark' ? '#0F0F0F' : '#FFFFFF'}",
  "gridColor": "${widget.theme == 'dark' ? 'rgba(242, 242, 242, 0.06)' : 'rgba(242, 242, 242, 0.5)'}",
  "watchlist": [],
  "withdateranges": false,
  "compareSymbols": [],
  "studies": ${widget.showVolume ? '["Volume@tv-basicstudies"]' : '[]'},
  "autosize": true
}
  </script>
</div>
<!-- TradingView Widget END -->
    ''';
    
    return Container(
      width: double.infinity,
      height: widget.height,
      color: widget.theme == 'dark' ? const Color(0xFF1e1e1e) : Colors.white,
      child: kIsWeb
          ? WebIframeHelper.createIframe(
              viewId: viewId,
              htmlContent: htmlContent,
              height: widget.height,
            )
          : Container(
              child: const Center(
                child: Text('Web chart not available on this platform'),
              ),
            ),
    );
  }
}
