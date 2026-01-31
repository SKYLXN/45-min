import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/active_workout_provider.dart';
import '../widgets/exercise_header.dart';
import '../widgets/set_tracker.dart';
import '../widgets/previous_performance_card.dart';
import '../widgets/rest_timer_overlay.dart';
import '../widgets/set_input_dialog.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../smart_planner/presentation/widgets/exercise_swap_dialog.dart';
import '../../../exercise_database/data/models/exercise.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(activeWorkoutProvider);
    final workoutNotifier = ref.read(activeWorkoutProvider.notifier);

    print('📱 ActiveWorkoutScreen build:');
    print('  isActive: ${workoutState.isActive}');
    print('  plannedWorkout: ${workoutState.plannedWorkout?.name}');
    print('  exercises count: ${workoutState.plannedWorkout?.exercises.length ?? 0}');
    print('  currentExerciseIndex: ${workoutState.currentExerciseIndex}');
    print('  currentPlannedExercise: ${workoutState.currentPlannedExercise?.exercise.name}');
    print('  currentExercise: ${workoutState.currentExercise?.name}');

    if (!workoutState.isActive) {
      // Redirect if no active workout
      print('  ⚠️  No active workout, redirecting to home');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show rest timer overlay if resting
    if (workoutState.isResting) {
      return RestTimerOverlay(
        onSkip: () => workoutNotifier.endRest(),
        onAddTime: (seconds) => workoutNotifier.addRestTime(seconds),
      );
    }

    final currentExercise = workoutState.currentExercise;
    final currentPlanned = workoutState.currentPlannedExercise;

    print('  currentExercise null? ${currentExercise == null}');
    print('  currentPlanned null? ${currentPlanned == null}');

    if (currentExercise == null || currentPlanned == null) {
      // Workout complete or error
      print('  ⚠️  No current exercise, showing completion screen');
      return _buildWorkoutComplete(context, workoutState);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.pause, color: AppColors.textPrimary),
          onPressed: () => _showPauseDialog(context, workoutNotifier),
        ),
        title: Text(
          workoutState.plannedWorkout?.name ?? 'Active Workout',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.error),
            onPressed: () => _showCancelDialog(context, workoutNotifier),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(workoutState),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise header
                    ExerciseHeader(
                      exercise: currentExercise,
                      onViewDemo: () => _viewExerciseDemo(context, currentExercise.id),
                      onReplace: () => _showReplaceExerciseDialog(context),
                    ),

                    const SizedBox(height: 20),

                    // Set tracker
                    SetTracker(
                      currentSet: workoutState.currentSetNumber,
                      totalSets: workoutState.totalSetsForCurrentExercise,
                      completedSets: workoutState.currentExerciseSets,
                    ),

                    const SizedBox(height: 24),

                    // Previous performance
                    PreviousPerformanceCard(
                      previousWeight: currentPlanned.previousWeight,
                      previousRPE: currentPlanned.previousRPE,
                      targetReps: currentPlanned.reps,
                    ),

                    const SizedBox(height: 24),

                    // Current set info
                    _buildCurrentSetInfo(currentPlanned),

                    const SizedBox(height: 32),

                    // Complete set button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _showSetInputDialog(context, currentPlanned),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Complete Set ${workoutState.currentSetNumber}',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.backgroundDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Skip exercise button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _showSkipExerciseDialog(context, workoutNotifier),
                        child: Text(
                          'Skip Exercise',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFinishWorkoutDialog(context, workoutNotifier),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.check, color: AppColors.backgroundDark),
        label: Text(
          'Finish Workout',
          style: AppTextStyles.button.copyWith(color: AppColors.backgroundDark),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ActiveWorkoutState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise ${state.currentExerciseIndex + 1}/${state.totalExercises}',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                '${state.progress.toStringAsFixed(0)}%',
                style: AppTextStyles.body.copyWith(color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress / 100,
              backgroundColor: AppColors.cardBackground,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSetInfo(dynamic plannedExercise) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Target Reps', '${plannedExercise.reps}'),
              _buildStatColumn('Target Weight', '${plannedExercise.weight} kg'),
              _buildStatColumn('Target RPE', '${plannedExercise.targetRPE.toStringAsFixed(1)}'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rest: ${plannedExercise.restTime ~/ 60}:${(plannedExercise.restTime % 60).toString().padLeft(2, '0')}',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(color: AppColors.primaryGreen),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildWorkoutComplete(BuildContext context, ActiveWorkoutState state) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration,
                size: 80,
                color: AppColors.primaryGold,
              ),
              const SizedBox(height: 24),
              Text(
                'Workout Complete!',
                style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Great job! Tap below to save your workout.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _finishWorkout(context, ref.read(activeWorkoutProvider.notifier)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save & Finish',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.backgroundDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetInputDialog(BuildContext context, dynamic plannedExercise) {
    showDialog(
      context: context,
      builder: (context) => SetInputDialog(
        targetReps: plannedExercise.reps,
        targetWeight: plannedExercise.weight,
        targetRPE: plannedExercise.targetRPE,
        onComplete: (reps, weight, rpe, notes) async {
          Navigator.of(context).pop();
          await ref.read(activeWorkoutProvider.notifier).completeSet(
                actualReps: reps,
                actualWeight: weight,
                rpe: rpe,
                notes: notes,
              );
        },
      ),
    );
  }

  void _showPauseDialog(BuildContext context, ActiveWorkoutNotifier notifier) {
    notifier.pauseWorkout();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Workout Paused', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Take a break. Resume when you\'re ready.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifier.resumeFromPause();
              Navigator.of(context).pop();
            },
            child: const Text('Resume', style: TextStyle(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, ActiveWorkoutNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Cancel Workout?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure? All progress will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Training', style: TextStyle(color: AppColors.primaryGreen)),
          ),
          TextButton(
            onPressed: () async {
              await notifier.cancelWorkout();
              if (context.mounted) {
                Navigator.of(context).pop();
                context.go('/');
              }
            },
            child: const Text('Cancel Workout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showSkipExerciseDialog(BuildContext context, ActiveWorkoutNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Skip Exercise?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Skip to the next exercise without completing this one?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              notifier.skipExercise();
              Navigator.of(context).pop();
            },
            child: const Text('Skip', style: TextStyle(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }

  void _showFinishWorkoutDialog(BuildContext context, ActiveWorkoutNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Finish Workout?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Complete your workout and save all progress?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _finishWorkout(context, notifier);
            },
            child: const Text('Finish', style: TextStyle(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showReplaceExerciseDialog(BuildContext context) async {
    final workoutState = ref.read(activeWorkoutProvider);
    final workoutNotifier = ref.read(activeWorkoutProvider.notifier);
    
    final currentPlanned = workoutState.currentPlannedExercise;
    final currentExercise = workoutState.currentExercise;
    
    if (currentPlanned == null || currentExercise == null) {
      return;
    }

    final result = await showDialog<Exercise>(
      context: context,
      builder: (context) => ExerciseSwapDialog(
        currentExercise: currentPlanned,
        muscleGroup: currentExercise.muscleGroup,
        onSwap: (newExercise) {
          Navigator.of(context).pop(newExercise);
        },
      ),
    );

    if (result != null && context.mounted) {
      // Replace the exercise in the active workout
      await workoutNotifier.replaceExercise(result);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${result.name}'),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _viewExerciseDemo(BuildContext context, String exerciseId) {
    context.push('/exercise-detail/$exerciseId');
  }

  Future<void> _finishWorkout(BuildContext context, ActiveWorkoutNotifier notifier) async {
    await notifier.finishWorkout();
    if (context.mounted) {
      context.go('/workout-summary');
    }
  }
}
