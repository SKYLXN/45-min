import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';

/// A floating action button for quick notification actions
class NotificationFloatingButton extends ConsumerWidget {
  const NotificationFloatingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationEnabled = ref.watch(notificationEnabledProvider);

    return notificationEnabled.when(
      data: (enabled) => FloatingActionButton.extended(
        onPressed: () => _showQuickActions(context, ref, enabled),
        backgroundColor: enabled ? Colors.green : Colors.grey,
        foregroundColor: Colors.white,
        icon: Icon(enabled ? Icons.notifications_active : Icons.notifications_off),
        label: Text(enabled ? 'Reminders On' : 'Reminders Off'),
      ),
      loading: () => const FloatingActionButton(
        onPressed: null,
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => FloatingActionButton(
        onPressed: () => _showQuickActions(context, ref, false),
        backgroundColor: Colors.red,
        child: const Icon(Icons.error),
      ),
    );
  }

  void _showQuickActions(BuildContext context, WidgetRef ref, bool currentlyEnabled) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Daily Training Reminders',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Toggle Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _toggleNotifications(context, ref, !currentlyEnabled);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentlyEnabled ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(currentlyEnabled ? Icons.notifications_off : Icons.notifications_active),
                label: Text(
                  currentlyEnabled ? 'Turn Off Reminders' : 'Turn On Reminders',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Test Notification Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _sendTestNotification(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.send),
                label: const Text('Send Test Notification'),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(BuildContext context, WidgetRef ref, bool enable) async {
    try {
      final success = await NotificationService.setDailyReminderEnabled(enable);
      
      // Refresh the provider
      ref.invalidate(notificationEnabledProvider);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  enable ? Icons.notifications_active : Icons.notifications_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  enable 
                    ? '✅ Daily reminders enabled! You\'ll get notifications at 9:00 AM'
                    : '⏸️ Daily reminders disabled'
                ),
              ],
            ),
            backgroundColor: enable ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (enable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '❌ Could not enable notifications. Please check your permission settings.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    try {
      await NotificationService.sendTestNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('🧪 Test notification sent!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}