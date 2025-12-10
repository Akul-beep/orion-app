// Stub file for non-web platforms
// This file is replaced by web_iframe_helper_web.dart on web

import 'package:flutter/widgets.dart';

class WebIframeHelper {
  static Widget createIframe({
    required String viewId,
    required String htmlContent,
    required double height,
  }) {
    // Stub implementation for non-web platforms
    return Container(
      height: height,
      child: Center(
        child: Text('Iframe not supported on this platform'),
      ),
    );
  }
}


