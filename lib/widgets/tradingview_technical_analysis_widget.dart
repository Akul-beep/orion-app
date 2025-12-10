import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/company_profile.dart';
import '../utils/stock_utils.dart';
import 'web_iframe_helper.dart' if (dart.library.html) 'web_iframe_helper_web.dart';

/// TradingView Technical Analysis Widget
/// Displays technical analysis ratings (Buy/Sell/Hold) for a stock
/// Reference: https://www.tradingview.com/widget-docs/widgets/symbol-details/technical-analysis/
class TradingViewTechnicalAnalysisWidget extends StatefulWidget {
  final String symbol;
  final CompanyProfile? profile; // Optional profile for exchange detection
  final double height;
  final String theme; // 'light' or 'dark'
  final String interval; // '1', '5', '15', '30', '60', 'D', 'W', 'M'

  const TradingViewTechnicalAnalysisWidget({
    super.key,
    required this.symbol,
    this.profile,
    this.height = 400,
    this.theme = 'light',
    this.interval = 'D',
  });

  @override
  State<TradingViewTechnicalAnalysisWidget> createState() => _TradingViewTechnicalAnalysisWidgetState();
}

class _TradingViewTechnicalAnalysisWidgetState extends State<TradingViewTechnicalAnalysisWidget> {
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('📊 TradingView Technical Analysis page started: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            print('📊 TradingView Technical Analysis page finished: $url');
            // Give extra time for widget to render
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ TradingView Technical Analysis error: ${error.description}');
            print('   Error code: ${error.errorCode}, Error type: ${error.errorType}');
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
    
    // Load TradingView Technical Analysis widget HTML
    _controller.loadHtmlString(_getTechnicalAnalysisHTML(), baseUrl: 'https://www.tradingview.com');
    
    // Fallback timeout - increased for widget loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        print('⏱️ TradingView Technical Analysis loading timeout - marking as loaded');
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  String _getSymbolForTradingView() {
    // Use StockUtils to get proper symbol format
    return StockUtils.getTradingViewSymbol(widget.symbol, widget.profile);
  }

  String _getTechnicalAnalysisHTML() {
    final formattedSymbol = _getSymbolForTradingView();
    
    // Check if this is an Indian stock (NSE/BSE)
    final isIndianStock = formattedSymbol.startsWith('NSE:') || formattedSymbol.startsWith('BSE:');
    
    if (isIndianStock) {
      return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>TradingView Technical Analysis</title>
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
    
    // Map interval to TradingView format
    String tradingViewInterval = '1m';
    switch (widget.interval) {
      case '1':
        tradingViewInterval = '1m';
        break;
      case '5':
        tradingViewInterval = '5m';
        break;
      case '15':
        tradingViewInterval = '15m';
        break;
      case '30':
        tradingViewInterval = '30m';
        break;
      case '60':
        tradingViewInterval = '1h';
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
        tradingViewInterval = '1m';
    }
    
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>TradingView Technical Analysis</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        html, body {
            width: 100%;
            height: 100%;
            overflow: hidden;
            background: ${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'};
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            touch-action: manipulation;
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            user-select: none;
        }
        .tradingview-widget-container {
            width: 100%;
            height: ${widget.height}px;
            position: relative;
            background: ${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'};
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
            margin: 0 auto;
            padding: 0;
        }
        .tradingview-widget-container__widget {
            width: 100% !important;
            max-width: 100% !important;
            height: calc(100% - 32px);
            border: none;
            overflow: hidden;
            margin: 0 auto;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .tradingview-widget-copyright {
            display: none !important;
        }
        .loading {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            background: ${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'};
            color: ${widget.theme == 'dark' ? '#ffffff' : '#000000'};
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            z-index: 5;
            padding: 20px;
            text-align: center;
        }
        .loading-spinner {
            width: 40px;
            height: 40px;
            border: 4px solid ${widget.theme == 'dark' ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'};
            border-top-color: ${widget.theme == 'dark' ? '#ffffff' : '#0052FF'};
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-bottom: 16px;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        .error {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100%;
            background: ${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'};
            color: #ff4444;
            text-align: center;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="tradingview-widget-container">
        <div class="tradingview-widget-container__widget"></div>
        <div class="tradingview-widget-copyright">
            <a href="https://www.tradingview.com/symbols/${formattedSymbol.replaceAll(':', '-')}/technicals/" rel="noopener nofollow" target="_blank">
                <span class="blue-text">${widget.symbol} stock analysis</span>
            </a>
            <span class="trademark"> by TradingView</span>
        </div>
        <div class="loading" id="loading">
            <div class="loading-spinner"></div>
            <div style="font-size: 14px; font-weight: 500; margin-bottom: 8px;">Loading Technical Analysis...</div>
            <div style="font-size: 12px; color: ${widget.theme == 'dark' ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.6)'};">This may take a few moments. Please wait.</div>
        </div>
        <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-technical-analysis.js" async>
        {
            "colorTheme": "${widget.theme}",
            "displayMode": "single",
            "isTransparent": false,
            "locale": "en",
            "interval": "$tradingViewInterval",
            "disableInterval": false,
            "width": "100%",
            "height": ${widget.height},
            "symbol": "${formattedSymbol.replaceAll('"', '\\"')}",
            "showIntervalTabs": true
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
        }, 8000);
        
        console.log('✅ TradingView technical analysis widget script loaded for: $formattedSymbol');
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SizedBox(
                width: constraints.maxWidth.clamp(0, 400),
                child: Stack(
                  children: [
                    if (_isLoading)
              Container(
                color: widget.theme == 'dark' ? const Color(0xFF1e1e1e) : Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Technical Analysis...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.theme == 'dark' ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take a few moments. Please wait.',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.theme == 'dark' ? Colors.white70 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
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
                        'Failed to load technical analysis',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else if (kIsWeb)
              _buildWebWidget()
            else
              WebViewWidget(controller: _controller),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWebWidget() {
    // For web, use iframe to embed TradingView Technical Analysis widget
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
                'Please use the custom indicators view',
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
        tradingViewInterval = '1m';
        break;
      case '5':
        tradingViewInterval = '5m';
        break;
      case '15':
        tradingViewInterval = '15m';
        break;
      case '30':
        tradingViewInterval = '30m';
        break;
      case '60':
        tradingViewInterval = '1h';
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
    final viewId = 'tradingview-ta-${widget.symbol}-${DateTime.now().millisecondsSinceEpoch}';
    
    // Build the HTML content for the TradingView Technical Analysis widget - EXACT structure
    final htmlContent = '''
<!-- TradingView Widget BEGIN -->
<div class="tradingview-widget-container" style="height:100%;width:100%">
  <div class="tradingview-widget-container__widget" style="height:100%;width:100%"></div>
  <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-technical-analysis.js" async>
  {
  "colorTheme": "${widget.theme}",
  "displayMode": "single",
  "isTransparent": false,
  "locale": "en",
  "interval": "$tradingViewInterval",
  "disableInterval": false,
  "width": "100%",
  "height": ${widget.height},
  "symbol": "${formattedSymbol.replaceAll('"', '\\"')}",
  "showIntervalTabs": true
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
                child: Text('Technical analysis not available on this platform'),
              ),
            ),
    );
  }
}

