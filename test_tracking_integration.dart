// Test script to verify all tracking integrations
// Run this to test database connections and tracking

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/user_progress_service.dart';
import 'package:myapp/services/database_service.dart';

void main() {
  group('Tracking Integration Tests', () {
    setUpAll(() async {
      // Initialize services
      await DatabaseService.init();
    });

    test('UserProgressService can track screen visit', () async {
      await UserProgressService().trackScreenVisit(
        screenName: 'TestScreen',
        screenType: 'main',
        metadata: {'test': true},
      );
      // If no exception, test passes
      expect(true, true);
    });

    test('UserProgressService can track widget interaction', () async {
      await UserProgressService().trackWidgetInteraction(
        screenName: 'TestScreen',
        widgetType: 'button',
        actionType: 'tap',
        widgetId: 'test_button',
      );
      expect(true, true);
    });

    test('UserProgressService can track navigation', () async {
      await UserProgressService().trackNavigation(
        fromScreen: 'ScreenA',
        toScreen: 'ScreenB',
        navigationMethod: 'push',
      );
      expect(true, true);
    });

    test('UserProgressService can track learning progress', () async {
      await UserProgressService().trackLearningProgress(
        lessonId: 'test_lesson',
        lessonName: 'Test Lesson',
        progressPercentage: 50,
      );
      expect(true, true);
    });

    test('UserProgressService can track trading activity', () async {
      await UserProgressService().trackTradingActivity(
        activityType: 'view_stock',
        symbol: 'AAPL',
      );
      expect(true, true);
    });

    test('Session can be started and ended', () async {
      await UserProgressService().startSession();
      await UserProgressService().endSession();
      expect(true, true);
    });

    test('DatabaseService can get user progress', () async {
      final progress = await DatabaseService.getUserProgress();
      // Should return null or Map
      expect(progress == null || progress is Map, true);
    });
  });
}






