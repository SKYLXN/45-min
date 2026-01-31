import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Card widget displaying HealthKit permission status
/// Shows current authorization state and allows re-authorization
class HealthPermissionCard extends StatelessWidget {
  final bool isGranted;
  final VoidCallback onRequestPermission;
  final bool isLoading;
  
  const HealthPermissionCard({
    super.key,
    required this.isGranted,
    required this.onRequestPermission,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? AppColors.primaryGreen : AppColors.error,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGranted ? Icons.check_circle : Icons.warning_rounded,
                color: isGranted ? AppColors.primaryGreen : AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isGranted ? 'Apple Health Connected' : 'Apple Health Not Connected',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isGranted
                ? 'Automatically syncing body metrics, sleep, and HRV data from Apple Health.'
                : 'Connect to Apple Health to automatically sync your body metrics, sleep quality, and recovery data.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onRequestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.backgroundDark,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.backgroundDark,
                          ),
                        ),
                      )
                    : const Icon(Icons.favorite),
                label: Text(
                  isLoading ? 'Connecting...' : 'Connect Apple Health',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
