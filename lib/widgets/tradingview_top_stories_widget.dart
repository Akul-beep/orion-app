import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// TradingView Top Stories Widget
/// Displays market news and top stories from TradingView
/// Reference: https://in.tradingview.com/widget/#topstories
class TradingViewTopStoriesWidget extends StatefulWidget {
  final double height;
  final String theme; // 'light' or 'dark'
  final String locale; // 'en', 'in', etc.

  const TradingViewTopStoriesWidget({
    super.key,
    this.height = 400,
    this.theme = 'light',
    this.locale = 'en',
  });

  @override
  State<TradingViewTopStoriesWidget> createState() => _TradingViewTopStoriesWidgetState();
}

class _TradingViewTopStoriesWidgetState extends State<TradingViewTopStoriesWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            print('📰 TradingView Top Stories page finished: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ TradingView Top Stories error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow navigation to TradingView
            if (request.url.contains('tradingview.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );
    
    // Load TradingView Top Stories widget HTML
    _controller.loadHtmlString(_getTopStoriesHTML(), baseUrl: 'https://in.tradingview.com');
    
    // Fallback timeout
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        print('⏱️ TradingView Top Stories loading timeout - marking as loaded');
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  String _getTopStoriesHTML() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>TradingView Top Stories</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: ${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'};
            overflow: hidden;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        #tradingview_topstories {
            width: 100%;
            height: ${widget.height}px;
            position: relative;
        }
        .loading {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100%;
            background: ${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'};
            color: ${widget.theme == 'dark' ? '#ffffff' : '#000000'};
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
    <div id="tradingview_topstories">
        <div class="loading">Loading market news...</div>
    </div>
    
    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-timeline.js" async>
    {
        "feedMode": "all_symbols",
        "colorTheme": "${widget.theme}",
        "isTransparent": false,
        "displayMode": "regular",
        "width": "100%",
        "height": "${widget.height}",
        "locale": "${widget.locale}"
    }
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (_isLoading)
              Container(
                color: widget.theme == 'dark' ? const Color(0xFF1e1e1e) : Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
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
                        'Failed to load market news',
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
  }

  Widget _buildWebWidget() {
    // For web, show a placeholder or use iframe
    return Container(
      color: widget.theme == 'dark' ? const Color(0xFF1e1e1e) : Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.newspaper, size: 48, color: Color(0xFF0052FF)),
            const SizedBox(height: 16),
            Text(
              'Market News & Top Stories',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Web view - News feed',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

