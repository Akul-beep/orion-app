import 'package:flutter/foundation.dart';

/// Production-safe logging utility
/// In release mode, all logs are disabled to comply with App Store guidelines
class DebugLogger {
  /// Log debug information (only in debug mode)
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
  
  /// Log warnings (only in debug mode)
  static void warn(String message) {
    if (kDebugMode) {
      print('⚠️ $message');
    }
  }
  
  /// Log errors (only in debug mode)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack: $stackTrace');
      }
    }
  }
  
  /// Log success messages (only in debug mode)
  static void success(String message) {
    if (kDebugMode) {
      print('✅ $message');
    }
  }
  
  /// Log info messages (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ $message');
    }
  }
}

