import 'package:flutter/material.dart';
import '../services/user_progress_service.dart';

/// Mixin to automatically track screen visits and navigation
mixin ScreenTrackingMixin<T extends StatefulWidget> on State<T> {
  String get screenName;
  String get screenType => 'main';
  Map<String, dynamic> get screenMetadata => {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackScreenVisit();
    });
  }

  @override
  void dispose() {
    _trackScreenExit();
    super.dispose();
  }

  Future<void> _trackScreenVisit() async {
    await UserProgressService().trackScreenVisit(
      screenName: screenName,
      screenType: screenType,
      metadata: screenMetadata,
    );
  }

  Future<void> _trackScreenExit() async {
    // Time spent will be calculated when next screen is visited
    // This is handled by UserProgressService
  }

  /// Track widget interaction
  Future<void> trackInteraction({
    required String widgetType,
    required String actionType,
    String? widgetId,
    Map<String, dynamic>? interactionData,
  }) async {
    await UserProgressService().trackWidgetInteraction(
      screenName: screenName,
      widgetType: widgetType,
      actionType: actionType,
      widgetId: widgetId,
      interactionData: interactionData,
    );
  }

  /// Track navigation to another screen
  Future<void> trackNavigation({
    required String toScreen,
    String? navigationMethod,
    Map<String, dynamic>? navigationData,
  }) async {
    await UserProgressService().trackNavigation(
      fromScreen: screenName,
      toScreen: toScreen,
      navigationMethod: navigationMethod,
      navigationData: navigationData,
    );
  }

  /// Navigate with tracking
  Future<T?> navigateTo<T extends Object?>(
    BuildContext context,
    Widget screen, {
    String? navigationMethod,
    Map<String, dynamic>? navigationData,
  }) async {
    final screenName = screen.runtimeType.toString();
    await trackNavigation(
      toScreen: screenName,
      navigationMethod: navigationMethod ?? 'push',
      navigationData: navigationData,
    );
    
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Navigate with replacement and tracking
  Future<T?> navigateToReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget screen, {
    String? navigationMethod,
    Map<String, dynamic>? navigationData,
  }) async {
    final screenName = screen.runtimeType.toString();
    await trackNavigation(
      toScreen: screenName,
      navigationMethod: navigationMethod ?? 'replace',
      navigationData: navigationData,
    );
    
    return Navigator.pushReplacement<T, TO>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}






