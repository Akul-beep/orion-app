// Utility script to add tracking to all remaining screens
// This file documents the pattern for adding tracking

/*
PATTERN FOR ADDING TRACKING TO ANY SCREEN:

1. Add import:
import '../services/user_progress_service.dart';

2. Add screen visit tracking in initState:
@override
void initState() {
  super.initState();
  // ... existing code ...
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    UserProgressService().trackScreenVisit(
      screenName: 'ScreenName',
      screenType: 'main', // or 'detail', 'modal'
      metadata: {'custom': 'data'},
    );
  });
}

3. Track widget interactions:
onTap: () async {
  await UserProgressService().trackWidgetInteraction(
    screenName: 'ScreenName',
    widgetType: 'button', // or 'card', 'tab', etc.
    actionType: 'tap', // or 'swipe', 'long_press'
    widgetId: 'button_id',
    interactionData: {'data': 'value'},
  );
  // Perform action
}

4. Track navigation:
await UserProgressService().trackNavigation(
  fromScreen: 'CurrentScreen',
  toScreen: 'NextScreen',
  navigationMethod: 'push', // or 'pop', 'replace', 'tab_switch'
  navigationData: {'data': 'value'},
);
Navigator.push(context, MaterialPageRoute(...));

5. Track learning progress (for lesson screens):
await UserProgressService().trackLearningProgress(
  lessonId: 'lesson_id',
  lessonName: 'Lesson Name',
  progressPercentage: 50,
  timeSpentSeconds: 120,
  completed: false,
);

6. Track trading activity (for trading screens):
await UserProgressService().trackTradingActivity(
  activityType: 'view_stock', // or 'add_watchlist', 'execute_buy', etc.
  symbol: 'AAPL',
  activityData: {'custom': 'data'},
);
*/






