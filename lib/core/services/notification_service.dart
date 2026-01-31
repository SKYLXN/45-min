import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service for handling local notifications, particularly for daily training reminders
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static const String _dailyReminderKey = 'daily_training_reminder';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _reminderEnabledKey = 'reminder_enabled';
  
  /// Initialize notification service
  static Future<void> initialize() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();
    
    // Android initialization with notification channels
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const DarwinInitializationSettings iOSSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channels for Android
    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      'daily_training',
      'Daily Training Reminders',
      description: 'Reminders for your daily workout sessions',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    
    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_channel',
      'Test Notifications',
      description: 'Test notifications for 45min app',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(dailyChannel);
      await androidImplementation.createNotificationChannel(testChannel);
      print('Notification channels created successfully');
    }
    
    print('Notification service initialized successfully');
  }
  
  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Navigate to workout screen or main app
    // This will be handled by the router
    print('Notification tapped: ${response.payload}');
  }
  
  /// Request notification permissions
  static Future<bool> _requestPermissions() async {
    // For iOS, request permissions through the plugin first
    final iOSImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    
    if (iOSImplementation != null) {
      final result = await iOSImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    
    // For Android, request notification permission using permission_handler
    final notificationStatus = await Permission.notification.request();
    
    // Also request exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    
    return notificationStatus == PermissionStatus.granted;
  }
  
  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }
  
  /// Check current notification permission status
  static Future<bool> hasNotificationPermission() async {
    // Check iOS permissions
    final iOSImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    
    if (iOSImplementation != null) {
      final settings = await iOSImplementation.checkPermissions();
      return settings?.isEnabled == true;
    }
    
    // Check Android permissions
    final status = await Permission.notification.status;
    return status == PermissionStatus.granted;
  }
  
  /// Enable or disable daily training reminders
  static Future<bool> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (enabled) {
      // First check if we already have permission
      final hasPermission = await hasNotificationPermission();
      
      if (!hasPermission) {
        // Request permissions
        final permissionGranted = await _requestPermissions();
        if (!permissionGranted) {
          print('Permission not granted for notifications');
          return false;
        }
      }
      
      // Schedule the daily reminder
      try {
        await _scheduleDailyReminder();
      } catch (e) {
        print('Error scheduling notification: $e');
        return false;
      }
    } else {
      // Cancel the daily reminder
      await _cancelDailyReminder();
    }
    
    await prefs.setBool(_reminderEnabledKey, enabled);
    return true;
  }
  
  /// Set the time for daily training reminders
  static Future<void> setDailyReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderTimeKey, '$hour:$minute');
    
    // Reschedule if reminders are enabled
    final enabled = await areNotificationsEnabled();
    if (enabled) {
      await _scheduleDailyReminder();
    }
  }
  
  /// Get the current reminder time (defaults to 9:00 AM)
  static Future<Map<String, int>> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_reminderTimeKey) ?? '9:0';
    final parts = timeString.split(':');
    
    return {
      'hour': int.parse(parts[0]),
      'minute': int.parse(parts[1]),
    };
  }
  
  /// Schedule daily training reminder
  static Future<void> _scheduleDailyReminder() async {
    // Cancel existing reminder first
    await _cancelDailyReminder();
    
    final reminderTime = await getDailyReminderTime();
    
    // Create notification details
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      'daily_training',
      'Daily Training Reminders',
      channelDescription: 'Reminders for your daily workout sessions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    // Schedule daily at specified time
    await _notifications.zonedSchedule(
      0, // notification id
      '💪 Time to Train!', // title
      'Your 45-minute workout is waiting for you. Let\'s get stronger today!', // body
      _nextInstanceOfTime(reminderTime['hour']!, reminderTime['minute']!),
      notificationDetails,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_training_reminder',
    );
  }
  
  /// Cancel daily training reminder
  static Future<void> _cancelDailyReminder() async {
    await _notifications.cancel(0);
  }
  
  /// Calculate next instance of given time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local, 
      now.year, 
      now.month, 
      now.day, 
      hour, 
      minute
    );
    
    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  /// Open app settings for manual permission setup
  static Future<void> openPermissionSettings() async {
    // This will open settings if the user previously denied
    if (await Permission.notification.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      // Try requesting again
      await Permission.notification.request();
    }
  }
  
  /// Send immediate notification (for testing)
  static Future<void> sendTestNotification() async {
    // Check permissions first
    final hasPermission = await hasNotificationPermission();
    if (!hasPermission) {
      print('No permission for test notification');
      throw Exception('Notification permission not granted');
    }
    
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notifications for 45min app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    try {
      await _notifications.show(
        999,
        '🧪 Test Notification',
        'This is a test notification from your 45min app!',
        notificationDetails,
        payload: 'test_notification',
      );
      print('Test notification sent successfully');
    } catch (e) {
      print('Error sending test notification: $e');
      throw Exception('Failed to send test notification: $e');
    }
  }
}

/// Provider for notification service state
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for notification enabled status
final notificationEnabledProvider = FutureProvider<bool>((ref) async {
  return await NotificationService.areNotificationsEnabled();
});

/// Provider for reminder time
final reminderTimeProvider = FutureProvider<Map<String, int>>((ref) async {
  return await NotificationService.getDailyReminderTime();
});