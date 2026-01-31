import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';

/// Settings widget for managing daily training reminders
class NotificationSettingsWidget extends ConsumerStatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  ConsumerState<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends ConsumerState<NotificationSettingsWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final notificationEnabled = ref.watch(notificationEnabledProvider);
    final reminderTime = ref.watch(reminderTimeProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Training Reminders',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Get motivated to maintain your daily workout routine with personalized reminders.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Enable/Disable Toggle
            notificationEnabled.when(
              data: (enabled) => SwitchListTile(
                title: const Text('Enable Daily Reminders'),
                subtitle: Text(
                  enabled 
                    ? 'You\'ll receive daily workout reminders'
                    : 'Turn on to get daily workout notifications'
                ),
                value: enabled,
                onChanged: _isLoading ? null : (value) => _toggleNotifications(value),
                secondary: Icon(
                  enabled ? Icons.notifications : Icons.notifications_off,
                ),
              ),
              loading: () => const ListTile(
                title: Text('Enable Daily Reminders'),
                subtitle: Text('Loading...'),
                leading: CircularProgressIndicator(),
              ),
              error: (error, stack) => ListTile(
                title: const Text('Enable Daily Reminders'),
                subtitle: Text('Error: $error'),
                leading: const Icon(Icons.error),
              ),
            ),
            
            const Divider(height: 32),
            
            // Time Setting
            reminderTime.when(
              data: (time) => ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Reminder Time'),
                subtitle: Text('Currently set to ${_formatTime(time['hour']!, time['minute']!)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showTimePicker(time['hour']!, time['minute']!),
              ),
              loading: () => const ListTile(
                leading: Icon(Icons.access_time),
                title: Text('Reminder Time'),
                subtitle: Text('Loading...'),
              ),
              error: (error, stack) => ListTile(
                leading: const Icon(Icons.error),
                title: const Text('Reminder Time'),
                subtitle: Text('Error loading time'),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Toggle notification enable/disable
  Future<void> _toggleNotifications(bool enabled) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await NotificationService.setDailyReminderEnabled(enabled);
      
      if (!success && enabled) {
        if (mounted) {
          // Show more detailed error with action
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Failed to enable notifications'),
                  const SizedBox(height: 4),
                  const Text('Please check your permission settings.'),
                ],
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await NotificationService.openPermissionSettings();
                },
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } else {
        // Refresh the providers
        ref.invalidate(notificationEnabledProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                enabled 
                  ? '✅ Daily reminders enabled!'
                  : '⏸️ Daily reminders disabled'
              ),
              backgroundColor: enabled ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show time picker for setting reminder time
  Future<void> _showTimePicker(int currentHour, int currentMinute) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      helpText: 'Select reminder time',
    );

    if (picked != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await NotificationService.setDailyReminderTime(picked.hour, picked.minute);
        
        // Refresh the providers
        ref.invalidate(reminderTimeProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⏰ Reminder time updated to ${_formatTime(picked.hour, picked.minute)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update time: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Format time for display
  String _formatTime(int hour, int minute) {
    final TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time);
  }
}