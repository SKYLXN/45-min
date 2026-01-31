import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import '../../../../core/constants/app_colors.dart';
import '../../data/services/health_service.dart';
import '../../providers/health_sync_provider.dart';

/// Widget shown when HealthKit permissions are denied or unavailable
class PermissionDeniedCard extends ConsumerWidget {
  const PermissionDeniedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(healthSyncProvider);
    
    // Don't show if permissions are granted
    if (syncState.permissionGranted) {
      return const SizedBox.shrink();
    }
    
    // Check if on Android (HealthKit not available)
    final isAndroid = Platform.isAndroid;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isAndroid ? Icons.phone_android : Icons.lock_outline,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAndroid 
                      ? 'Apple Health Not Available'
                      : 'Health Access Required',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Message
          Text(
            isAndroid
                ? 'Apple Health is only available on iOS devices. Use manual entry to track your body metrics.'
                : 'To automatically sync your body metrics from smart scales and track recovery data, please grant access to Apple Health.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          if (!isAndroid) ...[
            // Request permissions button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: syncState.isCheckingPermission 
                    ? null 
                    : () async {
                        final granted = await ref
                            .read(healthSyncProvider.notifier)
                            .requestPermissions();
                        
                        if (context.mounted) {
                          if (granted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Health permissions granted!'),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Health permissions denied'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                icon: syncState.isCheckingPermission
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.backgroundDark,
                        ),
                      )
                    : const Icon(Icons.health_and_safety),
                label: const Text(
                  'Grant Health Access',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // iOS Settings link
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Open iOS Settings app (requires url_launcher package)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Open Settings → Privacy & Security → Health → 45min',
                    ),
                    duration: Duration(seconds: 4),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text(
                'Open iOS Settings',
                style: TextStyle(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
          ],
          
          // Manual entry option (always available)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/manual-entry');
              },
              icon: const Icon(Icons.edit_note),
              label: Text(
                isAndroid 
                    ? 'Enter Metrics Manually' 
                    : 'Or Enter Manually',
                style: const TextStyle(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
