import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

/// Shows sync status with last sync time and refresh action
class SyncStatusIndicator extends StatelessWidget {
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final VoidCallback onRefresh;
  final String? error;
  
  const SyncStatusIndicator({
    super.key,
    this.lastSyncTime,
    this.isSyncing = false,
    required this.onRefresh,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: error != null
            ? AppColors.error.withOpacity(0.1)
            : AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error != null
              ? AppColors.error.withOpacity(0.3)
              : AppColors.borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (isSyncing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            )
          else
            Icon(
              error != null ? Icons.error_outline : Icons.sync,
              size: 16,
              color: error != null ? AppColors.error : AppColors.primaryGreen,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusText(),
              style: TextStyle(
                color: error != null ? AppColors.error : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          if (!isSyncing)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              iconSize: 20,
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
  
  String _getStatusText() {
    if (error != null) {
      return 'Sync failed: $error';
    }
    
    if (isSyncing) {
      return 'Syncing with Apple Health...';
    }
    
    if (lastSyncTime == null) {
      return 'Not synced yet';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);
    
    if (difference.inMinutes < 1) {
      return 'Synced just now';
    } else if (difference.inMinutes < 60) {
      return 'Synced ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return 'Synced ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Last synced ${DateFormat('MMM d, h:mm a').format(lastSyncTime!)}';
    }
  }
}
