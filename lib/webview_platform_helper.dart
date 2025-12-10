// Conditional import - uses web implementation on web, stub on other platforms
import 'webview_platform_helper_stub.dart'
    if (dart.library.html) 'webview_platform_helper_web.dart';

// Re-export the function
export 'webview_platform_helper_stub.dart'
    if (dart.library.html) 'webview_platform_helper_web.dart';

