import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/weekly_program.dart';
import '../../../workout_mode/data/repositories/workout_repository.dart' as workout_repo;
import '../../../workout_mode/providers/active_workout_provider.dart';
import '../../providers/smart_planner_provider.dart';
import '../widgets/exercise_swap_dialog.dart';
import '../widgets/recovery_check_dialog.dart';
import '../widgets/workout_conflict_dialog.dart';
import '../../../body_analytics/data/services/health_service.dart';
import '../../../body_analytics/providers/health_sync_provider.dart';

class WorkoutPreviewScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutPreviewScreen({
    super.key,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(_workoutProvider(workoutId));

    return workoutAsync.when(
      data: (workout) => _buildScaffold(context, ref, workout),
      loading: () => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.errorRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading workout',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    PlannedWorkout workout,
  ) {
    final isCompleted = workout.completedAt != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: _buildContent(context, ref, workout),
      floatingActionButton: isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _startWorkout(context, ref, workout),
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.backgroundDark,
              ),
              label: const Text(
                'Start Workout',
                style: TextStyle(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
    );
  }

  void _startWorkout(
    BuildContext context,
    WidgetRef ref,
    PlannedWorkout workout,
  ) async {
    print('🏋️ _startWorkout called for: ${workout.name}');
    
    // Check for workout conflicts (cardio on leg day)
    final hasCardio = await _checkWorkoutConflict(context, ref, workout);
    if (hasCardio == 'skip' || !context.mounted) {
      return; // User chose to skip workout
    }
    
    // Show recovery check dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RecoveryCheckDialog(
        onProceed: () async {
          print('✅ Recovery dialog: User clicked Proceed');
          
          try {
            print('🏋️ Starting workout...');
            // Start the workout
            await ref.read(activeWorkoutProvider.notifier).startWorkout(workout);
            
            print('🏋️ Workout started, navigating to /active-workout');
            // Navigate to active workout screen
            if (context.mounted) {
              context.go('/active-workout');
            }
          } catch (e) {
            print('❌ Error starting workout: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error starting workout: $e'),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          }
        },
        onRest: () {
          print('⏸️  Recovery dialog: User clicked Rest');
          // User chose to rest
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Good choice! Recovery is important 💪'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
            context.go('/');
          }
        },
      ),
    );
  }

  /// Check for workout conflicts (e.g., cardio on leg day)
  Future<String?> _checkWorkoutConflict(
    BuildContext context,
    WidgetRef ref,
    PlannedWorkout workout,
  ) async {
    try {
      // Check if user did significant cardio today
      final healthService = ref.read(healthServiceProvider);
      final hasCardio = await healthService.hasSignificantCardioToday();
      
      if (!hasCardio || !context.mounted) {
        return null; // No conflict
      }

      // Check if it's a leg day
      final isLegDay = workout.name.toLowerCase().contains('leg') ||
          workout.exercises.any((e) => 
            e.exercise.muscleGroup.toLowerCase() == 'legs' ||
            e.exercise.muscleGroup.toLowerCase() == 'lower body'
          );

      // Show conflict dialog
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => WorkoutConflictDialog(
          conflictingActivity: 'Running', // Could be fetched from HealthKit
          conflictingDistance: '>5km',
          scheduledWorkout: workout.name,
          isLegDay: isLegDay,
        ),
      );

      return result;
    } catch (e) {
      print('Error checking workout conflict: $e');
      return null; // Continue on error
    }
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PlannedWorkout workout,
  ) {
    final isCompleted = workout.completedAt != null;

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          backgroundColor: AppColors.backgroundDark,
          expandedHeight: 200,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.go('/smart-planner'),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.backgroundDark,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'COMPLETED',
                                style: TextStyle(
                                  color: AppColors.backgroundDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Workout ${workout.workoutType}',
                        style: const TextStyle(
                          color: AppColors.backgroundDark,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatChip(
                            Icons.timer_outlined,
                            '${workout.estimatedDuration} min',
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            Icons.list_alt,
                            '${workout.exercises.length} exercises',
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            Icons.fitness_center,
                            '${_getTotalSets(workout)} sets',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Exercise list
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exercise = workout.exercises[index];
                return _buildExerciseTile(context, ref, workout, exercise, index);
              },
              childCount: workout.exercises.length,
            ),
          ),
        ),

        // Bottom spacing for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.backgroundDark,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.backgroundDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(
    BuildContext context,
    WidgetRef ref,
    PlannedWorkout workout,
    PlannedExercise exercise,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exercise.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.exercise.muscleGroup} • ${exercise.exercise.equipmentRequired.join(", ")}',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.swap_horiz,
                  color: AppColors.primaryGreen,
                ),
                onPressed: () => _showExerciseSwapDialog(
                  context,
                  ref,
                  workout,
                  exercise,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sets/Reps/Weight
          Row(
            children: [
              _buildWorkloadChip('${exercise.sets} sets', Icons.repeat),
              const SizedBox(width: 8),
              _buildWorkloadChip('${exercise.reps} reps', Icons.fitness_center),
              const SizedBox(width: 8),
              _buildWorkloadChip(
                '${exercise.weight.toStringAsFixed(1)} kg',
                Icons.monitor_weight_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rest time and RPE
          Row(
            children: [
              Icon(
                Icons.timer,
                color: AppColors.textSecondary.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Rest: ${exercise.restTime}s',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.trending_up,
                color: AppColors.textSecondary.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Target RPE: ${exercise.targetRPE.toStringAsFixed(1)}',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Previous performance (if exists)
          if (exercise.previousWeight != null && exercise.previousWeight! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColors.primaryGold,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last week: ${exercise.previousWeight!.toStringAsFixed(1)}kg @ RPE ${exercise.previousRPE?.toStringAsFixed(1) ?? "N/A"}',
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkloadChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseSwapDialog(
    BuildContext context,
    WidgetRef ref,
    PlannedWorkout workout,
    PlannedExercise exercise,
  ) {
    showDialog(
      context: context,
      builder: (context) => ExerciseSwapDialog(
        currentExercise: exercise,
        muscleGroup: exercise.exercise.muscleGroup,
        onSwap: (newExercise) async {
          final exerciseIndex = workout.exercises.indexOf(exercise);
          await ref.read(smartPlannerProvider.notifier).replaceExerciseInWorkout(
                workout.id,
                exerciseIndex,
                newExercise,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Replaced with ${newExercise.name}'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
        },
      ),
    );
  }

  int _getTotalSets(PlannedWorkout workout) {
    return workout.exercises.fold(0, (sum, exercise) => sum + exercise.sets);
  }
}

// Provider to fetch workout by ID
final _workoutProvider =
    FutureProvider.family<PlannedWorkout, String>((ref, workoutId) async {
  // Import from workout_mode to avoid conflict
  final repository = ref.watch(
    workout_repo.workoutRepositoryProvider,
  );
  final workout = await repository.getWorkout(workoutId);
  if (workout == null) {
    throw Exception('Workout not found');
  }
  return workout;
});
