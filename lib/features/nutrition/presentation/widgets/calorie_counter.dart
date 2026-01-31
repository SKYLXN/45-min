import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';

/// Calorie Counter Widget - Daily calorie tracker with progress bar
class CalorieCounter extends StatelessWidget {
  final int targetCalories;
  final int consumedCalories;
  final bool isWorkoutDay;

  const CalorieCounter({
    super.key,
    required this.targetCalories,
    required this.consumedCalories,
    this.isWorkoutDay = false,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = targetCalories - consumedCalories;
    final progress = targetCalories > 0
        ? (consumedCalories / targetCalories).clamp(0.0, 1.0)
        : 0.0;
    final isOverTarget = consumedCalories > targetCalories;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverTarget
              ? AppColors.error.withOpacity(0.3)
              : AppColors.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Calories',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isWorkoutDay)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: AppColors.primaryGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Workout Day',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Main calorie display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                consumedCalories.toString(),
                style: TextStyle(
                  color: isOverTarget ? AppColors.error : AppColors.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Text(
                ' / ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                targetCalories.toString(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kcal',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  // Background
                  Container(
                    color: AppColors.backgroundDark,
                  ),
                  // Progress
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOverTarget
                              ? [AppColors.error, AppColors.error.withOpacity(0.7)]
                              : progress >= 0.9
                                  ? [
                                      AppColors.primaryGold,
                                      AppColors.warning
                                    ]
                                  : [
                                      AppColors.primaryGreen,
                                      AppColors.primaryGreen.withOpacity(0.7)
                                    ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Remaining/Over text
          Text(
            isOverTarget
                ? '${consumedCalories - targetCalories} kcal over target'
                : remaining > 0
                    ? '$remaining kcal remaining'
                    : 'Target reached!',
            style: TextStyle(
              color: isOverTarget
                  ? AppColors.error
                  : remaining == 0
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
