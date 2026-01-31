import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/workout_session.dart';
import '../data/models/workout_set.dart';
import '../data/repositories/workout_repository.dart' as workout_repo;
import '../../smart_planner/data/models/weekly_program.dart';
import '../../smart_planner/providers/smart_planner_provider.dart';
import '../../exercise_database/data/models/exercise.dart';
import '../../body_analytics/data/services/health_service.dart';
import '../../body_analytics/providers/health_sync_provider.dart';
import '../../nutrition/providers/nutrition_target_provider.dart';
import '../../../core/providers/timer_provider.dart';
import '../../../core/services/rest_timer_service.dart';
import '../../../core/constants/app_constants.dart';

/// State for active workout session
class ActiveWorkoutState {
  final WorkoutSession? session;
  final PlannedWorkout? plannedWorkout;
  final int currentExerciseIndex;
  final int currentSetNumber;
  final bool isResting;
  final int restTimeRemaining;
  final List<WorkoutSet> completedSets;
  final DateTime? startTime;
  final bool isLoading;
  final String? error;
  final bool isPaused;
  final Map<String, dynamic>? setInProgress; // Temporary storage for current set input
  final bool shouldShowPostWorkoutPrompt; // Flag to show nutrition prompt after workout

  const ActiveWorkoutState({
    this.session,
    this.plannedWorkout,
    this.currentExerciseIndex = 0,
    this.currentSetNumber = 1,
    this.isResting = false,
    this.restTimeRemaining = 0,
    this.completedSets = const [],
    this.startTime,
    this.isLoading = false,
    this.error,
    this.isPaused = false,
    this.setInProgress,
    this.shouldShowPostWorkoutPrompt = false,
  });

  ActiveWorkoutState copyWith({
    WorkoutSession? session,
    PlannedWorkout? plannedWorkout,
    int? currentExerciseIndex,
    int? currentSetNumber,
    bool? isResting,
    int? restTimeRemaining,
    List<WorkoutSet>? completedSets,
    DateTime? startTime,
    bool? isLoading,
    String? error,
    bool? isPaused,
    Map<String, dynamic>? setInProgress,
    bool? shouldShowPostWorkoutPrompt,
  }) {
    return ActiveWorkoutState(
      session: session ?? this.session,
      plannedWorkout: plannedWorkout ?? this.plannedWorkout,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetNumber: currentSetNumber ?? this.currentSetNumber,
      isResting: isResting ?? this.isResting,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      completedSets: completedSets ?? this.completedSets,
      startTime: startTime ?? this.startTime,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPaused: isPaused ?? this.isPaused,
      setInProgress: setInProgress,
      shouldShowPostWorkoutPrompt: shouldShowPostWorkoutPrompt ?? this.shouldShowPostWorkoutPrompt,
    );
  }

  /// Get current planned exercise
  PlannedExercise? get currentPlannedExercise {
    if (plannedWorkout == null ||
        currentExerciseIndex >= plannedWorkout!.exercises.length) {
      return null;
    }
    return plannedWorkout!.exercises[currentExerciseIndex];
  }

  /// Get current exercise
  Exercise? get currentExercise => currentPlannedExercise?.exercise;

  /// Check if workout is active
  bool get isActive => session != null && !session!.completed;

  /// Check if workout is complete
  bool get isComplete {
    if (plannedWorkout == null) return false;
    return currentExerciseIndex >= plannedWorkout!.exercises.length;
  }

  /// Get total exercises count
  int get totalExercises => plannedWorkout?.exercises.length ?? 0;

  /// Get completed sets for current exercise
  List<WorkoutSet> get currentExerciseSets {
    if (currentExercise == null) return [];
    return completedSets
        .where((set) => set.exerciseId == currentExercise!.id)
        .toList();
  }

  /// Get total sets for current exercise
  int get totalSetsForCurrentExercise =>
      currentPlannedExercise?.sets ?? 0;

  /// Get workout progress percentage
  double get progress {
    if (totalExercises == 0) return 0.0;
    final exerciseProgress = currentExerciseIndex / totalExercises;
    final setProgress = currentSetNumber / (totalSetsForCurrentExercise + 1);
    return ((exerciseProgress + (setProgress / totalExercises)) * 100)
        .clamp(0.0, 100.0);
  }

  /// Get workout duration
  Duration? get duration {
    if (startTime == null) return null;
    return DateTime.now().difference(startTime!);
  }

  /// Calculate total volume lifted so far
  double get totalVolume {
    return completedSets.fold(
      0.0,
      (sum, set) => sum + (set.actualWeight * set.actualReps),
    );
  }

  /// Calculate average RPE
  double? get averageRPE {
    if (completedSets.isEmpty) return null;
    final total = completedSets.fold(0.0, (sum, set) => sum + set.rpe);
    return total / completedSets.length;
  }
}

/// StateNotifier for managing active workout
class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final workout_repo.WorkoutRepository _workoutRepository;
  final Ref _ref;
  final _uuid = const Uuid();

  ActiveWorkoutNotifier(this._workoutRepository, this._ref)
      : super(const ActiveWorkoutState());

  /// Start a new workout session
  Future<void> startWorkout(PlannedWorkout plannedWorkout) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🏋️ Starting workout: ${plannedWorkout.name}');
      print('🏋️ Exercises count: ${plannedWorkout.exercises.length}');
      if (plannedWorkout.exercises.isNotEmpty) {
        print('🏋️ First exercise: ${plannedWorkout.exercises.first.exercise.name}');
      }
      
      final session = WorkoutSession(
        id: _uuid.v4(),
        userId: AppConstants.defaultUserId, // TODO: Get from auth provider
        workoutType: plannedWorkout.workoutType,
        weekNumber: 1, // TODO: Get from smart planner provider
        sets: [],
        startTime: DateTime.now(),
        endTime: null,
        totalVolumeKg: 0.0,
        rpeAverage: null,
        notes: null,
        completed: false,
      );

      // Save initial session to database
      await _workoutRepository.saveWorkoutSession(session);

      state = ActiveWorkoutState(
        session: session,
        plannedWorkout: plannedWorkout,
        currentExerciseIndex: 0,
        currentSetNumber: 1,
        isResting: false,
        restTimeRemaining: 0,
        completedSets: [],
        startTime: DateTime.now(),
        isLoading: false,
        error: null,
        isPaused: false,
      );
      
      print('🏋️ Workout started successfully');
      print('🏋️ Current exercise: ${state.currentExercise?.name ?? "NULL"}');
    } catch (e) {
      print('❌ Error starting workout: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start workout: $e',
      );
    }
  }

  /// Resume an existing workout session
  Future<void> resumeWorkout(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = await _workoutRepository.getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // TODO: Load planned workout from weekly program
      // For now, we'll need to reconstruct the state from the session

      state = state.copyWith(
        session: session,
        completedSets: session.sets,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to resume workout: $e',
      );
    }
  }

  /// Complete a set
  Future<void> completeSet({
    required int actualReps,
    required double actualWeight,
    required int rpe,
    String? notes,
  }) async {
    if (state.session == null || state.currentExercise == null) {
      state = state.copyWith(error: 'No active workout');
      return;
    }

    try {
      final plannedExercise = state.currentPlannedExercise!;
      
      final workoutSet = WorkoutSet(
        id: _uuid.v4(),
        sessionId: state.session!.id,
        exerciseId: state.currentExercise!.id,
        exerciseName: state.currentExercise!.name,
        setNumber: state.currentSetNumber,
        targetReps: plannedExercise.reps,
        actualReps: actualReps,
        targetWeight: plannedExercise.weight,
        actualWeight: actualWeight,
        rpe: rpe,
        restTimeSec: plannedExercise.restTime,
        timestamp: DateTime.now(),
        notes: notes,
      );

      // Save set to database
      await _workoutRepository.saveWorkoutSet(workoutSet);

      // Update completed sets list
      final updatedSets = [...state.completedSets, workoutSet];

      // Check if this was the last set for current exercise
      final isLastSet = state.currentSetNumber >= plannedExercise.sets;

      if (isLastSet) {
        // Move to next exercise
        state = state.copyWith(
          completedSets: updatedSets,
          currentExerciseIndex: state.currentExerciseIndex + 1,
          currentSetNumber: 1,
          error: null,
        );
      } else {
        // Move to next set and start rest timer
        final restTime = plannedExercise.restTime;
        
        state = state.copyWith(
          completedSets: updatedSets,
          currentSetNumber: state.currentSetNumber + 1,
          isResting: true,
          restTimeRemaining: restTime,
          error: null,
        );

        // Start rest timer
        _ref.read(restTimerProvider.notifier).startTimer(restTime);
      }

      // Auto-save session progress
      await _autoSaveSession();
    } catch (e) {
      state = state.copyWith(error: 'Failed to complete set: $e');
    }
  }

  /// Skip current exercise
  Future<void> skipExercise() async {
    if (state.plannedWorkout == null) return;

    state = state.copyWith(
      currentExerciseIndex: state.currentExerciseIndex + 1,
      currentSetNumber: 1,
      isResting: false,
      error: null,
    );

    await _autoSaveSession();
  }

  /// Replace current exercise
  Future<void> replaceExercise(Exercise newExercise) async {
    if (state.plannedWorkout == null || state.currentPlannedExercise == null) {
      return;
    }

    try {
      final currentPlanned = state.currentPlannedExercise!;
      
      // Create new planned exercise with same sets/reps but different exercise
      final newPlanned = PlannedExercise(
        exercise: newExercise,
        sets: currentPlanned.sets,
        reps: currentPlanned.reps,
        weight: currentPlanned.weight,
        restTime: currentPlanned.restTime,
        targetRPE: currentPlanned.targetRPE,
        previousWeight: currentPlanned.previousWeight,
        previousRPE: currentPlanned.previousRPE,
      );

      // Update planned workout
      final updatedExercises = List<PlannedExercise>.from(
        state.plannedWorkout!.exercises,
      );
      updatedExercises[state.currentExerciseIndex] = newPlanned;

      final updatedWorkout = state.plannedWorkout!.copyWith(
        exercises: updatedExercises,
      );

      state = state.copyWith(
        plannedWorkout: updatedWorkout,
        currentSetNumber: 1, // Reset to first set
        error: null,
      );

      // TODO: Update weekly program in database
    } catch (e) {
      state = state.copyWith(error: 'Failed to replace exercise: $e');
    }
  }

  /// Go back to previous exercise
  void goToPreviousExercise() {
    if (state.currentExerciseIndex > 0) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex - 1,
        currentSetNumber: 1,
        isResting: false,
      );
    }
  }

  /// Go to next exercise
  void goToNextExercise() {
    if (state.currentExerciseIndex < state.totalExercises - 1) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex + 1,
        currentSetNumber: 1,
        isResting: false,
      );
    }
  }

  /// Pause workout
  void pauseWorkout() {
    state = state.copyWith(isPaused: true);
    
    // Pause rest timer if active
    if (state.isResting) {
      _ref.read(restTimerProvider.notifier).pause();
    }
  }

  /// Resume workout
  void resumeFromPause() {
    state = state.copyWith(isPaused: false);
    
    // Resume rest timer if it was active
    if (state.isResting) {
      _ref.read(restTimerProvider.notifier).resume();
    }
  }

  /// End rest period early
  void endRest() {
    state = state.copyWith(
      isResting: false,
      restTimeRemaining: 0,
    );
    
    _ref.read(restTimerProvider.notifier).cancel();
  }

  /// Add time to rest timer
  void addRestTime(int seconds) {
    if (state.isResting) {
      _ref.read(restTimerProvider.notifier).addTime(seconds);
    }
  }

  /// Store temporary set input (before confirming)
  void updateSetInProgress(Map<String, dynamic> setData) {
    state = state.copyWith(setInProgress: setData);
  }

  /// Clear temporary set input
  void clearSetInProgress() {
    state = state.copyWith(setInProgress: null);
  }

  /// Finish workout
  Future<void> finishWorkout({String? notes}) async {
    if (state.session == null) {
      state = state.copyWith(error: 'No active workout');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final endTime = DateTime.now();
      final totalVolume = state.totalVolume;
      final avgRPE = state.averageRPE;

      final updatedSession = state.session!.copyWith(
        endTime: endTime,
        totalVolumeKg: totalVolume,
        rpeAverage: avgRPE,
        notes: notes,
        completed: true,
        sets: state.completedSets,
      );

      // Save final session to database
      await _workoutRepository.saveWorkoutSession(updatedSession);

      // Mark workout as completed in weekly program
      if (state.plannedWorkout != null) {
        await _ref.read(smartPlannerProvider.notifier).markWorkoutCompleted(
          state.plannedWorkout!.id,
        );
      }

      // Write workout to Apple Health
      try {
        final healthService = _ref.read(healthServiceProvider);
        final duration = endTime.difference(state.startTime ?? endTime);
        
        // Estimate calories burned (rough calculation)
        // ~5 kcal per minute of strength training
        final estimatedCalories = (duration.inMinutes * 5).round();
        
        await healthService.writeWorkoutSession(
          workoutName: state.plannedWorkout?.workoutType ?? 'Workout',
          start: state.startTime ?? endTime,
          end: endTime,
          caloriesBurned: estimatedCalories,
        );
      } catch (e) {
        // Log but don't fail if HealthKit write fails
        print('Failed to write workout to HealthKit: $e');
      }

      // Refresh nutrition targets (workout day = higher calorie needs)
      try {
        await _ref.read(nutritionTargetProvider.notifier).refresh();
      } catch (e) {
        // Log but don't fail if nutrition refresh fails
        print('Failed to refresh nutrition targets: $e');
      }

      // Clear state (set flag to show post-workout nutrition prompt)
      state = const ActiveWorkoutState(
        isLoading: false,
        shouldShowPostWorkoutPrompt: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to finish workout: $e',
      );
    }
  }

  /// Cancel workout (without saving)
  Future<void> cancelWorkout() async {
    if (state.session == null) return;

    try {
      // Optionally delete incomplete session from database
      // await _workoutRepository.deleteSession(state.session!.id);

      // Clear state
      state = const ActiveWorkoutState();
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel workout: $e');
    }
  }

  /// Auto-save session progress
  Future<void> _autoSaveSession() async {
    if (state.session == null) return;

    try {
      final updatedSession = state.session!.copyWith(
        sets: state.completedSets,
        totalVolumeKg: state.totalVolume,
        rpeAverage: state.averageRPE,
      );

      await _workoutRepository.saveWorkoutSession(updatedSession);
    } catch (e) {
      // Silent fail for auto-save
      print('Auto-save failed: $e');
    }
  }

  /// Get previous performance for current exercise
  Future<List<WorkoutSet>?> getPreviousPerformance() async {
    if (state.currentExercise == null) return null;

    try {
      return await _workoutRepository.getLastExercisePerformance(
        state.currentExercise!.id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear post-workout nutrition prompt flag
  void clearPostWorkoutPrompt() {
    state = state.copyWith(shouldShowPostWorkoutPrompt: false);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider for active workout state
final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>((ref) {
  final repository = ref.watch(workout_repo.workoutRepositoryProvider);
  return ActiveWorkoutNotifier(repository, ref);
});

/// Provider for checking if workout is active
final isWorkoutActiveProvider = Provider<bool>((ref) {
  final state = ref.watch(activeWorkoutProvider);
  return state.isActive;
});

/// Provider for current exercise
final currentExerciseProvider = Provider<Exercise?>((ref) {
  final state = ref.watch(activeWorkoutProvider);
  return state.currentExercise;
});

/// Provider for workout progress
final workoutProgressProvider = Provider<double>((ref) {
  final state = ref.watch(activeWorkoutProvider);
  return state.progress;
});

/// Provider for previous exercise performance
final previousPerformanceProvider = FutureProvider<List<WorkoutSet>?>((ref) async {
  final notifier = ref.watch(activeWorkoutProvider.notifier);
  return await notifier.getPreviousPerformance();
});
