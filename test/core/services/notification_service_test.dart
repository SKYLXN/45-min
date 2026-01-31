import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forty_five_min/core/services/notification_service.dart';

void main() {
  group('NotificationService Tests', () {
    setUp(() {
      // Clear any existing preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should return false for notifications enabled by default', () async {
      final enabled = await NotificationService.areNotificationsEnabled();
      expect(enabled, false);
    });

    test('should return default reminder time of 9:00 AM', () async {
      final time = await NotificationService.getDailyReminderTime();
      expect(time['hour'], 9);
      expect(time['minute'], 0);
    });

    test('should set and get reminder time correctly', () async {
      // Set reminder time to 2:30 PM
      await NotificationService.setDailyReminderTime(14, 30);
      
      final time = await NotificationService.getDailyReminderTime();
      expect(time['hour'], 14);
      expect(time['minute'], 30);
    });

    test('should properly format time string for storage', () async {
      // Set a time with single digit minute
      await NotificationService.setDailyReminderTime(7, 5);
      
      final time = await NotificationService.getDailyReminderTime();
      expect(time['hour'], 7);
      expect(time['minute'], 5);
    });
  });
}