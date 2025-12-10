// Web-specific implementation
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

/// Initialize WebView platform for web
void initializeWebViewPlatform() {
  WebViewPlatform.instance = WebWebViewPlatform();
}






