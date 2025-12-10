import 'package:flutter/material.dart';
import '../services/user_progress_service.dart';

/// Helper class for consistent navigation with tracking
class NavigationHelper {
  /// Navigate to a screen with full tracking
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget screen, {
    String? fromScreen,
    Map<String, dynamic>? navigationData,
  }) async {
    final toScreen = screen.runtimeType.toString();
    
    // Track navigation
    await UserProgressService().trackNavigation(
      fromScreen: fromScreen,
      toScreen: toScreen,
      navigationMethod: 'push',
      navigationData: navigationData,
    );
    
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Navigate with replacement and tracking
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget screen, {
    String? fromScreen,
    Map<String, dynamic>? navigationData,
  }) async {
    final toScreen = screen.runtimeType.toString();
    
    // Track navigation
    await UserProgressService().trackNavigation(
      fromScreen: fromScreen,
      toScreen: toScreen,
      navigationMethod: 'replace',
      navigationData: navigationData,
    );
    
    return Navigator.pushReplacement<T, TO>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Pop with tracking
  static void pop<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) {
    Navigator.pop<T>(context, result);
  }

  /// Pop until condition with tracking
  static void popUntil(
    BuildContext context,
    bool Function(Route<dynamic>) predicate,
  ) {
    Navigator.popUntil(context, predicate);
  }
}






