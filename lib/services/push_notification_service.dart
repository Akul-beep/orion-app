import 'dart:async';
import 'dart:io' show Platform, File, Directory;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'gamification_service.dart';
import 'paper_trading_service.dart';
import 'database_service.dart';
import 'notification_manager.dart';
import '../models/orion_character.dart' show OrionCharacter, CharacterMood;

/// Comprehensive push notification service with Duolingo-style retention strategies
/// Handles scheduling, market news, streak reminders, and daily engagement
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  SharedPreferences? _prefs;
  
  // Cache for copied asset files (iOS notification attachments)
  final Map<String, String> _assetFileCache = {};
  
  // Directory for notification images (persists across app restarts)
  Directory? _notificationImagesDir;

  // Notification channels
  static const String _channelIdGeneral = 'orion_general';
  static const String _channelIdStreak = 'orion_streak';
  static const String _channelIdMarket = 'orion_market';
  static const String _channelIdLearning = 'orion_learning';
  static const String _channelIdAchievements = 'orion_achievements';

  // Notification IDs (ranges for different types)
  static const int _idBaseStreak = 1000;
  static const int _idBaseLearning = 2000;
  static const int _idBaseMarket = 3000;
  static const int _idBaseAchievements = 4000;
  static const int _idBaseDaily = 5000;

  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Create directory for notification images
    // CRITICAL: For iOS, we use Documents directory (accessible to notification system)
    // For Android, use Documents directory (persists across restarts)
    try {
      if (Platform.isIOS) {
        // iOS: Use Documents directory - accessible to notification system even when app is backgrounded
        print('✅ iOS: Will use Documents directory for notification images');
      } else {
        // Android: Use Documents directory (persists)
        final baseDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(path.join(baseDir.path, 'notification_images'));
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        _notificationImagesDir = imagesDir;
        print('✅ Android notification images directory ready: ${_notificationImagesDir!.path}');
      }
    } catch (e) {
      print('⚠️ Error setting up notification images directory: $e');
    }
    
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization - DON'T request permissions here (we'll do it manually)
    // This allows us to show a pre-permission screen first (like Duolingo)
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (Android)
    await _createNotificationChannels();

    // Sync notification settings from database to SharedPreferences
    await syncSettingsFromDatabase();

    _initialized = true;
    print('✅ Push Notification Service initialized');
    
    // Pre-load all character images in background (non-blocking)
    // This ensures images are ready when notifications fire
    if (Platform.isIOS || Platform.isAndroid) {
      // Don't await - let it run in background
      _preloadCharacterImages().catchError((e) {
        print('⚠️ Error pre-loading character images (non-critical): $e');
      });
    }
    
    // NOTE: Notifications will be scheduled by NotificationScheduler.initialize()
    // We don't cancel here to avoid cancelling notifications that were just scheduled
  }

  /// Pre-load all character images in background (non-blocking)
  Future<void> _preloadCharacterImages() async {
    try {
      print('📸 Pre-loading all character mascot images in background...');
      final moods = [CharacterMood.friendly, CharacterMood.concerned, CharacterMood.excited, CharacterMood.proud];
      for (final mood in moods) {
        try {
          final imagePath = OrionCharacter.getCharacterImagePath(mood);
          final copiedPath = await _copyAssetToTempFile(imagePath);
          if (copiedPath != null) {
            print('   ✅ Pre-loaded ${mood.toString().split('.').last}: $copiedPath');
          } else {
            print('   ⚠️ Failed to pre-load ${mood.toString().split('.').last}');
          }
        } catch (e) {
          print('   ⚠️ Error pre-loading ${mood.toString().split('.').last}: $e');
          // Continue with other images
        }
      }
      print('📸 Character image pre-loading complete');
    } catch (e) {
      print('⚠️ Error in pre-loading process: $e');
    }
  }
  
  /// Copy asset to persistent file for notification attachments
  /// iOS requires file:// URLs, not asset paths
  /// Files are stored in a persistent directory to ensure they're available when notification fires
  /// CRITICAL: Resizes images to notification-appropriate size (300x300px) for proper display
  Future<String?> _copyAssetToTempFile(String assetPath) async {
    try {
      // Ensure initialization is complete
      if (!_initialized) {
        await initialize();
      }
      
      // Check cache first
      if (_assetFileCache.containsKey(assetPath)) {
        final cachedPath = _assetFileCache[assetPath]!;
        final cachedFile = File(cachedPath);
        if (await cachedFile.exists()) {
          final size = await cachedFile.length();
          if (size > 0) {
            print('✅ Using cached image: $cachedPath (${size} bytes)');
            return cachedPath;
          }
        }
        // Cache is stale, remove it
        _assetFileCache.remove(assetPath);
      }
      
      print('📸 Loading Ory character image from asset: $assetPath');
      
      // Try to load asset - with better error handling
      ByteData data;
      try {
        data = await rootBundle.load(assetPath);
      } catch (e) {
        print('❌ ERROR: Cannot load asset $assetPath: $e');
        print('💡 Make sure the asset exists in pubspec.yaml and assets/character/ folder');
        print('💡 Asset path format should be: assets/character/ory_friendly.png');
        return null;
      }
      
      final Uint8List bytes = data.buffer.asUint8List();
      
      if (bytes.isEmpty) {
        print('⚠️ Asset file is empty: $assetPath');
        return null;
      }
      
      print('✅ Loaded ${bytes.length} bytes from asset');
      
      // CRITICAL FIX: Resize image to notification-appropriate size
      // iOS notification thumbnails work best with 300x300px or smaller images
      // This ensures the mascot appears correctly on the right side like Duolingo
      Uint8List resizedBytes = bytes;
      try {
        // Decode the image
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final originalImage = frame.image;
        
        // Get original dimensions
        final originalWidth = originalImage.width;
        final originalHeight = originalImage.height;
        print('📐 Original image size: ${originalWidth}x${originalHeight}');
        
        // Calculate target size (max 300x300 for notification thumbnails)
        // Maintain aspect ratio
        const maxSize = 300.0;
        double scale = 1.0;
        if (originalWidth > maxSize || originalHeight > maxSize) {
          scale = maxSize / (originalWidth > originalHeight ? originalWidth : originalHeight);
        }
        
        final targetWidth = (originalWidth * scale).round();
        final targetHeight = (originalHeight * scale).round();
        print('📐 Resizing to: ${targetWidth}x${targetHeight} (scale: $scale)');
        
        // Resize the image
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint()..filterQuality = ui.FilterQuality.high;
        
        canvas.drawImageRect(
          originalImage,
          Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
          Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
          paint,
        );
        
        final picture = recorder.endRecording();
        final resizedImage = await picture.toImage(targetWidth, targetHeight);
        
        // Convert to PNG bytes
        print('📸 Converting resized image to PNG bytes...');
        final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          resizedBytes = byteData.buffer.asUint8List();
          print('✅ Resized image: ${bytes.length} bytes -> ${resizedBytes.length} bytes');
          
          // Dispose resources
          originalImage.dispose();
          resizedImage.dispose();
        } else {
          print('⚠️ Failed to convert resized image to bytes, using original');
          originalImage.dispose();
        }
      } catch (e, stackTrace) {
        print('⚠️ Error resizing image (using original): $e');
        print('   Stack: $stackTrace');
        // Continue with original bytes if resize fails
      }
      
      print('📸 Preparing to write file (${resizedBytes.length} bytes)...');
      // CRITICAL: For iOS local notifications, the file MUST be accessible when notification fires
      // Even if app is backgrounded or terminated. 
      // CRITICAL FIX: Use App Group shared container for Notification Content Extension access
      // If App Group is not available, fall back to Documents directory
      Directory targetDir;
      if (Platform.isIOS) {
        // Try App Group first (best for extension access)
        // App Group identifier: group.com.akulnehra.orion
        try {
          // Use path_provider to get App Group directory if available
          // For now, we'll use Documents but also copy to a location the extension can access
          final docsDir = await getApplicationDocumentsDirectory();
          targetDir = Directory(path.join(docsDir.path, 'notification_images'));
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
          print('✅ Using iOS Documents directory: ${targetDir.path}');
          print('   💡 Documents directory is accessible to notification system');
          print('   💡 Files will be accessible via notification attachments');
        } catch (e) {
          print('⚠️ Error setting up iOS notification images directory: $e');
          // Fallback to Documents directory
          final docsDir = await getApplicationDocumentsDirectory();
          targetDir = Directory(path.join(docsDir.path, 'notification_images'));
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
        }
      } else {
        // For Android: Use Documents directory (persists across restarts)
        if (_notificationImagesDir != null && await _notificationImagesDir!.exists()) {
          targetDir = _notificationImagesDir!;
        } else {
          final baseDir = await getApplicationDocumentsDirectory();
          targetDir = Directory(path.join(baseDir.path, 'notification_images'));
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
          _notificationImagesDir = targetDir;
          print('✅ Created Android notification images directory: ${targetDir.path}');
        }
      }
      
      final String fileName = path.basename(assetPath);
      // Use consistent filename - iOS needs stable file paths
      // Add unique suffix to avoid conflicts if same file is used multiple times
      final String targetFilePath = path.join(targetDir.path, fileName);
      
      // Write to file (overwrite if exists to ensure fresh copy)
      print('📸 Writing file to: $targetFilePath');
      final File targetFile = File(targetFilePath);
      try {
        await targetFile.writeAsBytes(resizedBytes, flush: true);  // Flush immediately
        
        print('✅ File written successfully');
      } catch (e, stackTrace) {
        print('❌ ERROR writing file: $e');
        print('   Stack: $stackTrace');
        return null;
      }
      
      // Verify file was written and is readable
      print('📸 Verifying file exists...');
      if (!await targetFile.exists()) {
        print('⚠️ Failed to create file: $targetFilePath');
        return null;
      }
      print('✅ File exists and is readable');
      
      // CRITICAL: Get absolute path using File.absolute - iOS requires this exact format
      final absolutePath = targetFile.absolute.path;
      
      // Verify absolute path file exists
      final absoluteFile = File(absolutePath);
      if (!await absoluteFile.exists()) {
        print('❌ Absolute path file does not exist: $absolutePath');
        return null;
      }
      
      final fileSize = await absoluteFile.length();
      if (fileSize == 0) {
        print('❌ File is empty: $absolutePath');
        return null;
      }
      
      print('✅ Copied Ory image: $assetPath -> $absolutePath (${fileSize} bytes)');
      
      // Verify it's a valid image file (check first few bytes)
      if (fileSize < 100) {
        print('⚠️ File seems too small to be a valid image: $fileSize bytes');
      }
      
      // For iOS: Verify PNG header (89 50 4E 47) and try to decode the image
      if (fileName.endsWith('.png')) {
        try {
          final header = await targetFile.openRead(0, 4).first;
          if (header.length >= 4) {
            final pngHeader = [0x89, 0x50, 0x4E, 0x47];
            final isValidPng = header[0] == pngHeader[0] && 
                               header[1] == pngHeader[1] && 
                               header[2] == pngHeader[2] && 
                               header[3] == pngHeader[3];
            if (!isValidPng) {
              print('⚠️ File does not appear to be a valid PNG (header check failed)');
            } else {
              print('✅ Verified PNG file format');
              
              // CRITICAL: Try to decode the image to ensure iOS can read it
              try {
                final imageBytes = await targetFile.readAsBytes();
                final codec = await ui.instantiateImageCodec(imageBytes);
                final frame = await codec.getNextFrame();
                final testImage = frame.image;
                print('✅ Image can be decoded by iOS (${testImage.width}x${testImage.height})');
                testImage.dispose();
              } catch (decodeError) {
                print('❌ ERROR: Image cannot be decoded - iOS won\'t be able to display it!');
                print('   Decode error: $decodeError');
                return null; // Don't use corrupted image
              }
            }
          }
        } catch (e) {
          print('⚠️ Could not verify PNG header: $e');
        }
      }
      
      // Cache the absolute path
      _assetFileCache[assetPath] = absolutePath;
      
      // Return absolute path - iOS requires this
      return absolutePath;
    } catch (e, stackTrace) {
      print('❌ ERROR copying asset $assetPath to temp file: $e');
      print('   Stack trace: $stackTrace');
      print('💡 Check that:');
      print('   1. Asset exists in assets/character/ folder');
      print('   2. Asset is listed in pubspec.yaml');
      print('   3. App was rebuilt after adding asset');
      return null;
    }
  }
  
  /// Load image bitmap for Android BigPictureStyle
  Future<ui.Image?> _loadImageBitmap(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        print('⚠️ Image file does not exist: $imagePath');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        print('⚠️ Image file is empty: $imagePath');
        return null;
      }
      
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      print('❌ Error loading image bitmap: $e');
      return null;
    }
  }

  /// Sync notification settings from database to SharedPreferences
  /// This ensures settings are consistent between database and local storage
  Future<void> syncSettingsFromDatabase() async {
    try {
      final profile = await DatabaseService.loadUserProfile();
      if (profile != null) {
        print('🔄 Syncing notification settings from database...');
        
        // Sync notifications enabled
        if (profile['notificationsEnabled'] != null) {
          final enabled = profile['notificationsEnabled'] == true || 
                         profile['notificationsEnabled'] == 'true' ||
                         profile['notificationsEnabled'] == 1;
          await _prefs?.setBool('notifications_enabled', enabled);
        }
        
        // Sync reminder time
        if (profile['reminderTime'] != null) {
          final reminderTime = profile['reminderTime'].toString();
          if (reminderTime.contains(':')) {
            final parts = reminderTime.split(':');
            if (parts.length == 2) {
              final hour = int.tryParse(parts[0]) ?? 20;
              final minute = int.tryParse(parts[1]) ?? 0;
              await _prefs?.setInt('notification_hour', hour);
              await _prefs?.setInt('notification_minute', minute);
            }
          }
        }
        
        // Sync streak reminders enabled
        if (profile['streakRemindersEnabled'] != null) {
          final enabled = profile['streakRemindersEnabled'] == true || 
                         profile['streakRemindersEnabled'] == 'true' ||
                         profile['streakRemindersEnabled'] == 1;
          await _prefs?.setBool('streak_reminders_enabled', enabled);
        }
        
        // Sync market news enabled
        if (profile['marketNewsEnabled'] != null) {
          final enabled = profile['marketNewsEnabled'] == true || 
                         profile['marketNewsEnabled'] == 'true' ||
                         profile['marketNewsEnabled'] == 1;
          await _prefs?.setBool('market_news_enabled', enabled);
        }
        
        // Sync learning reminders enabled
        if (profile['learningRemindersEnabled'] != null) {
          final enabled = profile['learningRemindersEnabled'] == true || 
                         profile['learningRemindersEnabled'] == 'true' ||
                         profile['learningRemindersEnabled'] == 1;
          await _prefs?.setBool('learning_reminders_enabled', enabled);
        }
        
        // Sync preferred notification tab
        if (profile['preferredNotificationTab'] != null) {
          await _prefs?.setString('preferred_notification_tab', profile['preferredNotificationTab'].toString());
        }
        
        print('✅ Notification settings synced from database');
      }
    } catch (e) {
      print('⚠️ Error syncing notification settings from database: $e');
      // Don't fail initialization if sync fails
    }
  }

  /// Sync notification settings to database
  /// This ensures settings are saved to database when changed locally
  Future<void> syncSettingsToDatabase() async {
    try {
      final profileUpdate = <String, dynamic>{};
      
      // Get current SharedPreferences values
      final notificationsEnabled = await areNotificationsEnabled();
      final preferredTime = await getPreferredNotificationTime();
      final streakRemindersEnabled = await isStreakRemindersEnabled();
      final marketNewsEnabled = await isMarketNewsEnabled();
      final learningRemindersEnabled = await isLearningRemindersEnabled();
      final preferredTab = _prefs?.getString('preferred_notification_tab');
      
      // Build update map
      profileUpdate['notificationsEnabled'] = notificationsEnabled;
      if (preferredTime != null) {
        profileUpdate['reminderTime'] = '${preferredTime.hour.toString().padLeft(2, '0')}:${preferredTime.minute.toString().padLeft(2, '0')}';
      }
      profileUpdate['streakRemindersEnabled'] = streakRemindersEnabled;
      profileUpdate['marketNewsEnabled'] = marketNewsEnabled;
      profileUpdate['learningRemindersEnabled'] = learningRemindersEnabled;
      if (preferredTab != null) {
        profileUpdate['preferredNotificationTab'] = preferredTab;
      }
      
      // Save to database (will merge with existing profile)
      await DatabaseService.saveUserProfileData(profileUpdate);
      print('✅ Notification settings synced to database');
    } catch (e) {
      print('⚠️ Error syncing notification settings to database: $e');
      // Don't fail if sync fails
    }
  }

  /// Check if notification permissions are granted
  Future<bool> checkPermissionStatus() async {
    if (!_initialized) await initialize();
    
    // Check iOS permissions
    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final result = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    
    // Check Android permissions (Android 13+)
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    
    // Default to true for older Android versions
    return true;
  }

  /// Request notification permissions (shows system dialog)
  /// Returns true if granted, false if denied
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    
    try {
      // iOS permissions
      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        print('🔔 Requesting iOS notification permissions...');
        final result = await iosImplementation.requestPermissions(
          alert: true,  // CRITICAL: Must request alert permission
          badge: true,
          sound: true,
        );
        final granted = result ?? false;
        
        // Save permission status
        await _prefs?.setBool('notification_permission_granted', granted);
        await _prefs?.setBool('notification_permission_requested', true);
        
        if (granted) {
          print('✅ Notification permissions GRANTED');
        } else {
          print('❌ Notification permissions DENIED');
          print('💡 User must enable in Settings > Orion > Notifications');
        }
        
        return granted;
      }
      
      // Android permissions (Android 13+)
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission() ?? false;
        
        // Save permission status
        await _prefs?.setBool('notification_permission_granted', granted);
        await _prefs?.setBool('notification_permission_requested', true);
        
        return granted;
      }
      
      // Default to true for older Android versions
      await _prefs?.setBool('notification_permission_granted', true);
      return true;
    } catch (e) {
      print('⚠️ Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check if permissions have been requested before
  Future<bool> hasRequestedPermissions() async {
    return _prefs?.getBool('notification_permission_requested') ?? false;
  }

  /// Check if permissions are currently granted
  /// Checks cached status first to avoid showing dialog unnecessarily
  /// On iOS, if permissions were denied in system settings, the cached status might be stale
  /// In that case, user needs to explicitly request permissions again
  Future<bool> arePermissionsGranted({bool forceCheck = false}) async {
    if (!_initialized) await initialize();
    
    // Check cached status first (unless force checking)
    if (!forceCheck) {
      final cached = _prefs?.getBool('notification_permission_granted');
      if (cached != null) {
        // If we have cached status, return it
        // User can explicitly request permissions to update it
        return cached;
      }
    }
    
    // If no cached status or force checking, try to check actual status
    // Note: On iOS, checking status may show a dialog, so we do this sparingly
    try {
      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        // On iOS, requesting permissions returns the current status
        // If permissions were disabled in Settings, this will return false
        // and allow the user to re-enable them
        final result = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        final granted = result ?? false;
        
        // Update cached status
        await _prefs?.setBool('notification_permission_granted', granted);
        
        return granted;
      }
      
      // Android permissions (Android 13+)
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission() ?? false;
        await _prefs?.setBool('notification_permission_granted', granted);
        return granted;
      }
      
      // Default to checking cached status for older Android
      return _prefs?.getBool('notification_permission_granted') ?? true;
    } catch (e) {
      print('⚠️ Error checking permissions: $e');
      // If check fails, return cached status
      return _prefs?.getBool('notification_permission_granted') ?? false;
    }
  }

  // Note: Local notification handling is now done through onDidReceiveNotificationResponse
  // in the initialize method, so this callback is no longer needed

  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // Handle navigation based on payload
    // This will be handled by the app's navigation system
  }

  Future<void> _createNotificationChannels() async {
    // General notifications
    const generalChannel = AndroidNotificationChannel(
      _channelIdGeneral,
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    // Streak notifications
    const streakChannel = AndroidNotificationChannel(
      _channelIdStreak,
      'Streak Reminders',
      description: 'Notifications to maintain your learning streak',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Market notifications
    const marketChannel = AndroidNotificationChannel(
      _channelIdMarket,
      'Market Updates',
      description: 'Stock market news and price alerts',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Learning notifications
    const learningChannel = AndroidNotificationChannel(
      _channelIdLearning,
      'Learning Reminders',
      description: 'Daily learning reminders and lesson suggestions',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    // Achievement notifications
    const achievementChannel = AndroidNotificationChannel(
      _channelIdAchievements,
      'Achievements',
      description: 'Badge unlocks and milestone achievements',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(streakChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(marketChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(learningChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(achievementChannel);
  }

  // ========== NOTIFICATION PREFERENCES ==========

  Future<bool> areNotificationsEnabled() async {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool('notifications_enabled', enabled);
    // Sync to database
    await syncSettingsToDatabase();
    if (!enabled) {
      await cancelAllScheduledNotifications();
    } else {
      await rescheduleAllNotifications();
    }
  }

  Future<bool> isStreakRemindersEnabled() async {
    return _prefs?.getBool('streak_reminders_enabled') ?? true;
  }

  Future<void> setStreakRemindersEnabled(bool enabled) async {
    await _prefs?.setBool('streak_reminders_enabled', enabled);
    // Sync to database
    await syncSettingsToDatabase();
  }

  Future<bool> isMarketNewsEnabled() async {
    return _prefs?.getBool('market_news_enabled') ?? true;
  }

  Future<void> setMarketNewsEnabled(bool enabled) async {
    await _prefs?.setBool('market_news_enabled', enabled);
    // Sync to database
    await syncSettingsToDatabase();
  }

  Future<bool> isLearningRemindersEnabled() async {
    return _prefs?.getBool('learning_reminders_enabled') ?? true;
  }

  Future<void> setLearningRemindersEnabled(bool enabled) async {
    await _prefs?.setBool('learning_reminders_enabled', enabled);
    // Sync to database
    await syncSettingsToDatabase();
  }

  Future<TimeOfDay?> getPreferredNotificationTime() async {
    final hour = _prefs?.getInt('notification_hour') ?? 20; // Default 8 PM (evening)
    final minute = _prefs?.getInt('notification_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Duolingo sends notifications at multiple times per day
  // Get morning notification time (default 8 AM)
  Future<TimeOfDay> getMorningNotificationTime() async {
    final hour = _prefs?.getInt('morning_notification_hour') ?? 8;
    final minute = _prefs?.getInt('morning_notification_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Get evening notification time (user's preferred time, default 8 PM)
  Future<TimeOfDay> getEveningNotificationTime() async {
    return await getPreferredNotificationTime() ?? const TimeOfDay(hour: 20, minute: 0);
  }

  Future<void> setPreferredNotificationTime(TimeOfDay time) async {
    await _prefs?.setInt('notification_hour', time.hour);
    await _prefs?.setInt('notification_minute', time.minute);
    // Sync to database
    await syncSettingsToDatabase();
    // Note: Rescheduling is handled by NotificationScheduler
  }

  /// Get preferred notification tab (e.g., 'home', 'trading', 'learning')
  Future<String?> getPreferredNotificationTab() async {
    return _prefs?.getString('preferred_notification_tab');
  }

  /// Set preferred notification tab
  Future<void> setPreferredNotificationTab(String tab) async {
    await _prefs?.setString('preferred_notification_tab', tab);
    // Sync to database
    await syncSettingsToDatabase();
  }

  // ========== SCHEDULED NOTIFICATIONS ==========

  /// Schedule a notification at a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channelId = _channelIdGeneral,
    CharacterMood? characterMood, // Ory character mood for image
  }) async {
    if (!(await areNotificationsEnabled())) {
      print('⚠️ Notifications disabled in app settings');
      return;
    }
    
    // CRITICAL: Check and request permissions before scheduling
    print('🔔 Checking notification permissions before scheduling...');
    final permissionsGranted = await arePermissionsGranted();
    if (!permissionsGranted) {
      print('⚠️ Permissions not granted, requesting now...');
      final requested = await requestPermissions();
      if (!requested) {
        print('❌❌❌ NOTIFICATION PERMISSIONS DENIED! ❌❌❌');
        print('   Notifications will NOT be scheduled until permissions are granted.');
        print('   Go to: Settings > Orion > Notifications > Allow Notifications');
        return; // Don't try to schedule if permissions denied
      }
      print('✅ Permissions granted after request');
    } else {
      print('✅ Permissions already granted');
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    
    // Get Ory character image path based on mood
    String? characterImagePath;
    String? iosAttachmentPath;
    String? androidImagePath;
    ui.Image? androidImageBitmap;
    
    if (characterMood != null) {
      characterImagePath = OrionCharacter.getCharacterImagePath(characterMood);
      print('📸 Character image path: $characterImagePath for mood: $characterMood');
      
      // Copy asset to persistent file for both platforms
      print('📸 Calling _copyAssetToTempFile for: $characterImagePath');
      final copiedPath = await _copyAssetToTempFile(characterImagePath);
      print('📸 _copyAssetToTempFile returned: ${copiedPath ?? "❌ NULL - THIS IS THE PROBLEM!"}');
      
      if (copiedPath != null) {
        if (Platform.isIOS) {
          iosAttachmentPath = copiedPath;
          print('📸 ✅ Set iosAttachmentPath: $iosAttachmentPath');
        }
        
        if (Platform.isAndroid) {
          androidImagePath = copiedPath;
          // Also load as bitmap for BigPictureStyle
          androidImageBitmap = await _loadImageBitmap(copiedPath);
        }
      } else {
        print('❌ FAILED to copy character image for mood: $characterMood');
        print('   This is why the mascot is NOT appearing on the right side!');
      }
    } else {
      print('⚠️ No character mood provided - no mascot will be shown');
    }
    
    // Build iOS attachments if we have a file path
    List<DarwinNotificationAttachment>? iosAttachments;
    print('📸 Checking iOS attachment setup...');
    print('   Platform.isIOS: ${Platform.isIOS}');
    print('   iosAttachmentPath: ${iosAttachmentPath ?? "❌ NULL"}');
    if (Platform.isIOS && iosAttachmentPath != null) {
      try {
        print('📸 ========== CREATING iOS ATTACHMENT ==========');
        print('   Original path: $iosAttachmentPath');
        
        // Verify file exists before creating attachment
        final attachmentFile = File(iosAttachmentPath);
        final exists = await attachmentFile.exists();
        print('   File exists: $exists');
        
        if (exists) {
          // CRITICAL: Get absolute path - iOS requires absolute file path
          final absolutePath = attachmentFile.absolute.path;
          print('   Absolute path: $absolutePath');
          
          // CRITICAL: Ensure path uses forward slashes (iOS requirement)
          // Normalize path separators to forward slashes
          final normalizedPath = absolutePath.replaceAll('\\', '/');
          print('   Normalized path: $normalizedPath');
          
          // Verify normalized path file exists
          final normalizedFile = File(normalizedPath);
          final normalizedExists = await normalizedFile.exists();
          print('   Normalized file exists: $normalizedExists');
          
          if (normalizedExists) {
            // Verify file is readable and not empty
            final fileSize = await normalizedFile.length();
            print('   File size: $fileSize bytes');
            
            if (fileSize > 0) {
              // Try to read the file to verify it's accessible
              try {
                final testBytes = await normalizedFile.readAsBytes();
                print('   ✅ File is readable: ${testBytes.length} bytes');
                
                // Create attachment with unique identifier (required for iOS)
                // Use shorter ID to avoid issues
                final attachmentId = 'ory_${characterMood.toString().split('.').last}_$id';
                print('   Creating attachment with ID: $attachmentId');
                
                // CRITICAL: Verify file one more time before creating attachment
                // iOS is very strict about file accessibility
                final finalFile = File(normalizedPath);
                if (!await finalFile.exists()) {
                  print('❌ CRITICAL: File does not exist at normalized path: $normalizedPath');
                  // Don't return - continue without attachment
                } else {
                  final finalFileSize = await finalFile.length();
                  if (finalFileSize == 0) {
                    print('❌ CRITICAL: File is empty at: $normalizedPath');
                    // Don't return - continue without attachment
                  } else {
                    // CRITICAL: Use the absolute path directly - iOS needs exact file path
                    // Ensure path uses forward slashes (iOS requirement)
                    final finalAttachmentPath = finalFile.absolute.path.replaceAll('\\', '/');
                    print('   📁 Final attachment path: $finalAttachmentPath');
                    print('   📁 File size: $finalFileSize bytes');
                    
                    // CRITICAL: Create attachment with verified file path
                    // The identifier must be unique and the file must exist
                    try {
                      final attachment = DarwinNotificationAttachment(
                        finalAttachmentPath,
                        identifier: attachmentId,
                      );
                      
                      // Verify attachment was created
                      print('📸 Attachment object created:');
                      print('   - filePath: ${attachment.filePath}');
                      print('   - identifier: ${attachment.identifier}');
                      
                      iosAttachments = [attachment];
                      print('📸 ✅✅✅ iOS ATTACHMENT CREATED SUCCESSFULLY! ✅✅✅');
                      print('   💡 File location: Cache directory (iOS notification system accessible)');
                      print('   💡 File verified: exists=${await finalFile.exists()}, size=$finalFileSize bytes');
                    } catch (attachError) {
                      print('❌ CRITICAL ERROR creating DarwinNotificationAttachment: $attachError');
                      print('   This is why the mascot is NOT appearing!');
                      print('   Error details: $attachError');
                      // Don't return - continue without attachment
                    }
                  }
                }
              } catch (readError) {
                print('❌ ERROR reading file: $readError');
              }
            } else {
              print('⚠️ File exists but is empty (0 bytes)');
            }
          } else {
            print('⚠️ Normalized path file does not exist: $normalizedPath');
          }
        } else {
          print('⚠️ Attachment file does not exist: $iosAttachmentPath');
        }
        print('📸 ===========================================');
      } catch (e, stackTrace) {
        print('❌ ERROR creating iOS attachment: $e');
        print('   Stack: $stackTrace');
      }
    } else if (Platform.isIOS && characterMood != null) {
      print('⚠️ iOS attachment path is null for mood: $characterMood');
      print('   iosAttachmentPath: $iosAttachmentPath');
    } else if (Platform.isIOS) {
      print('⚠️ No character mood provided for iOS attachment');
    }
    
    try {
      // Build Android style - use BigPictureStyle for better mascot visibility (Duolingo-style)
      BigPictureStyleInformation? bigPictureStyle;
      if (androidImageBitmap != null) {
        try {
          // Convert ui.Image to ByteData for bitmap
          final byteData = await androidImageBitmap.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            bigPictureStyle = BigPictureStyleInformation(
              ByteArrayAndroidBitmap(byteData.buffer.asUint8List()),
              contentTitle: title,
              summaryText: body,
              largeIcon: androidImagePath != null 
                  ? FilePathAndroidBitmap(androidImagePath!) 
                  : null,
            );
            print('📸 Using BigPictureStyle for Android notification with mascot');
          }
        } catch (e) {
          print('⚠️ Error creating BigPictureStyle, falling back to BigText: $e');
        }
      }
      
      // CRITICAL: Final verification before scheduling
      if (Platform.isIOS) {
        print('');
        print('🔍🔍🔍 FINAL VERIFICATION BEFORE SCHEDULING 🔍🔍🔍');
        if (iosAttachments != null && iosAttachments!.isNotEmpty) {
          print('✅ iosAttachments list has ${iosAttachments!.length} attachment(s):');
          for (var att in iosAttachments!) {
            final attFile = File(att.filePath);
            final exists = await attFile.exists();
            final size = exists ? await attFile.length() : 0;
            print('   📸 Attachment: ${att.identifier}');
            print('      - Path: ${att.filePath}');
            print('      - Exists: $exists');
            print('      - Size: $size bytes');
            if (!exists || size == 0) {
              print('      ❌❌❌ FILE PROBLEM - This attachment will NOT work! ❌❌❌');
            }
          }
        } else if (characterMood != null) {
          print('❌❌❌ CRITICAL: NO iOS ATTACHMENTS CREATED FOR MOOD: $characterMood ❌❌❌');
          print('   This is why the mascot is NOT appearing!');
          print('   iosAttachmentPath was: ${iosAttachmentPath ?? "NULL"}');
        }
        print('🔍🔍🔍 END VERIFICATION 🔍🔍🔍');
        print('');
      }
      
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _getChannelName(channelId),
          channelDescription: _getChannelDescription(channelId),
          importance: _getImportance(channelId),
          priority: _getPriority(channelId),
          largeIcon: androidImagePath != null 
              ? FilePathAndroidBitmap(androidImagePath!) 
              : null,
          styleInformation: bigPictureStyle ?? BigTextStyleInformation(body),
        ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            attachments: iosAttachments, // Now includes Ory character image!
            threadIdentifier: 'ory_notifications', // Group notifications together
            categoryIdentifier: 'ORY_NOTIFICATION', // CRITICAL: This triggers the Notification Content Extension
          ),
      );
      
      // CRITICAL: Verify attachments are in NotificationDetails
      if (Platform.isIOS) {
        print('🔍 NotificationDetails.iOS.attachments: ${notificationDetails.iOS?.attachments?.length ?? 0}');
        if (notificationDetails.iOS?.attachments != null && notificationDetails.iOS!.attachments!.isNotEmpty) {
          print('✅✅✅ ATTACHMENTS ARE IN NotificationDetails! ✅✅✅');
          for (var att in notificationDetails.iOS!.attachments!) {
            print('   ✅ In NotificationDetails: ${att.identifier} -> ${att.filePath}');
          }
        } else {
          print('❌❌❌ NO ATTACHMENTS IN NotificationDetails! ❌❌❌');
          print('   This means attachments were NOT passed to the notification system!');
        }
      }
      
      // CRITICAL: For Notification Content Extension, pass image path in payload
      // The extension will read this from userInfo
      String? finalPayload = payload;
      if (Platform.isIOS && iosAttachmentPath != null) {
        // Include image path in payload JSON so extension can access it
        try {
          Map<String, dynamic> payloadMap;
          if (payload != null && payload.isNotEmpty) {
            // Try to parse as JSON
            try {
              payloadMap = jsonDecode(payload) as Map<String, dynamic>;
            } catch (e) {
              // If payload is not JSON, treat it as a string value
              payloadMap = {'type': payload};
            }
          } else {
            payloadMap = <String, dynamic>{};
          }
          payloadMap['image_path'] = iosAttachmentPath;
          finalPayload = jsonEncode(payloadMap);
          print('📸 Added image_path to payload for Notification Content Extension: $iosAttachmentPath');
        } catch (e) {
          print('⚠️ Could not add image_path to payload: $e');
          // Fallback: create simple payload with image path
          finalPayload = jsonEncode({'image_path': iosAttachmentPath, 'type': payload ?? 'notification'});
        }
      }
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: finalPayload,
      );
      
      // Calculate time until notification fires
      final now = DateTime.now();
      final timeUntilNotification = scheduledDate.difference(now);
      final daysUntil = timeUntilNotification.inDays;
      final hoursUntil = timeUntilNotification.inHours % 24;
      final minutesUntil = timeUntilNotification.inMinutes % 60;
      
      print('✅ Notification scheduled (ID: $id)');
      print('   📅 Scheduled for: ${scheduledDate.toString()}');
      print('   ⏰ Time until: ${daysUntil}d ${hoursUntil}h ${minutesUntil}m');
      print('   📸 Mascot: ${characterMood?.toString().split('.').last ?? "none"}');
      print('   📝 Title: "$title"');
      
      // Log if notification is in the past (shouldn't happen, but good to catch)
      if (scheduledDate.isBefore(now)) {
        print('   ⚠️ WARNING: Notification is scheduled in the PAST!');
      }
      
      print('📅 Scheduled notification: $title at ${scheduledDate.toString()}${characterMood != null ? ' with Ory (${characterMood.toString().split('.').last})' : ''}');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      // Re-throw to let caller handle it
      rethrow;
    }
  }

  /// Schedule a daily recurring notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
    String channelId = _channelIdGeneral,
    CharacterMood? characterMood, // Ory character mood for image
  }) async {
    if (!(await areNotificationsEnabled())) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Schedule for the next 365 days (we'll reschedule daily)
    for (int day = 0; day < 365; day++) {
      final date = scheduledDate.add(Duration(days: day));
      await scheduleNotification(
        id: id + day,
        title: title,
        body: body,
        scheduledDate: date,
        payload: payload,
        channelId: channelId,
        characterMood: characterMood, // Pass through character mood
      );
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all scheduled notifications - COMPLETE CLEANUP
  Future<void> cancelAllScheduledNotifications() async {
    print('🗑️ Cancelling ALL scheduled notifications...');
    
    // Cancel all notification ranges (including high IDs for streak-at-risk)
    for (int i = 0; i < 1000; i++) {
      await _notifications.cancel(_idBaseStreak + i);
      await _notifications.cancel(_idBaseLearning + i);
      await _notifications.cancel(_idBaseMarket + i);
      await _notifications.cancel(_idBaseAchievements + i);
      await _notifications.cancel(_idBaseDaily + i);
    }
    
    // Cancel high ID notifications (streak-at-risk uses 10000+)
    for (int i = 10000; i < 11000; i++) {
      await _notifications.cancel(i);
    }
    
    // Cancel test notification IDs
    for (int i = 99990; i < 100000; i++) {
      await _notifications.cancel(i);
    }
    
    // Cancel ALL pending notifications (nuclear option)
    try {
      final pending = await _notifications.pendingNotificationRequests();
      for (final notification in pending) {
        await _notifications.cancel(notification.id);
      }
      print('🗑️ Cancelled ${pending.length} pending notifications');
    } catch (e) {
      print('⚠️ Error getting pending notifications: $e');
    }
    
    print('✅ All scheduled notifications cancelled');
  }

  // ========== DUOLINGO-STYLE NOTIFICATIONS ==========

  /// Schedule streak reminder notifications (Duolingo-style: 2-3 times per day with Ory character)
  Future<void> scheduleStreakReminders(GamificationService gamification) async {
    print('📅 Scheduling streak reminders...');
    
    // Check if permissions are granted first
    if (!(await arePermissionsGranted())) {
      print('⚠️ Notification permissions not granted - requesting...');
      final granted = await requestPermissions();
      if (!granted) {
        print('❌ Notification permissions denied - cannot schedule streak reminders');
        return;
      }
    }
    
    if (!(await isStreakRemindersEnabled())) {
      print('⚠️ Streak reminders disabled in settings');
      return;
    }
    if (!(await areNotificationsEnabled())) {
      print('⚠️ Notifications disabled in settings');
      return;
    }

    final streak = gamification.streak;
    if (streak == 0) return;

    // Get user name for personalization
    final userProfile = await DatabaseService.loadUserProfile();
    final userName = userProfile?['displayName'] as String?;

    final now = DateTime.now();
    final morningTime = await getMorningNotificationTime();
    final eveningTime = await getEveningNotificationTime();
    
    // Duolingo sends notifications 2-3 times per day
    // Morning notification (8 AM default)
    var morningDate = DateTime(now.year, now.month, now.day, morningTime.hour, morningTime.minute);
    if (morningDate.isBefore(now)) {
      morningDate = morningDate.add(const Duration(days: 1));
    }
    
    // Evening notification (user's preferred time, default 8 PM)
    var eveningDate = DateTime(now.year, now.month, now.day, eveningTime.hour, eveningTime.minute);
    if (eveningDate.isBefore(now)) {
      eveningDate = eveningDate.add(const Duration(days: 1));
    }

    // Schedule for next 30 days with Ory character messages
    for (int day = 0; day < 30; day++) {
      // Morning notification with Ory
      final morning = morningDate.add(Duration(days: day));
      final morningMessage = await OrionCharacter.getNotificationMessage(
        mood: CharacterMood.friendly,
        context: 'morning_streak',
        streak: streak,
        userName: userName,
      );
      final morningTitle = await OrionCharacter.getNotificationTitle(
        CharacterMood.friendly,
        streak,
      );
      
      // Title is already short ("Hey. It's Ory.") - no truncation needed
      
      await scheduleNotification(
        id: _idBaseStreak + (day * 2),
        title: morningTitle,
        body: morningMessage,
        scheduledDate: morning,
        payload: 'streak_reminder',
        channelId: _channelIdStreak,
        characterMood: CharacterMood.friendly,
      );
      
      // Evening notification with Ory
      final evening = eveningDate.add(Duration(days: day));
      final eveningMessage = await OrionCharacter.getNotificationMessage(
        mood: CharacterMood.friendly,
        context: 'evening_streak',
        streak: streak,
        userName: userName,
      );
      final eveningTitle = await OrionCharacter.getNotificationTitle(
        CharacterMood.friendly,
        streak,
      );
      
      // Title is already short ("Hey. It's Ory.") - no truncation needed
      
      await scheduleNotification(
        id: _idBaseStreak + (day * 2) + 1,
        title: eveningTitle,
        body: eveningMessage,
        scheduledDate: evening,
        payload: 'streak_reminder',
        channelId: _channelIdStreak,
        characterMood: CharacterMood.friendly,
      );
    }
  }

  /// Check if streak is at risk and schedule urgent reminder with Ory's "concerned" personality
  /// Duolingo sends this when user hasn't opened app for ~20-24 hours (Duo gets "angry")
  Future<void> checkAndScheduleStreakAtRisk(GamificationService gamification) async {
    // Check if permissions are granted first
    if (!(await arePermissionsGranted())) {
      print('⚠️ Notification permissions not granted - skipping streak-at-risk check');
      return;
    }
    
    if (!(await isStreakRemindersEnabled())) return;
    if (!(await areNotificationsEnabled())) return;

    final streak = gamification.streak;
    if (streak == 0) return;

    // Get user name for personalization
    final userProfile = await DatabaseService.loadUserProfile();
    final userName = userProfile?['displayName'] as String?;

    // Get last activity date from gamification service
    final lastActivity = gamification.lastActivityDate;
    if (lastActivity == null) {
      // No activity yet, save current time
      await updateLastAppOpen();
      return;
    }

    final now = DateTime.now();
    final hoursSinceActivity = now.difference(lastActivity).inHours;
    final daysSinceActivity = now.difference(lastActivity).inDays;

    // If user hasn't had activity for 20-24 hours (almost a full day), streak is at risk
    // Also check if it's been more than 1 day (streak already broken, but send reminder anyway)
    if ((hoursSinceActivity >= 20 && hoursSinceActivity <= 24) || (daysSinceActivity >= 1 && daysSinceActivity < 2)) {
      // Schedule urgent "streak at risk" notification for 30 minutes from now
      final urgentTime = now.add(const Duration(minutes: 30));
      
      // Cancel any existing streak-at-risk notification
      await cancelNotification(_idBaseStreak + 10000);
      
      // Use Ory's "concerned" mood (like Duo's "angry" but more professional)
      final message = await OrionCharacter.getNotificationMessage(
        mood: CharacterMood.concerned,
        context: 'streak_at_risk',
        streak: streak,
        userName: userName,
      );
      final title = await OrionCharacter.getNotificationTitle(
        CharacterMood.concerned,
        streak,
      );
      
      // Title is already short ("Hey. It's Ory.") - no truncation needed
      
      await scheduleNotification(
        id: _idBaseStreak + 10000, // Use high ID to avoid conflicts
        title: title,
        body: message,
        scheduledDate: urgentTime,
        payload: 'streak_at_risk',
        channelId: _channelIdStreak,
        characterMood: CharacterMood.concerned, // Aggressive Ory!
      );
      
      print('🚨 Scheduled streak-at-risk notification with Ory (concerned mood) for ${urgentTime.toString()}');
    }
  }

  /// Update last app open time (call when app opens)
  Future<void> updateLastAppOpen() async {
    await _prefs?.setString('last_app_open', DateTime.now().toIso8601String());
  }

  /// Schedule learning reminder notifications (Duolingo-style: afternoon reminder with Ory)
  Future<void> scheduleLearningReminders() async {
    // Check if permissions are granted first
    if (!(await arePermissionsGranted())) {
      print('⚠️ Notification permissions not granted - skipping scheduling');
      return;
    }
    
    if (!(await isLearningRemindersEnabled())) return;
    if (!(await areNotificationsEnabled())) return;

    // Get user name for personalization
    final userProfile = await DatabaseService.loadUserProfile();
    final userName = userProfile?['displayName'] as String?;

    // Duolingo sends learning reminders in the afternoon (default 2 PM)
    final afternoonTime = TimeOfDay(hour: 14, minute: 0); // 2 PM
    final now = DateTime.now();
    
    var scheduledDate = DateTime(now.year, now.month, now.day, afternoonTime.hour, afternoonTime.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Schedule for next 30 days with Ory character messages
    for (int day = 0; day < 30; day++) {
      final date = scheduledDate.add(Duration(days: day));
      final message = await OrionCharacter.getNotificationMessage(
        mood: CharacterMood.friendly,
        context: 'afternoon_learning',
        streak: null,
        userName: userName,
      );
      final title = await OrionCharacter.getNotificationTitle(
        CharacterMood.friendly,
        null,
      );
      
      // Title is already short ("Hey. It's Ory.") - no truncation needed
      
      await scheduleNotification(
        id: _idBaseLearning + day,
        title: title,
        body: message,
        scheduledDate: date,
        payload: 'learning_reminder',
        channelId: _channelIdLearning,
        characterMood: CharacterMood.friendly,
      );
    }
  }

  /// Schedule market open notification
  Future<void> scheduleMarketOpenNotification() async {
    // Check if permissions are granted first
    if (!(await arePermissionsGranted())) {
      print('⚠️ Notification permissions not granted - skipping scheduling');
      return;
    }
    
    if (!(await isMarketNewsEnabled())) return;
    if (!(await areNotificationsEnabled())) return;

    // Get user name for personalization
    final userProfile = await DatabaseService.loadUserProfile();
    final userName = userProfile?['displayName'] as String?;

    final now = DateTime.now();
    // Market opens at 9:30 AM EST (convert to local time)
    // For simplicity, we'll use 9:30 AM local time
    var scheduledDate = DateTime(now.year, now.month, now.day, 9, 30);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Market open messages with variations
    final marketOpenMessages = [
      'Market is open! Check your portfolio and see how your stocks are performing today.',
      'The market is live! Time to check your trades and see those gains.',
      'Market\'s open! Your portfolio is waiting. Don\'t miss out on today\'s moves.',
      'Trading is live! Check your positions and see what\'s happening.',
      'Market opened! Time to see if your stocks are making you money today.',
      'The market is open! Your portfolio needs your attention.',
      'Trading started! Check your positions and see the action.',
      'Market\'s live! Don\'t miss today\'s opportunities.',
    ];

    // Schedule for next 30 days
    int scheduledCount = 0;
    for (int day = 0; day < 30; day++) {
      final date = scheduledDate.add(Duration(days: day));
      // Only schedule for weekdays (Monday = 1, Friday = 5)
      if (date.weekday >= 1 && date.weekday <= 5) {
        // Use rotation for variety
        final messageIndex = (day + DateTime.now().day) % marketOpenMessages.length;
        final title = await OrionCharacter.getNotificationTitle(CharacterMood.friendly, null);
        
        await scheduleNotification(
          id: _idBaseMarket + day,
          title: title,
          body: marketOpenMessages[messageIndex],
          scheduledDate: date,
          payload: 'market_open',
          channelId: _channelIdMarket,
          characterMood: CharacterMood.friendly,
        );
        scheduledCount++;
      }
    }
    print('✅ Scheduled $scheduledCount market open notifications');
  }

  /// Show immediate notification (for achievements, etc.)
  /// Note: On iOS Simulator, notifications may only appear in Notification Center
  /// Pull down from top of screen to see notifications
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = _channelIdGeneral,
    CharacterMood? characterMood, // Ory character mood for image
  }) async {
    if (!(await areNotificationsEnabled())) {
      print('⚠️ Notifications disabled in app settings');
      return;
    }

    // CRITICAL: Check and request permissions before showing
    print('🔔 Checking notification permissions...');
    final permissionsGranted = await arePermissionsGranted();
    if (!permissionsGranted) {
      print('⚠️ Permissions not granted, requesting now...');
      final requested = await requestPermissions();
      if (!requested) {
        print('❌❌❌ NOTIFICATION PERMISSIONS DENIED! ❌❌❌');
        print('   Notifications will NOT appear until permissions are granted.');
        print('   Go to: Settings > Orion > Notifications > Allow Notifications');
        return; // Don't try to show if permissions denied
      }
      print('✅ Permissions granted after request');
    } else {
      print('✅ Permissions already granted');
    }

    // Get Ory character image path based on mood
    String? characterImagePath;
    String? iosAttachmentPath;
    String? androidImagePath;
    ui.Image? androidImageBitmap;
    
    if (characterMood != null) {
      characterImagePath = OrionCharacter.getCharacterImagePath(characterMood);
      print('📸 Character image path: $characterImagePath for mood: $characterMood');
      
      // Copy asset to persistent file for both platforms
      final copiedPath = await _copyAssetToTempFile(characterImagePath);
      
      if (copiedPath != null) {
        if (Platform.isIOS) {
          iosAttachmentPath = copiedPath;
        }
        
        if (Platform.isAndroid) {
          androidImagePath = copiedPath;
          // Also load as bitmap for BigPictureStyle
          androidImageBitmap = await _loadImageBitmap(copiedPath);
        }
      } else {
        print('⚠️ Failed to copy character image for mood: $characterMood');
      }
    }
    
    // Build iOS attachments if we have a file path
    List<DarwinNotificationAttachment>? iosAttachments;
    if (Platform.isIOS && iosAttachmentPath != null) {
      try {
        print('📸 ========== CREATING iOS ATTACHMENT (showNotification) ==========');
        print('   Original path: $iosAttachmentPath');
        
        // Verify file exists before creating attachment
        final attachmentFile = File(iosAttachmentPath);
        final exists = await attachmentFile.exists();
        print('   File exists: $exists');
        
        if (exists) {
          // CRITICAL: Get absolute path - iOS requires absolute file path
          final absolutePath = attachmentFile.absolute.path;
          print('   Absolute path: $absolutePath');
          
          // CRITICAL: Ensure path uses forward slashes (iOS requirement)
          // Normalize path separators to forward slashes
          final normalizedPath = absolutePath.replaceAll('\\', '/');
          print('   Normalized path: $normalizedPath');
          
          // Verify normalized path file exists
          final normalizedFile = File(normalizedPath);
          final normalizedExists = await normalizedFile.exists();
          print('   Normalized file exists: $normalizedExists');
          
          if (normalizedExists) {
            // Verify file is readable and not empty
            final fileSize = await normalizedFile.length();
            print('   File size: $fileSize bytes');
            
            if (fileSize > 0) {
              // Try to read the file to verify it's accessible
              try {
                final testBytes = await normalizedFile.readAsBytes();
                print('   ✅ File is readable: ${testBytes.length} bytes');
                
                // Create attachment with unique identifier (required for iOS)
                // Use shorter ID to avoid issues
                final attachmentId = 'ory_${characterMood.toString().split('.').last}_$id';
                print('   Creating attachment with ID: $attachmentId');
                
                // CRITICAL: Verify file one more time before creating attachment
                // iOS is very strict about file accessibility
                final finalFile = File(normalizedPath);
                if (!await finalFile.exists()) {
                  print('❌ CRITICAL: File does not exist at normalized path: $normalizedPath');
                  // Don't return - continue without attachment
                } else {
                  final finalFileSize = await finalFile.length();
                  if (finalFileSize == 0) {
                    print('❌ CRITICAL: File is empty at: $normalizedPath');
                    // Don't return - continue without attachment
                  } else {
                    // CRITICAL: Use the absolute path directly - iOS needs exact file path
                    // Ensure path uses forward slashes (iOS requirement)
                    final finalAttachmentPath = finalFile.absolute.path.replaceAll('\\', '/');
                    print('   📁 Final attachment path: $finalAttachmentPath');
                    print('   📁 File size: $finalFileSize bytes');
                    
                    // CRITICAL: Create attachment with verified file path
                    // The identifier must be unique and the file must exist
                    try {
                      final attachment = DarwinNotificationAttachment(
                        finalAttachmentPath,
                        identifier: attachmentId,
                      );
                      
                      // Verify attachment was created
                      print('📸 Attachment object created:');
                      print('   - filePath: ${attachment.filePath}');
                      print('   - identifier: ${attachment.identifier}');
                      
                      iosAttachments = [attachment];
                      print('📸 ✅✅✅ iOS ATTACHMENT CREATED SUCCESSFULLY! ✅✅✅');
                      print('   💡 File location: Cache directory (iOS notification system accessible)');
                      print('   💡 File verified: exists=${await finalFile.exists()}, size=$finalFileSize bytes');
                    } catch (attachError) {
                      print('❌ CRITICAL ERROR creating DarwinNotificationAttachment: $attachError');
                      print('   This is why the mascot is NOT appearing!');
                      print('   Error details: $attachError');
                      // Don't return - continue without attachment
                    }
                  }
                }
              } catch (readError) {
                print('❌ ERROR reading file: $readError');
              }
            } else {
              print('⚠️ File exists but is empty (0 bytes)');
            }
          } else {
            print('⚠️ Normalized path file does not exist: $normalizedPath');
          }
        } else {
          print('⚠️ Attachment file does not exist: $iosAttachmentPath');
        }
        print('📸 ===========================================');
      } catch (e, stackTrace) {
        print('❌ ERROR creating iOS attachment: $e');
        print('   Stack: $stackTrace');
      }
    } else if (Platform.isIOS && characterMood != null) {
      print('⚠️ iOS attachment path is null for mood: $characterMood');
      print('   iosAttachmentPath: $iosAttachmentPath');
    } else if (Platform.isIOS) {
      print('⚠️ No character mood provided for iOS attachment');
    }

    try {
      // Build Android style - use BigPictureStyle for better mascot visibility (Duolingo-style)
      BigPictureStyleInformation? bigPictureStyle;
      if (androidImageBitmap != null) {
        try {
          // Convert ui.Image to ByteData for bitmap
          final byteData = await androidImageBitmap.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            bigPictureStyle = BigPictureStyleInformation(
              ByteArrayAndroidBitmap(byteData.buffer.asUint8List()),
              contentTitle: title,
              summaryText: body,
              largeIcon: androidImagePath != null 
                  ? FilePathAndroidBitmap(androidImagePath!) 
                  : null,
            );
            print('📸 Using BigPictureStyle for Android notification with mascot');
          }
        } catch (e) {
          print('⚠️ Error creating BigPictureStyle, falling back to BigText: $e');
        }
      }
      
      // CRITICAL: Final verification before showing
      if (Platform.isIOS && iosAttachments != null && iosAttachments!.isNotEmpty) {
        print('🔍 FINAL CHECK - iOS Attachments before showing:');
        for (var att in iosAttachments!) {
          final attFile = File(att.filePath);
          final exists = await attFile.exists();
          final size = exists ? await attFile.length() : 0;
          print('   ✅ Attachment: ${att.identifier}');
          print('      - Path: ${att.filePath}');
          print('      - Exists: $exists');
          print('      - Size: $size bytes');
        }
      } else if (Platform.isIOS && characterMood != null) {
        print('❌❌❌ CRITICAL: NO iOS ATTACHMENTS CREATED FOR MOOD: $characterMood ❌❌❌');
        print('   This is why the mascot is NOT appearing!');
      }
      
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _getChannelName(channelId),
          channelDescription: _getChannelDescription(channelId),
          importance: _getImportance(channelId),
          priority: _getPriority(channelId),
          largeIcon: androidImagePath != null 
              ? FilePathAndroidBitmap(androidImagePath!) 
              : null,
          styleInformation: bigPictureStyle ?? BigTextStyleInformation(body),
        ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            attachments: iosAttachments, // Now includes Ory character image!
            threadIdentifier: 'ory_notifications', // Group notifications together
            categoryIdentifier: 'ORY_NOTIFICATION', // CRITICAL: This triggers the Notification Content Extension
          ),
      );
      
      // CRITICAL: Verify attachments are in NotificationDetails
      if (Platform.isIOS) {
        print('🔍 NotificationDetails.iOS.attachments: ${notificationDetails.iOS?.attachments?.length ?? 0}');
        if (notificationDetails.iOS?.attachments != null) {
          for (var att in notificationDetails.iOS!.attachments!) {
            print('   ✅ In NotificationDetails: ${att.identifier} -> ${att.filePath}');
          }
        } else {
          print('❌❌❌ NO ATTACHMENTS IN NotificationDetails! ❌❌❌');
        }
      }
      
      // CRITICAL: For Notification Content Extension, pass image path in payload
      // The extension will read this from userInfo
      String? finalPayload = payload;
      if (Platform.isIOS && iosAttachmentPath != null) {
        // Include image path in payload JSON so extension can access it
        try {
          Map<String, dynamic> payloadMap;
          if (payload != null && payload.isNotEmpty) {
            // Try to parse as JSON
            try {
              payloadMap = jsonDecode(payload) as Map<String, dynamic>;
            } catch (e) {
              // If payload is not JSON, treat it as a string value
              payloadMap = {'type': payload};
            }
          } else {
            payloadMap = <String, dynamic>{};
          }
          payloadMap['image_path'] = iosAttachmentPath;
          finalPayload = jsonEncode(payloadMap);
          print('📸 Added image_path to payload for Notification Content Extension: $iosAttachmentPath');
        } catch (e) {
          print('⚠️ Could not add image_path to payload: $e');
          // Fallback: create simple payload with image path
          finalPayload = jsonEncode({'image_path': iosAttachmentPath, 'type': payload ?? 'notification'});
        }
      }
      
      print('📱 Showing notification immediately: $title');
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: finalPayload,
      );
      print('✅ Notification shown (ID: $id) - Check Notification Center if not visible');
    } catch (e, stackTrace) {
      print('❌ Error showing notification: $e');
      print('   Stack trace: $stackTrace');
      // Re-throw to let caller handle it
      rethrow;
    }
  }

  // ========== ACHIEVEMENT NOTIFICATIONS (with Ory character) ==========
  // MOOD MAPPING GUIDE:
  // - concerned: Streak lost, streak at risk (angry/worried Ory)
  // - excited: Achievements unlocked, level up (celebrating Ory)
  // - proud: Streak milestones (proud Ory)
  // - friendly: Regular reminders, market news, learning reminders (encouraging Ory)

  Future<void> showAchievementUnlocked(String badgeName, String description) async {
    final userProfile = await DatabaseService.loadUserProfile();
    final userName = userProfile?['displayName'] as String?;
    
    final message = await OrionCharacter.getNotificationMessage(
      mood: CharacterMood.excited,
      context: 'badge_unlocked',
      streak: null,
      userName: userName,
    );
    final title = await OrionCharacter.getNotificationTitle(
      CharacterMood.excited,
      null,
    );
    
    await showNotification(
      id: _idBaseAchievements + DateTime.now().millisecondsSinceEpoch % 1000,
      title: title,
      body: '$message\n\nYou earned: $badgeName - $description',
      payload: 'achievement:$badgeName',
      channelId: _channelIdAchievements,
      characterMood: CharacterMood.excited,
    );
    
    // Also add to in-app notification center
    try {
      await NotificationManager().addNotification(
        type: 'achievement',
        title: 'Badge Unlocked! 🏆',
        message: 'You earned: $badgeName - $description',
        data: {
          'badgeName': badgeName,
          'description': description,
        },
      );
    } catch (e) {
      print('⚠️ Error adding achievement to in-app notifications: $e');
    }
  }

  Future<void> showLevelUp(int newLevel) async {
    final userProfile = await DatabaseService.loadUserProfile();
    final userName = userProfile?['displayName'] as String?;
    
    final message = await OrionCharacter.getNotificationMessage(
      mood: CharacterMood.excited,
      context: 'level_up',
      streak: null,
      userName: userName,
    );
    final title = await OrionCharacter.getNotificationTitle(
      CharacterMood.excited,
      null,
    );
    
    await showNotification(
      id: _idBaseAchievements + DateTime.now().millisecondsSinceEpoch % 1000,
      title: title,
      body: '$message\n\nYou reached Level $newLevel! Keep learning to reach even higher!',
      payload: 'level_up:$newLevel',
      channelId: _channelIdAchievements,
      characterMood: CharacterMood.excited,
    );
    
    // Also add to in-app notification center
    try {
      await NotificationManager().addNotification(
        type: 'level_up',
        title: 'Level Up! 🎉',
        message: 'You reached Level $newLevel! Keep learning to reach even higher!',
        data: {
          'level': newLevel,
        },
      );
    } catch (e) {
      print('⚠️ Error adding level-up to in-app notifications: $e');
    }
  }

  Future<void> showStreakMilestone(int streak) async {
    final userProfile = await DatabaseService.loadUserProfile();
    final userName = userProfile?['displayName'] as String?;
    
    final message = await OrionCharacter.getNotificationMessage(
      mood: CharacterMood.proud,
      context: 'streak_milestone',
      streak: streak,
      userName: userName,
    );
    final title = await OrionCharacter.getNotificationTitle(
      CharacterMood.proud,
      streak,
    );
    
    await showNotification(
      id: _idBaseAchievements + DateTime.now().millisecondsSinceEpoch % 1000,
      title: title,
      body: message,
      payload: 'streak_milestone:$streak',
      channelId: _channelIdAchievements,
      characterMood: CharacterMood.proud,
    );
    
    // Also add to in-app notification center
    try {
      await NotificationManager().addNotification(
        type: 'streak',
        title: 'Streak Milestone 🔥',
        message: 'You reached a $streak-day streak! Ory is proud of you!',
        data: {
          'streak': streak,
        },
      );
    } catch (e) {
      print('⚠️ Error adding streak milestone to in-app notifications: $e');
    }
  }

  // ========== MARKET NEWS NOTIFICATIONS ==========

  Future<void> showMarketNewsNotification(String symbol, String headline) async {
    if (!(await isMarketNewsEnabled())) return;
    if (!(await areNotificationsEnabled())) return;

    // Get Ory message for market news
    final message = await OrionCharacter.getNotificationMessage(
      mood: CharacterMood.friendly,
      context: 'market_news',
      streak: null,
      userName: null,
    );
    final title = await OrionCharacter.getNotificationTitle(CharacterMood.friendly, null);
    
    // Combine Ory message with actual headline
    final body = '$message\n\n$headline';

    await showNotification(
      id: _idBaseMarket + DateTime.now().millisecondsSinceEpoch % 1000,
      title: title,
      body: body,
      payload: 'market_news:$symbol',
      channelId: _channelIdMarket,
      characterMood: CharacterMood.friendly,
    );
    
    // Also add to in-app notification center so user can see full news later
    try {
      await NotificationManager().addNotification(
        type: 'market_news',
        title: 'News: $symbol',
        message: headline,
        data: {
          'symbol': symbol,
          'headline': headline,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('⚠️ Error adding market news to in-app notifications: $e');
    }
  }
  
  /// Show streak lost notification (when streak breaks)
  Future<void> showStreakLostNotification(int lostStreak) async {
    if (!(await areNotificationsEnabled())) return;
    
    final message = await OrionCharacter.getNotificationMessage(
      mood: CharacterMood.concerned,
      context: 'streak_lost',
      streak: lostStreak,
      userName: null,
    );
    final title = await OrionCharacter.getNotificationTitle(CharacterMood.concerned, null);
    
    await showNotification(
      id: _idBaseStreak + 20000, // High ID to avoid conflicts
      title: title,
      body: message,
      payload: 'streak_lost:$lostStreak',
      channelId: _channelIdStreak,
      characterMood: CharacterMood.concerned,
    );
  }

  // ========== HELPER METHODS ==========

  String _getChannelName(String channelId) {
    switch (channelId) {
      case _channelIdStreak:
        return 'Streak Reminders';
      case _channelIdMarket:
        return 'Market Updates';
      case _channelIdLearning:
        return 'Learning Reminders';
      case _channelIdAchievements:
        return 'Achievements';
      default:
        return 'General Notifications';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _channelIdStreak:
        return 'Notifications to maintain your learning streak';
      case _channelIdMarket:
        return 'Stock market news and price alerts';
      case _channelIdLearning:
        return 'Daily learning reminders and lesson suggestions';
      case _channelIdAchievements:
        return 'Badge unlocks and milestone achievements';
      default:
        return 'General app notifications';
    }
  }

  Importance _getImportance(String channelId) {
    switch (channelId) {
      case _channelIdStreak:
      case _channelIdMarket:
      case _channelIdAchievements:
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  Priority _getPriority(String channelId) {
    switch (channelId) {
      case _channelIdStreak:
      case _channelIdMarket:
      case _channelIdAchievements:
        return Priority.high;
      default:
        return Priority.defaultPriority;
    }
  }

  /// Reschedule all notifications (call when preferences change)
  Future<void> rescheduleAllNotifications() async {
    print('🔄 Rescheduling all notifications with correct content...');
    await cancelAllScheduledNotifications();
    
    // Actually reschedule everything
    try {
      final gamification = GamificationService.instance;
      if (gamification != null) {
        await scheduleStreakReminders(gamification);
        await scheduleLearningReminders();
        await scheduleMarketOpenNotification();
        print('✅ All notifications rescheduled with correct titles and Ory images');
      } else {
        print('⚠️ GamificationService not available - skipping streak reminders');
        await scheduleLearningReminders();
        await scheduleMarketOpenNotification();
      }
    } catch (e) {
      print('❌ Error rescheduling notifications: $e');
    }
  }
  
  /// FORCE REFRESH: Cancel all and reschedule (for fixing old notifications)
  Future<void> forceRefreshAllNotifications() async {
    print('🔄 FORCE REFRESH: Cancelling all and rescheduling...');
    await rescheduleAllNotifications();
  }

  /// Open device settings (for when user denies permissions)
  Future<void> openAppSettings() async {
    try {
      if (Platform.isIOS) {
        // iOS: Open app settings
        final url = Uri.parse('app-settings:');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          print('⚠️ Could not open iOS settings');
        }
      } else if (Platform.isAndroid) {
        // Android: Open app settings
        final url = Uri.parse('package:com.orion.app');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          print('⚠️ Could not open Android settings');
        }
      }
    } catch (e) {
      print('⚠️ Error opening app settings: $e');
    }
  }

  // ========== TEST NOTIFICATIONS (for immediate testing) ==========

  /// Test notification - works on iOS Simulator!
  /// On iOS Simulator: Schedules for 5 seconds so you can minimize app first
  /// On real device: Shows immediately
  Future<bool> testNotification({
    String? title,
    String? body,
    CharacterMood? characterMood,
    String channelId = _channelIdGeneral,
    bool forceImmediate = false, // Set to true to try immediate show
  }) async {
    try {
      print('🧪 ========== TEST NOTIFICATION ==========');
      
      // CRITICAL: Initialize first if not already done
      if (!_initialized) {
        print('🔧 Initializing notification service...');
        await initialize();
      }
      
      // CRITICAL: Request permissions FIRST - iOS requires this
      print('🔔 Requesting notification permissions...');
      bool permissionsGranted = false;
      try {
        // Add timeout to prevent hanging
        permissionsGranted = await requestPermissions().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏱️ Permission request timed out - continuing anyway');
            return false; // Continue anyway
          },
        );
        print('🔔 Permission request completed. Result: $permissionsGranted');
      } catch (e) {
        print('❌ Error requesting permissions: $e');
        // Try to check current status
        try {
          permissionsGranted = await arePermissionsGranted(forceCheck: true).timeout(
            const Duration(seconds: 5),
            onTimeout: () => true, // Assume granted if timeout
          );
          print('🔔 Checked existing permissions: $permissionsGranted');
        } catch (e2) {
          print('❌ Error checking permissions: $e2');
          // Continue anyway - might work
          permissionsGranted = true;
        }
      }
      
      if (!permissionsGranted) {
        print('⚠️ Notification permissions may not be granted');
        print('💡 Go to iOS Settings > Orion > Notifications and enable them');
        print('💡 Continuing anyway - notification might still work');
      } else {
        print('✅ Permissions appear to be GRANTED');
      }
      
      // ALWAYS try to show notification (even if permissions uncertain)
      print('📱 Proceeding with notification display...');
      
      // Verify notifications are enabled in app settings
      if (!(await areNotificationsEnabled())) {
        print('⚠️ Notifications disabled in app settings');
        await setNotificationsEnabled(true);
        print('✅ Enabled notifications in app settings');
      }
      
      // Get user profile for personalization
      final userProfile = await DatabaseService.loadUserProfile();
      final userName = userProfile?['displayName'] as String?;
      
      // Use provided title/body or generate from character
      String notificationTitle;
      String notificationBody;
      
      if (title != null && body != null) {
        notificationTitle = title;
        notificationBody = body;
      } else if (characterMood != null) {
        // Get appropriate context based on mood for realistic test notifications
        String context = 'morning_streak';
        if (characterMood == CharacterMood.concerned) {
          context = 'streak_at_risk';
        } else if (characterMood == CharacterMood.excited) {
          context = 'badge_unlocked';
        } else if (characterMood == CharacterMood.proud) {
          context = 'streak_milestone';
        } else if (channelId == _channelIdLearning) {
          context = 'afternoon_learning';
        }
        
        final gamification = GamificationService.instance;
        final streak = gamification?.streak;
        
        notificationTitle = await OrionCharacter.getNotificationTitle(
          characterMood,
          streak,
        );
        notificationBody = await OrionCharacter.getNotificationMessage(
          mood: characterMood,
          context: context,
          streak: streak,
          userName: userName,
        );
      } else {
        notificationTitle = 'Hey. It\'s Ory.';
        notificationBody = 'This is a test notification. Just checking if everything works!';
      }
      
      // Use unique ID
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
      
      print('📱 Preparing notification with ID: $notificationId');
      print('   Title: $notificationTitle');
      print('   Body: $notificationBody');
      
      // Get Ory character image path if mood specified
      String? characterImagePath;
      String? iosAttachmentPath;
      String? androidImagePath;
      ui.Image? androidImageBitmap;
      
      if (characterMood != null) {
        characterImagePath = OrionCharacter.getCharacterImagePath(characterMood);
        print('📸 Character image path: $characterImagePath for mood: $characterMood');
        
        // Copy asset to persistent file for both platforms
        final copiedPath = await _copyAssetToTempFile(characterImagePath);
        
        if (copiedPath != null) {
          if (Platform.isIOS) {
            iosAttachmentPath = copiedPath;
            print('✅ Ory character image ready for iOS: $iosAttachmentPath');
          }
          
          if (Platform.isAndroid) {
            androidImagePath = copiedPath;
            // Also load as bitmap for BigPictureStyle
            androidImageBitmap = await _loadImageBitmap(copiedPath);
            if (androidImageBitmap != null) {
              print('✅ Ory character image ready for Android (bitmap loaded): $androidImagePath');
            } else {
              print('⚠️ Could not load bitmap for Android, will use file path');
            }
          }
        } else {
          print('⚠️ Failed to copy character image for mood: $characterMood');
        }
      }
      
      // Build iOS attachments if we have a file path
      List<DarwinNotificationAttachment>? iosAttachments;
      if (Platform.isIOS && iosAttachmentPath != null) {
        try {
          // Verify file exists and is accessible
          final attachmentFile = File(iosAttachmentPath);
          if (await attachmentFile.exists()) {
            final fileSize = await attachmentFile.length();
            print('📸 Verifying attachment file: $iosAttachmentPath (${fileSize} bytes)');
            
            // iOS requires file to be readable and in correct format
            if (fileSize > 0) {
              // Create attachment with identifier (required for iOS)
              // Use unique identifier to avoid conflicts
              final attachmentId = 'ory_${characterMood.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}';
              
              // CRITICAL: iOS requires the file path to be absolute and accessible
              // The path from _copyAssetToTempFile is already absolute, but verify it
              final absolutePath = attachmentFile.absolute.path;
              
              // CRITICAL: Ensure path uses forward slashes (iOS requirement)
              // Normalize path separators to forward slashes
              final normalizedPath = absolutePath.replaceAll('\\', '/');
              print('   Normalized path: $normalizedPath');
              
              // Triple-check: verify original, absolute, and file is readable
              final originalExists = await attachmentFile.exists();
              final normalizedFile = File(normalizedPath);
              final normalizedExists = await normalizedFile.exists();
              final fileReadable = normalizedExists && await normalizedFile.length() > 0;
              
              if (originalExists && normalizedExists && fileReadable) {
                // CRITICAL: Create attachment with normalized path
                // iOS requires the file to exist and be accessible at notification time
                try {
                  // CRITICAL FIX: Create attachment with normalized path (forward slashes)
                  // The identifier is optional but helps iOS identify the attachment
                  // IMPORTANT: File must be in Application Support directory for persistence
                  final attachment = DarwinNotificationAttachment(
                    normalizedPath,
                    identifier: attachmentId,
                  );
                  iosAttachments = [attachment];
                  
                  // Verify attachment was created
                  print('📸 Attachment object created: ${attachment.filePath}');
                  print('📸 ✅✅✅ iOS attachment created with Ory image! ✅✅✅');
                  print('   Normalized Path: $normalizedPath');
                  print('   ID: $attachmentId');
                  print('   Size: $fileSize bytes');
                  print('   ✅ File verified: original=$originalExists, normalized=$normalizedExists, readable=$fileReadable');
                  print('   💡 File location: Application Support (persists across app restarts)');
                  
                  // Final verification: try to read the file one more time
                  final testRead = await normalizedFile.readAsBytes();
                  if (testRead.isEmpty) {
                    print('⚠️ WARNING: File exists but readAsBytes returned empty!');
                    iosAttachments = null;  // Don't use broken attachment
                  } else {
                    print('   ✅ File read test passed: ${testRead.length} bytes');
                  }
                } catch (e) {
                  print('❌ ERROR creating DarwinNotificationAttachment: $e');
                  print('   This is why the mascot is not showing!');
                  iosAttachments = null;
                }
              } else {
                print('❌❌❌ File verification FAILED! ❌❌❌');
                print('   Original exists: $originalExists');
                print('   Normalized exists: $normalizedExists');
                print('   File readable: $fileReadable');
                print('   Original path: $iosAttachmentPath');
                print('   Normalized path: $normalizedPath');
                print('   💡 This is why mascot is not showing!');
                // Skip creating attachment but continue with notification
              }
            } else {
              print('⚠️ Attachment file is empty: $iosAttachmentPath');
            }
          } else {
            print('⚠️ Attachment file does not exist: $iosAttachmentPath');
          }
        } catch (e, stackTrace) {
          print('❌ Error creating iOS attachment: $e');
          print('   Stack: $stackTrace');
        }
      } else if (Platform.isIOS && characterMood != null) {
        print('⚠️ iOS attachment path is null for mood: $characterMood');
      }
      
      // iOS Simulator BUG: Scheduled notifications don't fire reliably
      // SOLUTION: Always use immediate show, but add delay so user can minimize app first
      if (!forceImmediate && Platform.isIOS) {
        print('⏰ iOS Simulator detected - using delayed immediate show');
        print('   ⚠️ CRITICAL: PRESS Cmd+H NOW to minimize the app!');
        print('   💡 iOS Simulator suppresses notifications when app is in foreground');
        print('   ⏳ Waiting 3 seconds for you to minimize the app...');
        
        // Wait 3 seconds so user can minimize app
        await Future.delayed(const Duration(seconds: 3));
        
        print('   ✅ Delay complete - showing notification now...');
        // Fall through to immediate show below
      }
      
      // Fallback: Show immediately (works better on real devices)
      print('📱 Showing notification IMMEDIATELY...');
      print('   Notification ID: $notificationId');
      print('   Title: "$notificationTitle"');
      print('   Body: "${notificationBody.substring(0, notificationBody.length > 50 ? 50 : notificationBody.length)}..."');
      print('   Platform: ${Platform.isIOS ? "iOS" : "Android"}');
      print('   Has iOS attachments: ${iosAttachments != null && iosAttachments!.isNotEmpty}');
      print('   Has Android image: ${androidImagePath != null}');
      
      try {
        // Final verification before showing
        if (Platform.isIOS && iosAttachments != null && iosAttachments!.isNotEmpty) {
          final attachment = iosAttachments!.first;
          print('📸 FINAL CHECK - iOS Attachment:');
          print('   File path: ${attachment.filePath}');
          // Verify file still exists
          final file = File(attachment.filePath);
          if (await file.exists()) {
            final size = await file.length();
            print('   ✅ File exists: ${size} bytes');
          } else {
            print('   ❌ File does NOT exist! This is the problem!');
          }
        }
        
        // Build Android style - use BigPictureStyle for better mascot visibility (Duolingo-style)
        BigPictureStyleInformation? bigPictureStyle;
        if (androidImageBitmap != null) {
          try {
            // Convert ui.Image to ByteData for bitmap
            final byteData = await androidImageBitmap.toByteData(format: ui.ImageByteFormat.png);
            if (byteData != null) {
              bigPictureStyle = BigPictureStyleInformation(
                ByteArrayAndroidBitmap(byteData.buffer.asUint8List()),
                contentTitle: notificationTitle,
                summaryText: notificationBody,
                largeIcon: androidImagePath != null 
                    ? FilePathAndroidBitmap(androidImagePath!) 
                    : null,
              );
              print('📸 Using BigPictureStyle for Android notification with mascot');
            }
          } catch (e) {
            print('⚠️ Error creating BigPictureStyle, falling back to BigText: $e');
          }
        }
        
        print('📱 Calling _notifications.show()...');
        final notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _getChannelName(channelId),
            channelDescription: _getChannelDescription(channelId),
            importance: _getImportance(channelId),
            priority: _getPriority(channelId),
            largeIcon: androidImagePath != null 
                ? FilePathAndroidBitmap(androidImagePath!) 
                : null,
            styleInformation: bigPictureStyle ?? BigTextStyleInformation(notificationBody),
          ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              attachments: iosAttachments, // Now includes Ory character image!
              threadIdentifier: 'ory_notifications', // Group notifications together
              categoryIdentifier: 'ORY_NOTIFICATION', // CRITICAL: This triggers the Notification Content Extension
            ),
        );
        
        // CRITICAL DEBUG: Log EVERYTHING about attachments
        if (Platform.isIOS) {
          print('');
          print('🔍🔍🔍 CRITICAL ATTACHMENT DEBUG 🔍🔍🔍');
          print('   iosAttachments variable: ${iosAttachments != null ? "NOT NULL" : "NULL"}');
          print('   iosAttachments length: ${iosAttachments?.length ?? 0}');
          if (iosAttachments != null && iosAttachments!.isNotEmpty) {
            for (int i = 0; i < iosAttachments!.length; i++) {
              final att = iosAttachments![i];
              print('   Attachment $i:');
              print('      - filePath: ${att.filePath}');
              final attFile = File(att.filePath);
              final exists = await attFile.exists();
              print('      - File exists: $exists');
              if (exists) {
                final size = await attFile.length();
                print('      - File size: $size bytes');
                // Try to read first few bytes to verify it's accessible
                try {
                  final testBytes = await attFile.readAsBytes();
                  print('      - Can read file: YES (${testBytes.length} bytes)');
                } catch (e) {
                  print('      - Can read file: NO - ERROR: $e');
                }
              }
            }
          } else {
            print('   ⚠️⚠️⚠️ NO ATTACHMENTS IN LIST! ⚠️⚠️⚠️');
          }
          print('   NotificationDetails.iOS.attachments: ${notificationDetails.iOS?.attachments?.length ?? 0}');
          if (notificationDetails.iOS?.attachments != null && notificationDetails.iOS!.attachments!.isNotEmpty) {
            print('   ✅ Attachments passed to NotificationDetails!');
            for (var att in notificationDetails.iOS!.attachments!) {
              print('      - NotificationDetails attachment: ${att.filePath}');
            }
          } else {
            print('   ❌❌❌ NO ATTACHMENTS IN NotificationDetails! ❌❌❌');
            print('   This means attachments are NOT being passed to the notification!');
          }
          print('🔍🔍🔍 END ATTACHMENT DEBUG 🔍🔍🔍');
          print('');
        }
        
        await _notifications.show(
          notificationId,
          notificationTitle,
          notificationBody,
          notificationDetails,
          payload: 'test_notification',
        );
        
        print('✅ Notification.show() completed without errors!');
        if (iosAttachments != null && iosAttachments!.isNotEmpty) {
          print('📸 ✅ Ory character image attached to notification');
          print('   💡 Check Notification Center - image should appear on the RIGHT side');
          print('   💡 If image still not visible, check console for file path errors above');
        } else if (Platform.isIOS && characterMood != null) {
          print('⚠️ WARNING: No iOS attachments created for mood: $characterMood');
          print('   💡 This means the image file was not created or is not accessible');
        }
        if (androidImagePath != null) {
          print('📸 Android large icon set: $androidImagePath');
        }
        print('');
        print('📱 IMPORTANT:');
        print('   - On iOS: Notification may appear in Notification Center (pull down from top)');
        print('   - On iOS Simulator: Press Cmd+H to minimize app, then check Notification Center');
        print('   - On real device: Notification should appear immediately');
        print('   - If not visible, check Settings > Orion > Notifications');
        print('');
        print('🧪 ======================================');
        return true;
      } catch (e, stackTrace) {
        print('❌ ERROR showing notification: $e');
        print('   Error type: ${e.runtimeType}');
        print('   Stack trace: $stackTrace');
        print('');
        print('💡 Troubleshooting:');
        print('   1. Check if notifications are enabled in iOS Settings');
        print('   2. Try restarting the app');
        print('   3. Check console for permission errors');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ ERROR in testNotification: $e');
      print('   Type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Test streak reminder notification
  Future<bool> testStreakReminder({int? streak}) async {
    final gamification = GamificationService.instance;
    final testStreak = streak ?? (gamification?.streak ?? 5);
    
    return await testNotification(
      characterMood: CharacterMood.friendly,
      channelId: _channelIdStreak,
    );
  }

  /// Test learning reminder notification
  Future<bool> testLearningReminder() async {
    return await testNotification(
      characterMood: CharacterMood.friendly,
      channelId: _channelIdLearning,
    );
  }

  /// Test achievement notification
  Future<bool> testAchievementNotification() async {
    return await testNotification(
      characterMood: CharacterMood.excited,
      channelId: _channelIdAchievements,
    );
  }

  /// Test market news notification
  Future<bool> testMarketNews() async {
    return await testNotification(
      channelId: _channelIdMarket,
      characterMood: CharacterMood.friendly,
    );
  }

  /// QUICK TEST: Show a notification immediately (for debugging)
  /// This is the simplest way to test if notifications work
  Future<bool> quickTestNotification() async {
    try {
      print('🚀 ========== QUICK NOTIFICATION TEST ==========');
      
      // Initialize
      if (!_initialized) {
        await initialize();
      }
      
      // Request permissions
      print('🔔 Requesting permissions...');
      final granted = await requestPermissions();
      print('   Permissions granted: $granted');
      
      if (!granted) {
        print('❌ PERMISSIONS NOT GRANTED!');
        print('   Go to: Settings > Orion > Notifications > Allow Notifications');
        return false;
      }
      
      // Show notification immediately
      print('📱 Showing test notification NOW...');
      await showNotification(
        id: 99999,
        title: 'Test Notification',
        body: 'If you see this, notifications work! 🎉',
        characterMood: CharacterMood.friendly,
      );
      
      print('✅ Notification sent! Check your notification center.');
      print('   On iOS: Pull down from top of screen');
      print('   If app is in foreground, minimize it first (Cmd+H)');
      return true;
    } catch (e, stackTrace) {
      print('❌ ERROR in quickTestNotification: $e');
      print('   Stack: $stackTrace');
      return false;
    }
  }

  /// Test all notification types (one after another with 3 second delays)
  /// Shows notifications immediately (not scheduled) - works better on iOS Simulator
  /// Tests all Ory character moods: friendly, concerned, excited, proud
  /// Shows multiple variations to demonstrate rotation system
  Future<void> testAllNotificationTypes() async {
    print('🧪 Testing ALL notification types with Ory character images...');
    print('📱 This will show multiple variations of each notification type');
    print('');
    print('⚠️⚠️⚠️ CRITICAL FOR iOS SIMULATOR: ⚠️⚠️⚠️');
    print('   iOS Simulator suppresses notifications when app is in FOREGROUND!');
    print('   SOLUTION: Press Cmd+H NOW to minimize the app BEFORE notifications appear');
    print('   Then pull down from top to see Notification Center');
    print('');
    
    // CRITICAL: Cancel ALL old notifications first
    print('🗑️ Cancelling all old notifications...');
    await cancelAllScheduledNotifications();
    
    // Request permissions once for all tests
    final permissionsGranted = await requestPermissions();
    if (!permissionsGranted) {
      print('❌ Notification permissions not granted - cannot test');
      return;
    }
    
    print('');
    print('⏰ Notifications will appear 3 seconds after each test starts');
    print('   👉 PRESS Cmd+H NOW to minimize the app!');
    print('   👉 Keep app minimized - notifications will appear automatically');
    print('   👉 Pull down from top to see Notification Center');
    print('');
    
    final gamification = GamificationService.instance;
    final streak = gamification?.streak ?? 5;
    
    int testNumber = 1;
    
    // ========== FRIENDLY ORY - MORNING STREAK REMINDERS (3 variations) ==========
    print('🧪 Test $testNumber-${testNumber + 2}: Friendly Ory - Morning Streak Reminders (3 variations)');
    print('⚠️ CRITICAL: Press Cmd+H NOW to minimize app BEFORE notifications appear!');
    for (int i = 0; i < 3; i++) {
      await testNotification(
        characterMood: CharacterMood.friendly,
        channelId: _channelIdStreak,
        forceImmediate: false, // Will use delayed immediate show
      );
      if (i < 2) await Future.delayed(const Duration(seconds: 5)); // Wait between notifications
    }
    testNumber += 3;
    await Future.delayed(const Duration(seconds: 2));
    
    // ========== FRIENDLY ORY - AFTERNOON LEARNING REMINDERS (3 variations) ==========
    print('🧪 Test $testNumber-${testNumber + 2}: Friendly Ory - Learning Reminders (3 variations)');
    for (int i = 0; i < 3; i++) {
      await testNotification(
        characterMood: CharacterMood.friendly,
        channelId: _channelIdLearning,
        forceImmediate: false,
      );
      if (i < 2) await Future.delayed(const Duration(seconds: 5));
    }
    testNumber += 3;
    await Future.delayed(const Duration(seconds: 2));
    
    // ========== FRIENDLY ORY - EVENING STREAK REMINDERS (3 variations) ==========
    print('🧪 Test $testNumber-${testNumber + 2}: Friendly Ory - Evening Streak Reminders (3 variations)');
    for (int i = 0; i < 3; i++) {
      await testNotification(
        characterMood: CharacterMood.friendly,
        channelId: _channelIdStreak,
        forceImmediate: false,
      );
      if (i < 2) await Future.delayed(const Duration(seconds: 5));
    }
    testNumber += 3;
    await Future.delayed(const Duration(seconds: 2));
    
    // ========== CONCERNED ORY - STREAK AT RISK (3 variations) ==========
    print('🧪 Test $testNumber-${testNumber + 2}: Concerned Ory - Streak at Risk (AGGRESSIVE! 3 variations)');
    for (int i = 0; i < 3; i++) {
      await testNotification(
        characterMood: CharacterMood.concerned,
        channelId: _channelIdStreak,
        forceImmediate: false,
      );
      if (i < 2) await Future.delayed(const Duration(seconds: 5));
    }
    testNumber += 3;
    await Future.delayed(const Duration(seconds: 2));
    
    // ========== EXCITED ORY - ACHIEVEMENT UNLOCKED (3 variations) ==========
    print('🧪 Test $testNumber-${testNumber + 2}: Excited Ory - Achievement Unlocked (3 variations)');
    for (int i = 0; i < 3; i++) {
      await testNotification(
        characterMood: CharacterMood.excited,
        channelId: _channelIdAchievements,
        forceImmediate: false,
      );
      if (i < 2) await Future.delayed(const Duration(seconds: 5));
    }
    testNumber += 3;
    await Future.delayed(const Duration(seconds: 2));
    
    // ========== PROUD ORY - STREAK MILESTONE (3 variations) ==========
    print('🧪 Test $testNumber-${testNumber + 2}: Proud Ory - Streak Milestone (3 variations)');
    for (int i = 0; i < 3; i++) {
      await testNotification(
        characterMood: CharacterMood.proud,
        channelId: _channelIdStreak,
        forceImmediate: false,
      );
      if (i < 2) await Future.delayed(const Duration(seconds: 5));
    }
    testNumber += 3;
    await Future.delayed(const Duration(seconds: 2));
    
    // ========== MARKET NEWS (no character) ==========
    print('🧪 Test $testNumber: Market News');
    await testMarketNews();
    
    print('');
    print('✅ ALL test notifications scheduled! ($testNumber total notifications)');
    print('');
    print('⚠️ CRITICAL FOR iOS SIMULATOR:');
    print('   1. Press Cmd+H NOW to minimize the app');
    print('   2. Wait 2-4 seconds for each notification');
    print('   3. Pull down from top to see Notification Center');
    print('   4. Notifications will appear when app is in background');
    print('');
    print('📱 You should see all Ory character images:');
    print('   - Friendly Ory (blue, encouraging) - Multiple variations');
    print('   - Concerned Ory (worried, aggressive) - Multiple variations');
    print('   - Excited Ory (celebrating) - Multiple variations');
    print('   - Proud Ory (proud of progress) - Multiple variations');
    print('');
    print('💡 Each notification type has 8+ variations that rotate automatically');
    print('💡 On real device: Notifications appear as alerts automatically');
    print('');
    print('🎯 All notifications feature:');
    print('   ✅ Short, punchy titles (Duolingo-style)');
    print('   ✅ Aggressive, guilty marketing content');
    print('   ✅ Ory character images (context-based)');
    print('   ✅ Multiple rotations to avoid monotony');
  }
}

