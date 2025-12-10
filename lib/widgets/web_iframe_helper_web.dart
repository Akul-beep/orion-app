// Web-specific implementation
import 'package:flutter/widgets.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebIframeHelper {
  static Widget createIframe({
    required String viewId,
    required String htmlContent,
    required double height,
  }) {
    // Wrap the HTML content in a full HTML document for iframe srcdoc
    // TradingView widgets need proper HTML structure to execute scripts
    final fullHtml = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; overflow: hidden; }
        .tradingview-widget-container { width: 100%; height: 100%; }
        .tradingview-widget-container__widget { width: 100%; height: 100%; }
        .blue-text { color: #2196F3; }
        .trademark { color: #999999; }
    </style>
</head>
<body>
$htmlContent
</body>
</html>
    ''';
    
    // Use iframe with srcdoc to properly execute scripts
    final iframe = html.IFrameElement()
      ..srcdoc = fullHtml
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '${height}px'
      ..style.margin = '0'
      ..style.padding = '0'
      ..allowFullscreen = true
      ..allow = 'clipboard-read; clipboard-write';
    
    // Register the platform view
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) => iframe);
    
    return HtmlElementView(viewType: viewId);
  }
}


