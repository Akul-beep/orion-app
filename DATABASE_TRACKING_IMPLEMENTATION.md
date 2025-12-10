# Database Tracking & Navigation Implementation

## Overview
This document outlines the comprehensive database tracking and navigation system implemented for the Orion app to ensure all user interactions, screen visits, and navigation flows are properly tracked and stored.

## Database Schema Enhancements

### New Tables Added

1. **user_screen_visits** - Tracks every screen visit with timing
   - Records screen name, type, visit time, and time spent
   - Includes metadata for context (symbol, action, etc.)

2. **user_widget_interactions** - Tracks all widget interactions
   - Records widget type, action type (tap, swipe, etc.)
   - Includes interaction data and context

3. **user_navigation_flows** - Tracks navigation between screens
   - Records from/to screens and navigation method
   - Tracks navigation data and context

4. **user_sessions** - Tracks user sessions
   - Session start/end times
   - Total screens visited and interactions per session

5. **user_progress** - Comprehensive user progress tracking
   - Last screen visited
   - Screen visit counts and time spent
   - Learning and trading progress
   - User preferences

6. **user_state_snapshots** - State persistence
   - Saves complete state snapshots for seamless experience

7. **learning_progress** - Detailed learning tracking
   - Lesson progress, completion status
   - Time spent, quiz scores

8. **trading_activity** - Trading activity tracking
   - All trading-related activities (view stock, add watchlist, etc.)
   - Symbol-specific tracking

## Services Created

### UserProgressService
Central service for tracking all user interactions:
- `startSession()` - Initialize new user session
- `endSession()` - End current session
- `trackScreenVisit()` - Track screen visits
- `trackWidgetInteraction()` - Track widget interactions
- `trackNavigation()` - Track navigation flows
- `trackLearningProgress()` - Track learning progress
- `trackTradingActivity()` - Track trading activities
- `updateUserProgress()` - Update comprehensive progress
- `saveStateSnapshot()` - Save state for persistence

### NavigationHelper
Helper class for consistent navigation with automatic tracking:
- `push()` - Navigate with tracking
- `pushReplacement()` - Replace route with tracking
- `pop()` - Pop with tracking

### ScreenTrackingMixin
Mixin for automatic screen tracking:
- Automatically tracks screen visits on init
- Provides helper methods for interactions
- Handles navigation tracking

## Implementation Status

### ✅ Completed

1. **Database Schema** - All tables created with proper RLS policies
2. **UserProgressService** - Full service implementation
3. **DatabaseService** - Enhanced with progress methods
4. **Main App** - Session tracking initialized
5. **MainScreen** - Tab navigation tracking
6. **ProfessionalStocksScreen** - Screen visit and interaction tracking
7. **EnhancedStockDetailScreen** - Screen visit tracking
8. **SmartActionHandler** - Navigation tracking

### 🔄 In Progress

1. **Additional Screens** - Need tracking added to:
   - Learning screens (DuolingoHomeScreen, lesson screens)
   - AI Coach screen
   - Dashboard screens
   - Other trading screens

2. **Widget Interactions** - Need tracking for:
   - Trade dialog interactions
   - Chart interactions
   - Tab switches in detail screens
   - Button clicks throughout app

### 📋 Recommended Next Steps

1. **Add tracking to all remaining screens**
   - Use ScreenTrackingMixin or manual tracking
   - Track all screen visits in initState

2. **Track all widget interactions**
   - Buttons, cards, tabs, dialogs
   - Use trackWidgetInteraction() method

3. **Track all navigation**
   - Replace Navigator.push with NavigationHelper.push
   - Or manually track with trackNavigation()

4. **Learning Progress Tracking**
   - Track lesson starts/completions
   - Track quiz attempts and scores
   - Track time spent in lessons

5. **Trading Activity Tracking**
   - Track all trade executions
   - Track watchlist changes
   - Track chart views
   - Track news reads

## Usage Examples

### Screen Tracking
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    UserProgressService().trackScreenVisit(
      screenName: 'MyScreen',
      screenType: 'main',
      metadata: {'custom': 'data'},
    );
  });
}
```

### Widget Interaction Tracking
```dart
onTap: () async {
  await UserProgressService().trackWidgetInteraction(
    screenName: 'MyScreen',
    widgetType: 'button',
    actionType: 'tap',
    widgetId: 'buy_button',
    interactionData: {'symbol': 'AAPL'},
  );
  // Perform action
}
```

### Navigation Tracking
```dart
// Option 1: Use NavigationHelper
await NavigationHelper.push(
  context,
  NextScreen(),
  fromScreen: 'CurrentScreen',
  navigationData: {'data': 'value'},
);

// Option 2: Manual tracking
await UserProgressService().trackNavigation(
  fromScreen: 'CurrentScreen',
  toScreen: 'NextScreen',
  navigationMethod: 'push',
  navigationData: {'data': 'value'},
);
Navigator.push(context, MaterialPageRoute(builder: (_) => NextScreen()));
```

## Database Queries

### Get User Progress
```sql
SELECT * FROM user_progress WHERE user_id = 'user-id';
```

### Get Screen Visit History
```sql
SELECT * FROM user_screen_visits 
WHERE user_id = 'user-id' 
ORDER BY visited_at DESC 
LIMIT 50;
```

### Get Navigation Flow
```sql
SELECT * FROM user_navigation_flows 
WHERE user_id = 'user-id' 
ORDER BY created_at DESC 
LIMIT 100;
```

### Get Session Summary
```sql
SELECT 
  session_start,
  session_end,
  total_screens_visited,
  total_interactions
FROM user_sessions 
WHERE user_id = 'user-id' 
ORDER BY session_start DESC;
```

## Testing Checklist

- [ ] Screen visits are tracked on all screens
- [ ] Widget interactions are tracked
- [ ] Navigation flows are tracked
- [ ] Sessions start and end correctly
- [ ] Learning progress is tracked
- [ ] Trading activities are tracked
- [ ] Data persists to Supabase
- [ ] Local fallback works when offline
- [ ] Navigation is smooth and consistent
- [ ] No performance issues from tracking

## Notes

- All tracking is non-blocking and won't affect app performance
- Local fallback ensures tracking works offline
- Data syncs to Supabase when available
- RLS policies ensure data privacy
- Indexes optimize query performance






