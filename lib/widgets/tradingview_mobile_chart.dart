import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TradingViewMobileChart extends StatefulWidget {
  final String symbol;
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
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..loadHtmlString(_getTradingViewMobileHTML());
    
    // Simulate loading completion for web platform
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  String _getTradingViewMobileHTML() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>TradingView Mobile Chart</title>
    <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: ${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'};
            overflow: hidden;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            touch-action: manipulation;
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            -khtml-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
            -webkit-overflow-scrolling: touch;
            overscroll-behavior: contain;
            pointer-events: auto;
        }
        #tradingview_widget {
            width: 100%;
            height: ${widget.height}px;
            position: relative;
            pointer-events: auto;
            touch-action: manipulation;
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            -khtml-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
            -webkit-overflow-scrolling: touch;
            overscroll-behavior: contain;
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
    <div id="tradingview_widget">
        <div class="loading">Loading ${widget.symbol} chart...</div>
    </div>
    
    <script type="text/javascript">
        // Enhanced touch handling for better mobile interaction
        document.addEventListener('touchstart', function(e) {
            e.stopPropagation();
            // Prevent default to allow chart to handle touch
            if (e.target.closest('#tradingview_widget')) {
                e.preventDefault();
            }
        }, { passive: false });
        
        document.addEventListener('touchmove', function(e) {
            e.stopPropagation();
            // Allow chart panning and zooming
            if (e.target.closest('#tradingview_widget')) {
                e.preventDefault();
            }
        }, { passive: false });
        
        document.addEventListener('touchend', function(e) {
            e.stopPropagation();
        }, { passive: true });
        
        // Additional mouse events for better desktop interaction
        document.addEventListener('mousedown', function(e) {
            if (e.target.closest('#tradingview_widget')) {
                e.stopPropagation();
            }
        });
        
        document.addEventListener('mousemove', function(e) {
            if (e.target.closest('#tradingview_widget')) {
                e.stopPropagation();
            }
        });
        
        try {
            new TradingView.widget({
                "width": "100%",
                "height": "${widget.height}",
                "symbol": "${widget.symbol}",
                "interval": "${widget.interval}",
                "timezone": "exchange",
                "theme": "${widget.theme}",
                "style": "1",
                "locale": "en",
                "toolbar_bg": "${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'}",
                "enable_publishing": false,
                "hide_top_toolbar": ${!widget.showToolbar},
                "hide_legend": ${!widget.showLegend},
                "save_image": false,
                "show_popup_button": false,
                "container_id": "tradingview_widget",
                "studies": [
                    ${widget.showVolume ? '"Volume@tv-basicstudies"' : ''}
                ],
                "overrides": {
                    "paneProperties.background": "${widget.theme == 'dark' ? '#1e1e1e' : '#ffffff'}",
                    "paneProperties.vertGridProperties.color": "${widget.theme == 'dark' ? '#2a2a2a' : '#e1e1e1'}",
                    "paneProperties.horzGridProperties.color": "${widget.theme == 'dark' ? '#2a2a2a' : '#e1e1e1'}",
                    "symbolWatermarkProperties.transparency": 90,
                    "scalesProperties.textColor": "${widget.theme == 'dark' ? '#ffffff' : '#000000'}"
                },
                "enabled_features": [
                    "side_toolbar_in_fullscreen_mode",
                    "mobile_support",
                    "hide_last_na_study_output",
                    "side_toolbar_in_fullscreen_mode",
                    "touch_events",
                    "gesture_events",
                    "pan_gesture",
                    "zoom_gesture"
                ],
                "disabled_features": [
                    "use_localstorage_for_settings",
                    "volume_force_overlay",
                    "create_volume_indicator_by_default",
                    "show_popup_button",
                    "popup_width",
                    "popup_height",
                    "header_symbol_search",
                    "header_compare",
                    "header_screenshot",
                    "header_widget"
                ],
                "withdateranges": true,
                "hide_side_toolbar": false,
                "allow_symbol_change": true,
                "save_image": false,
                "hide_top_toolbar": false
            });
        } catch (error) {
            document.getElementById('tradingview_widget').innerHTML = 
                '<div class="error">Failed to load chart for ${widget.symbol}<br>Error: ' + error.message + '</div>';
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
            else
              WebViewWidget(controller: _controller),
          ],
        ),
      ),
    );
  }
}
