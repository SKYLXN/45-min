import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/weekly_program.dart';

class WorkoutCard extends StatelessWidget {
  final PlannedWorkout workout;
  final String dayLabel;
  final VoidCallback onTap;
  final VoidCallback onStartWorkout;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.dayLabel,
    required this.onTap,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = workout.completedAt != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppColors.primaryGreen.withOpacity(0.5)
                : AppColors.textSecondary.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with completion status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primaryGreen.withOpacity(0.2)
                            : AppColors.primaryGradient.colors[0]
                                .withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.fitness_center,
                        color: isCompleted
                            ? AppColors.primaryGreen
                            : AppColors.primaryGradient.colors[0],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayLabel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Workout ${workout.workoutType}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Exercise list preview
            _buildExercisePreview(),
            const SizedBox(height: 16),

            // Workout stats
            Row(
              children: [
                _buildStatItem(
                  Icons.timer_outlined,
                  '${workout.estimatedDuration} min',
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.list_alt,
                  '${workout.exercises.length} exercises',
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.fitness_center,
                  _getTotalSets().toString() + ' sets',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCompleted ? onTap : onStartWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? AppColors.textSecondary.withOpacity(0.2)
                      : AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isCompleted ? 'View Details' : 'Start Workout',
                  style: TextStyle(
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.backgroundDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisePreview() {
    final previewCount = workout.exercises.length > 3 ? 3 : workout.exercises.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...workout.exercises.take(previewCount).map((exercise) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.exercise.name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${exercise.sets}×${exercise.reps}',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (workout.exercises.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              '+${workout.exercises.length - 3} more',
              style: TextStyle(
                color: AppColors.primaryGreen.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  int _getTotalSets() {
    return workout.exercises.fold(0, (sum, exercise) => sum + exercise.sets);
  }
}
