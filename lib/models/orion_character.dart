import '../services/database_service.dart';

/// Character moods/personalities
enum CharacterMood {
  friendly,      // Normal, encouraging
  concerned,     // When streak is at risk (Duo's "angry" equivalent)
  excited,       // When user achieves something
  proud,         // When user maintains streak
}

/// Ory Character - The app's mascot (like Duolingo's Duo)
/// Character personality and notification messages
/// Can fetch templates from Supabase for dynamic updates
class OrionCharacter {
  // Character name - "Ory" (friendly, short name)
  static const String name = 'Ory';
  
  // Character description for AI image generation
  static const String characterDescription = '''
  A friendly, professional blue mascot character for a financial trading app.
  Design: Cute but professional, blue color scheme matching #1E3A8A and #3B82F6.
  Style: Modern, approachable, similar to Duolingo's Duo but with a financial/trading theme.
  Expression: Can show friendly, encouraging, and "concerned" (not angry, but worried) expressions.
  Should have a professional yet playful appearance that matches a trading/learning app.
  ''';
  
  // Cache for templates
  static List<Map<String, dynamic>>? _templatesCache;
  static bool _templatesLoaded = false;

  /// Load templates from Supabase (with fallback to hardcoded)
  static Future<void> _loadTemplates() async {
    if (_templatesLoaded) return;
    
    try {
      _templatesCache = await DatabaseService.loadNotificationTemplates();
      _templatesLoaded = true;
    } catch (e) {
      print('⚠️ Error loading notification templates: $e');
      _templatesCache = [];
      _templatesLoaded = true;
    }
  }

  /// Get notification message based on mood and context
  /// Uses NEW hardcoded Duolingo-style messages (Supabase templates disabled to use new content)
  static Future<String> getNotificationMessage({
    required CharacterMood mood,
    required String context,
    int? streak,
    String? userName,
  }) async {
    // ALWAYS use new hardcoded messages (skip Supabase to avoid old templates)
    // The new messages are perfect Duolingo-style aggressive, guilty marketing
    switch (mood) {
      case CharacterMood.friendly:
        return _getFriendlyMessage(context, streak, userName);
      case CharacterMood.concerned:
        return _getConcernedMessage(context, streak, userName);
      case CharacterMood.excited:
        return _getExcitedMessage(context, streak, userName);
      case CharacterMood.proud:
        return _getProudMessage(context, streak, userName);
    }
  }

  /// Get notification title based on mood
  /// Uses NEW hardcoded short, punchy titles (Supabase templates disabled to use new content)
  static Future<String> getNotificationTitle(CharacterMood mood, int? streak) async {
    // ALWAYS use new hardcoded titles (skip Supabase to avoid old templates)
    // The new titles are short and punchy like Duolingo
    return _getNotificationTitle(mood, streak);
  }

  /// Get template from Supabase cache
  static Map<String, dynamic>? _getTemplateFromSupabase(CharacterMood mood, String context, int? streak) {
    if (_templatesCache == null) return null;
    
    final moodString = mood.toString().split('.').last;
    
    // Determine template type based on context
    String templateType = context;
    if (context == 'title') {
      // For titles, we need to find a template with matching mood
      final templates = _templatesCache!.where((t) => 
        t['character_mood'] == moodString
      ).toList();
      
      if (templates.isNotEmpty) {
        // Return the highest priority template
        templates.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
        return templates.first;
      }
      return null;
    }
    
    // For streak_at_risk, consider streak length
    if (templateType == 'streak_at_risk') {
      String suffix = '';
      if (streak != null && streak >= 30) {
        suffix = '_high';
      } else if (streak != null && streak >= 7) {
        suffix = '_medium';
      } else {
        suffix = '_low';
      }
      templateType = 'streak_at_risk$suffix';
    }
    
    // Find matching templates
    final templates = _templatesCache!.where((t) => 
      t['template_type'] == templateType && 
      t['character_mood'] == moodString
    ).toList();
    
    if (templates.isEmpty) {
      // Try without suffix for streak_at_risk
      if (templateType.startsWith('streak_at_risk')) {
        final fallbackTemplates = _templatesCache!.where((t) => 
          t['template_type'] == 'streak_at_risk' && 
          t['character_mood'] == moodString
        ).toList();
        if (fallbackTemplates.isNotEmpty) {
          fallbackTemplates.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
          return fallbackTemplates.first;
        }
      }
      return null;
    }
    
    // Return the highest priority template
    templates.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
    return templates.first;
  }

  /// Format template with variables
  static String _formatTemplate(Map<String, dynamic> template, int? streak, String? userName) {
    String text = template['body_template'] as String? ?? template['title_template'] as String;
    
    // Replace placeholders
    final greeting = userName != null ? 'Hi $userName' : 'Hi there';
    text = text.replaceAll('{greeting}', greeting);
    text = text.replaceAll('{userName}', userName ?? 'there');
    text = text.replaceAll('{streak}', streak?.toString() ?? '0');
    
    return text;
  }

  /// Get notification message based on mood and context (synchronous version for backwards compatibility)
  static String getNotificationMessageSync({
    required CharacterMood mood,
    required String context,
    int? streak,
    String? userName,
  }) {
    switch (mood) {
      case CharacterMood.friendly:
        return _getFriendlyMessage(context, streak, userName);
      case CharacterMood.concerned:
        return _getConcernedMessage(context, streak, userName);
      case CharacterMood.excited:
        return _getExcitedMessage(context, streak, userName);
      case CharacterMood.proud:
        return _getProudMessage(context, streak, userName);
    }
  }
  
  // Friendly messages - Duolingo style: aggressive, guilty, guilt-tripping
  static String _getFriendlyMessage(String context, int? streak, String? userName) {
    switch (context) {
      case 'morning_streak':
        final messages = [
          'Your ${streak ?? 0}-day streak is waiting. Don\'t make it wait any longer.',
          'It would be a bummer to lose that ${streak ?? 0}-day streak. Just saying.',
          'Hey. It looks like you haven\'t completed your goals today. Good luck explaining that to your ${streak ?? 0}-day streak.',
          'Your ${streak ?? 0}-day streak needs you. Complete your goals now.',
          'These reminders don\'t seem to be working. We\'ll stop sending them for you now. (Just kidding. Complete your goals.)',
          'Your daily lesson is waiting. Don\'t make it wait any longer.',
          'It\'s time to complete your goals. Your ${streak ?? 0}-day streak is counting on you.',
          'You\'re going to let your ${streak ?? 0}-day streak die? Really?',
        ];
        return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
        
      case 'afternoon_learning':
        final messages = [
          'Hey. It looks like you missed your trading lesson again. Good luck talking your way out of this one.',
          'Your trading knowledge is fading. Complete your lesson now.',
          'You\'re falling behind. Complete your daily lesson immediately.',
          'These reminders don\'t seem to be working. We\'ll stop sending them for you now. (Just kidding. Complete your lesson.)',
          'It\'s time to learn. Your future self will thank you.',
          'Your portfolio is waiting. But first, complete your lesson.',
          'You know what would be cool? Completing your lesson. Just saying.',
          'I\'m not mad, just disappointed. Complete your lesson.',
        ];
        return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
        
      case 'evening_streak':
        final messages = [
          'It would be a bummer to lose that ${streak ?? 0}-day streak. Just saying.',
          'Your ${streak ?? 0}-day streak is about to break. Complete your goals now.',
          'Time is running out. Your ${streak ?? 0}-day streak needs you.',
          'Hey. It looks like you haven\'t completed your goals today. Your ${streak ?? 0}-day streak won\'t be happy.',
          'This is your last chance. Complete your goals before your ${streak ?? 0}-day streak breaks.',
          'Your ${streak ?? 0}-day streak is waiting. Don\'t let it down.',
          'After ${streak ?? 0} days, you\'re going to let it all go?',
          'Your ${streak ?? 0}-day streak is in danger. It would be a shame to lose it.',
        ];
        return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
        
      case 'streak_lost':
        final messages = [
          'Your streak broke. I\'m not mad, just disappointed.',
          'Your streak is gone. But you can start a new one today!',
          'Streak broken. Time to start fresh and build it back up.',
          'Your streak ended. Don\'t worry, you can get it back!',
          'Streak lost. But every day is a new chance!',
          'Your streak broke. Let\'s start a new one right now!',
          'Streak gone. But you can rebuild it starting today!',
          'Your streak ended. Time to start a new one!',
        ];
        return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
        
      case 'market_news':
        final messages = [
          'Big news in the market! Check it out.',
          'Market update! Your portfolio might be affected.',
          'Important market news! Take a look.',
          'Market alert! This could impact your trades.',
          'Breaking market news! Don\'t miss this.',
          'Market update! Check your positions.',
          'Big market news! Your stocks might move.',
          'Market alert! Time to check your portfolio.',
        ];
        return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
        
      default:
        return 'It\'s time for you to complete your daily goals. Take 5 minutes now to complete them.';
    }
  }
  
  // Concerned messages - Duolingo style: AGGRESSIVE, guilt-tripping, passive-aggressive
  static String _getConcernedMessage(String context, int? streak, String? userName) {
    final effectiveStreak = streak;
    
    if (effectiveStreak != null && effectiveStreak >= 30) {
      final messages = [
        'After ${streak} days, you\'re going to let it all go? Your streak needs you right now.',
        'Your ${streak}-day streak is about to break. I really don\'t want that to happen. Please come back.',
        'Hey. It looks like you haven\'t been here today. Your ${streak}-day streak won\'t be happy.',
        'It would be a bummer to lose that ${streak}-day streak. Just saying. Come back now.',
        'Your ${streak}-day streak is in danger. It would be a shame to lose it after all this time.',
        'These reminders don\'t seem to be working. We\'ll stop sending them for you now. (Just kidding. Complete your goals.)',
        'I\'ve been watching your ${streak}-day streak. It\'s not looking good. Please come back.',
        'Your ${streak}-day streak is crying. (Not really, but you get the point.)',
        'After ${streak} days of hard work, you\'re just going to throw it away?',
        'Your ${streak}-day streak is about to break. I\'m not mad, just disappointed.',
      ];
      return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
    } else if (effectiveStreak != null && effectiveStreak >= 7) {
      final messages = [
        'Your ${streak}-day streak is about to break. I really don\'t want that to happen.',
        'After ${streak} days, you\'re going to let it all go? Complete your goals now.',
        'Hey. It looks like you haven\'t been here today. Your ${streak}-day streak is waiting.',
        'Your ${streak}-day streak is in danger. Complete your goals now.',
        'It would be a shame to lose your ${streak}-day streak. Just saying.',
        'Your ${streak}-day streak needs you. Don\'t let it down.',
        'I\'m worried about your ${streak}-day streak. Please come back.',
        'Your ${streak}-day streak is about to break. Don\'t let that happen.',
        'After ${streak} days, you\'re going to give up? Really?',
        'Your ${streak}-day streak won\'t survive without you. Come back now.',
      ];
      return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
    } else {
      final messages = [
        'Your streak is about to break. I really don\'t want that to happen.',
        'Hey. It looks like you haven\'t been here today. Your streak is waiting.',
        'Your streak is in danger. Complete your goals now.',
        'These reminders don\'t seem to be working. We\'ll stop sending them for you now. (Just kidding. Complete your goals.)',
        'Your streak needs you. Don\'t let it down.',
        'It would be a shame to lose your streak. Just saying.',
        'I\'m worried about your streak. Please come back.',
        'Your streak is about to break. Don\'t let that happen.',
        'You\'re going to let your streak die? Really?',
        'Your streak won\'t survive without you. Come back now.',
      ];
      return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
    }
  }
  
  // Excited messages - Duolingo style: celebratory but still engaging
  static String _getExcitedMessage(String context, int? streak, String? userName) {
    switch (context) {
      case 'level_up':
        final messages = [
          'You leveled up! Keep going!',
          'Level up! You\'re getting better!',
          'Congratulations! You leveled up!',
          'Level up! Your trading skills are improving!',
          'You leveled up! This is amazing!',
          'Level up! Keep the momentum going!',
          'You leveled up! I\'m so proud!',
          'Level up! You\'re crushing it!',
        ];
        return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
      case 'badge_unlocked':
        final messages = [
          'Achievement unlocked! Amazing work!',
          'You unlocked an achievement! Incredible!',
          'Achievement unlocked! You\'re doing great!',
          'New achievement! Keep it up!',
          'Achievement unlocked! I\'m so proud!',
          'You earned an achievement! This is awesome!',
          'Achievement unlocked! You\'re on fire!',
          'New achievement! Your hard work paid off!',
        ];
        return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
      case 'streak_milestone':
        final messages = [
          '${streak ?? 0}-day streak milestone! Incredible!',
          'You hit a ${streak ?? 0}-day streak! Amazing!',
          '${streak ?? 0}-day streak! You\'re unstoppable!',
          'Milestone reached! ${streak ?? 0} days strong!',
          '${streak ?? 0}-day streak! I\'m so proud!',
          'You\'ve reached ${streak ?? 0} days! Incredible!',
          '${streak ?? 0}-day streak milestone! Keep going!',
          '${streak ?? 0} days! You\'re a streak champion!',
        ];
        return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
      default:
        final messages = [
          'Great job! Keep it up!',
          'You\'re doing amazing! Keep going!',
          'Incredible work! Don\'t stop now!',
          'You\'re crushing it! Keep it up!',
          'Amazing progress! Keep going!',
          'You\'re on fire! Don\'t stop!',
          'Incredible! Keep the momentum!',
          'You\'re doing great! Keep it up!',
        ];
        return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
    }
  }
  
  // Proud messages - Duolingo style: encouraging but still engaging
  static String _getProudMessage(String context, int? streak, String? userName) {
    final messages = [
      '${streak ?? 0}-day streak! You\'re doing amazing!',
      '${streak ?? 0} days strong! I\'m so proud!',
      '${streak ?? 0}-day streak! Keep it up!',
      'You\'ve maintained ${streak ?? 0} days! Incredible!',
      '${streak ?? 0}-day streak! You\'re unstoppable!',
      '${streak ?? 0} days! You\'re a champion!',
      '${streak ?? 0}-day streak! This is amazing!',
      '${streak ?? 0} days! You\'re doing great!',
    ];
    return messages[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % messages.length];
  }
  
  /// Get notification title - SHORT like Duolingo: varied but always short
  /// Titles are ALWAYS short and different from body content
  static String _getNotificationTitle(CharacterMood mood, int? streak) {
    // Use time-based rotation for variety
    final index = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 8;
    
    switch (mood) {
      case CharacterMood.friendly:
        final titles = [
          'Hey. It\'s Ory.',
          'Hi. It\'s Ory.',
          'Ory here.',
          'Hey there.',
          'It\'s Ory.',
          'Ory here!',
          'Hey. It\'s Ory.',
          'Hi. It\'s Ory.',
        ];
        return titles[index];
      case CharacterMood.concerned:
        final titles = [
          'Hey. It\'s Ory.',
          'Ory here.',
          'Hey. It\'s Ory.',
          'It\'s Ory.',
          'Ory here...',
          'Hey there.',
          'Ory here.',
          'Hey. It\'s Ory.',
        ];
        return titles[index];
      case CharacterMood.excited:
        final titles = [
          'Hey. It\'s Ory!',
          'Ory here!',
          'Hey! It\'s Ory!',
          'It\'s Ory!',
          'Ory here!',
          'Hey! It\'s Ory!',
          'Ory here!',
          'Hey. It\'s Ory!',
        ];
        return titles[index];
      case CharacterMood.proud:
        final titles = [
          'Hey. It\'s Ory!',
          'Ory here!',
          'Hey! It\'s Ory!',
          'It\'s Ory!',
          'Ory here!',
          'Hey! It\'s Ory!',
          'Ory here!',
          'Hey. It\'s Ory!',
        ];
        return titles[index];
    }
  }

  /// Get character image asset path based on mood
  static String getCharacterImagePath(CharacterMood mood) {
    switch (mood) {
      case CharacterMood.friendly:
        return 'assets/character/ory_friendly.png';
      case CharacterMood.concerned:
        return 'assets/character/ory_concerned.png';
      case CharacterMood.excited:
        return 'assets/character/ory_excited.png';
      case CharacterMood.proud:
        return 'assets/character/ory_proud.png';
    }
  }

  /// Clear templates cache (call when templates are updated in Supabase)
  static void clearCache() {
    _templatesCache = null;
    _templatesLoaded = false;
    DatabaseService.clearNotificationTemplatesCache();
  }
  
  /// Force clear cache and reload (ensures new hardcoded messages are used)
  static void forceUseNewMessages() {
    _templatesCache = [];
    _templatesLoaded = false;
    DatabaseService.clearNotificationTemplatesCache();
    print('✅ Forced use of new hardcoded Duolingo-style messages');
  }
}

