import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../body_analytics/providers/recovery_provider.dart';

/// Dialog shown before starting a workout to check recovery status
/// and provide workout recommendations based on recovery score
class RecoveryCheckDialog extends ConsumerWidget {
  final VoidCallback onProceed;
  final VoidCallback? onRest;

  const RecoveryCheckDialog({
    super.key,
    required this.onProceed,
    this.onRest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoveryState = ref.watch(recoveryProvider);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: recoveryState.isLoading
          ? _buildLoading()
          : recoveryState.error != null
              ? _buildError(context, recoveryState.error!)
              : _buildContent(context, ref, recoveryState),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    RecoveryState recoveryState,
  ) {
    final recoveryScore = recoveryState.recoveryScore ?? 0;
    final recommendation = recoveryState.recommendation ?? '';
    
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (recoveryScore >= 70) {
      statusColor = AppColors.primaryGreen;
      statusIcon = Icons.check_circle;
      statusText = 'Ready to Train';
    } else if (recoveryScore >= 50) {
      statusColor = AppColors.primaryGold;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Moderate Recovery';
    } else {
      statusColor = AppColors.errorRed;
      statusIcon = Icons.error_outline;
      statusText = 'Low Recovery';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          const Text(
            'Recovery Check',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Recovery score circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: statusColor,
                width: 8,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 40,
                ),
                const SizedBox(height: 4),
                Text(
                  '$recoveryScore',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(
                    color: statusColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status text
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Recommendation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              recommendation,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          if (recoveryScore < 50) ...[
            // Low recovery - show warning buttons
            _buildButton(
              context,
              label: 'Take Rest Day',
              icon: Icons.hotel_rounded,
              color: AppColors.primaryGreen,
              isPrimary: true,
              onPressed: () {
                Navigator.of(context).pop();
                if (onRest != null) {
                  onRest!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 12),
            _buildButton(
              context,
              label: 'Continue with Reduced Intensity',
              icon: Icons.fitness_center,
              color: AppColors.primaryGold,
              isPrimary: false,
              onPressed: () {
                Navigator.of(context).pop();
                onProceed();
              },
            ),
          ] else if (recoveryScore < 70) ...[
            // Moderate recovery - show caution
            _buildButton(
              context,
              label: 'Proceed with Adjustment',
              icon: Icons.fitness_center,
              color: AppColors.primaryGreen,
              isPrimary: true,
              onPressed: () {
                Navigator.of(context).pop();
                onProceed();
              },
            ),
            const SizedBox(height: 12),
            _buildButton(
              context,
              label: 'Take Rest Day',
              icon: Icons.hotel_rounded,
              color: AppColors.textSecondary,
              isPrimary: false,
              onPressed: () {
                Navigator.of(context).pop();
                if (onRest != null) {
                  onRest!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ] else ...[
            // Good recovery - proceed normally
            _buildButton(
              context,
              label: 'Start Workout',
              icon: Icons.play_arrow_rounded,
              color: AppColors.primaryGreen,
              isPrimary: true,
              onPressed: () {
                Navigator.of(context).pop();
                onProceed();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.transparent,
          foregroundColor: isPrimary ? AppColors.backgroundDark : color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: color, width: 2),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
          SizedBox(height: 16),
          Text(
            'Checking recovery...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.errorRed,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to check recovery',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Error: ${error.toString()}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onProceed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue Anyway',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
