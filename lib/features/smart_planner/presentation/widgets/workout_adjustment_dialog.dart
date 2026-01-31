import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../smart_planner/data/models/planned_workout.dart';

/// Dialog shown before starting a workout when recovery score is low
/// Allows user to accept automatic intensity adjustments or proceed normally
class WorkoutAdjustmentDialog extends ConsumerWidget {
  final int recoveryScore;
  final PlannedWorkout originalWorkout;
  final VoidCallback onAcceptAdjustment;
  final VoidCallback onProceedNormal;
  final VoidCallback onRest;

  const WorkoutAdjustmentDialog({
    super.key,
    required this.recoveryScore,
    required this.originalWorkout,
    required this.onAcceptAdjustment,
    required this.onProceedNormal,
    required this.onRest,
  });

  String _getAdjustmentDescription() {
    if (recoveryScore < 40) {
      return 'Your recovery is critically low. We recommend reducing all weights by 30% and cutting sets by 1-2. Consider taking a rest day instead.';
    } else if (recoveryScore < 50) {
      return 'Your recovery is poor. We recommend reducing all weights by 20% and cutting 1 set from each exercise.';
    } else if (recoveryScore < 70) {
      return 'Your recovery is moderate. We recommend reducing all weights by 10% to avoid overtraining.';
    } else {
      return 'Your recovery is good! You\'re cleared for full intensity training.';
    }
  }

  Color _getWarningColor() {
    if (recoveryScore < 40) return Colors.red;
    if (recoveryScore < 50) return Colors.orange;
    if (recoveryScore < 70) return AppColors.primaryGold;
    return AppColors.primaryGreen;
  }

  IconData _getWarningIcon() {
    if (recoveryScore < 40) return Icons.warning;
    if (recoveryScore < 50) return Icons.info_outline;
    if (recoveryScore < 70) return Icons.lightbulb_outline;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warningColor = _getWarningColor();
    final showRestOption = recoveryScore < 50;

    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: warningColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Icon(
              _getWarningIcon(),
              color: warningColor,
              size: 56,
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              recoveryScore < 70 ? 'Low Recovery Detected' : 'Ready to Train!',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Recovery score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Recovery Score: $recoveryScore/100',
                style: TextStyle(
                  color: warningColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getAdjustmentDescription(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            if (recoveryScore < 70) ...[
              // Accept adjustment (recommended)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAcceptAdjustment();
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Accept Adjustment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warningColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Proceed with normal workout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onProceedNormal();
                  },
                  icon: const Icon(Icons.fitness_center),
                  label: const Text(
                    'Proceed with Normal Workout',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              if (showRestOption) ...[
                const SizedBox(height: 12),
                
                // Rest day option
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRest();
                    },
                    icon: const Icon(Icons.bed),
                    label: const Text(
                      'Take a Rest Day',
                      style: TextStyle(fontSize: 14),
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
            ] else ...[
              // Good recovery - start workout
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onProceedNormal();
                  },
                  icon: const Icon(Icons.fitness_center),
                  label: const Text(
                    'Start Workout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.backgroundDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the workout adjustment dialog
Future<void> showWorkoutAdjustmentDialog({
  required BuildContext context,
  required int recoveryScore,
  required PlannedWorkout originalWorkout,
  required VoidCallback onAcceptAdjustment,
  required VoidCallback onProceedNormal,
  required VoidCallback onRest,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // Force user to make a choice
    builder: (context) => WorkoutAdjustmentDialog(
      recoveryScore: recoveryScore,
      originalWorkout: originalWorkout,
      onAcceptAdjustment: onAcceptAdjustment,
      onProceedNormal: onProceedNormal,
      onRest: onRest,
    ),
  );
}
