import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Service for integrating with Apple Reminders app via platform channels
class AppleRemindersService {
  static const MethodChannel _channel = MethodChannel('com.45min/reminders');
  
  /// Check if running on iOS
  bool get isIOS => Platform.isIOS;

  /// Check if reminders access is granted
  Future<bool> hasRemindersAccess() async {
    if (!isIOS) return false;
    
    try {
      final bool result = await _channel.invokeMethod('hasRemindersAccess');
      return result;
    } on PlatformException catch (e) {
      print('Error checking reminders access: $e');
      return false;
    } on MissingPluginException catch (e) {
      print('Reminders native implementation not available: $e');
      return false;
    }
  }

  /// Request permission to access reminders
  Future<bool> requestRemindersAccess() async {
    if (!isIOS) return false;
    
    try {
      final bool result = await _channel.invokeMethod('requestRemindersAccess');
      return result;
    } on PlatformException catch (e) {
      print('Error requesting reminders access: $e');
      return false;
    } on MissingPluginException catch (e) {
      print('Reminders native implementation not available: $e');
      return false;
    }
  }

  /// Export shopping list to Apple Reminders
  /// Creates a new reminder list with shopping items
  Future<bool> exportShoppingList({
    required String listTitle,
    required List<String> items,
    DateTime? dueDate,
  }) async {
    if (!isIOS) return false;
    
    try {
      // Check/request permission
      final hasAccess = await hasRemindersAccess();
      if (!hasAccess) {
        final granted = await requestRemindersAccess();
        if (!granted) {
          return false;
        }
      }

      final Map<String, dynamic> arguments = {
        'listTitle': listTitle,
        'items': items,
        'dueDate': dueDate?.toIso8601String(),
      };

      final bool result = await _channel.invokeMethod('exportShoppingList', arguments);
      return result;
    } on PlatformException catch (e) {
      print('Error exporting shopping list: $e');
      return false;
    } on MissingPluginException catch (e) {
      print('Reminders native implementation not available: $e');
      return false;
    }
  }

  /// Export shopping list with categories
  /// Creates separate reminders for each category section
  Future<bool> exportCategorizedShoppingList({
    required String listTitle,
    required Map<String, List<String>> categorizedItems,
    DateTime? dueDate,
  }) async {
    if (!isIOS) return false;
    
    try {
      final hasAccess = await hasRemindersAccess();
      if (!hasAccess) {
        final granted = await requestRemindersAccess();
        if (!granted) {
          return false;
        }
      }

      final Map<String, dynamic> arguments = {
        'listTitle': listTitle,
        'categorizedItems': categorizedItems,
        'dueDate': dueDate?.toIso8601String(),
      };

      final bool result = await _channel.invokeMethod(
        'exportCategorizedShoppingList',
        arguments,
      );
      return result;
    } on PlatformException catch (e) {
      print('Error exporting categorized shopping list: $e');
      return false;
    } on MissingPluginException catch (e) {
      print('Reminders native implementation not available: $e');
      return false;
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Clear shopping list
  Future<bool> clearShoppingList(String listTitle) async {
    if (!isIOS) return false;
    
    try {
      final bool result = await _channel.invokeMethod('clearShoppingList', {
        'listTitle': listTitle,
      });
      return result;
    } on PlatformException catch (e) {
      print('Error clearing shopping list: $e');
      return false;
    } on MissingPluginException catch (e) {
      print('Reminders native implementation not available: $e');
      return false;
    }
  }

  /// Check if a shopping list already exists
  Future<bool> shoppingListExists(String listTitle) async {
    if (!isIOS) return false;
    
    try {
      final bool result = await _channel.invokeMethod('shoppingListExists', {
        'listTitle': listTitle,
      });
      return result;
    } on PlatformException catch (e) {
      print('Error checking if shopping list exists: $e');
      return false;
    } on MissingPluginException catch (e) {
      print('Reminders native implementation not available: $e');
      return false;
    }
  }

  /// Get count of items in shopping list
  Future<int> getShoppingListItemCount(String listTitle) async {
    if (!isIOS) return 0;
    
    try {
      final int result = await _channel.invokeMethod('getShoppingListItemCount', {
        'listTitle': listTitle,
      });
      return result;
    } on PlatformException catch (e) {
      print('Error getting shopping list item count: $e');
      return 0;
    } on MissingPluginException catch (e) {
      print('Reminders native implementation not available: $e');
      return 0;
    }
  }
}
