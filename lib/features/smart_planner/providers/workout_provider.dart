import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workout_mode/data/repositories/workout_repository.dart';
import '../../workout_mode/data/models/workout_session.dart';
import '../../workout_mode/data/models/workout_set.dart';
import '../../smart_planner/data/models/weekly_program.dart';

// ============================================================================
// Repository Provider
// ============================================================================

/// Singleton provider for WorkoutRepository
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

// ============================================================================
// Data Providers
// ============================================================================

/// Provider for workout session history
final sessionHistoryProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getSessionHistory(limit: 20);
});

/// Provider for current week program
final currentWeekProgramProvider = FutureProvider<WeeklyProgram?>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getCurrentWeekProgram();
});

/// Provider for sessions by week
final sessionsByWeekProvider = FutureProvider.family<List<WorkoutSession>, int>(
  (ref, weekNumber) async {
    final repository = ref.watch(workoutRepositoryProvider);
    return await repository.getSessionsByWeek(weekNumber: weekNumber);
  },
);

/// Provider for last exercise performance
final lastExercisePerformanceProvider = FutureProvider.family<List<WorkoutSet>?, String>(
  (ref, exerciseId) async {
    final repository = ref.watch(workoutRepositoryProvider);
    return await repository.getLastExercisePerformance(exerciseId);
  },
);

/// Provider for week completion count
final weekCompletionCountProvider = FutureProvider.family<int, int>(
  (ref, weekNumber) async {
    final repository = ref.watch(workoutRepositoryProvider);
    return await repository.getWeekCompletionCount(weekNumber: weekNumber);
  },
);

// ============================================================================
// Active Workout State Notifier
// ============================================================================

/// State for active workout session
class ActiveWorkoutState {
  final WorkoutSession? session;
  final int currentExerciseIndex;
  final int currentSetNumber;
  final bool isResting;
  final int restTimeRemaining;
  final List<WorkoutSet> completedSets;
  final DateTime? startTime;
  final bool isActive;
  final String? error;

  const ActiveWorkoutState({
    this.session,
    this.currentExerciseIndex = 0,
    this.currentSetNumber = 1,
    this.isResting = false,
    this.restTimeRemaining = 0,
    this.completedSets = const [],
    this.startTime,
    this.isActive = false,
    this.error,
  });

  ActiveWorkoutState copyWith({
    WorkoutSession? session,
    int? currentExerciseIndex,
    int? currentSetNumber,
    bool? isResting,
    int? restTimeRemaining,
    List<WorkoutSet>? completedSets,
    DateTime? startTime,
    bool? isActive,
    String? error,
  }) {
    return ActiveWorkoutState(
      session: session ?? this.session,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetNumber: currentSetNumber ?? this.currentSetNumber,
      isResting: isResting ?? this.isResting,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      completedSets: completedSets ?? this.completedSets,
      startTime: startTime ?? this.startTime,
      isActive: isActive ?? this.isActive,
      error: error,
    );
  }

  /// Get current exercise from planned workout
  PlannedExercise? get currentExercise {
    if (session == null) return null;
    // This would need to reference the planned workout structure
    return null; // Placeholder
  }

  /// Calculate workout progress percentage
  double get progressPercent {
    if (session == null) return 0.0;
    final totalSets = session!.sets.length;
    if (totalSets == 0) return 0.0;
    return (completedSets.length / totalSets) * 100;
  }
}

/// Notifier for managing active workout state
class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final WorkoutRepository _repository;

  ActiveWorkoutNotifier(this._repository) : super(const ActiveWorkoutState());

  /// Start a workout session
  void startWorkout(WorkoutSession session) {
    state = ActiveWorkoutState(
      session: session,
      startTime: DateTime.now(),
      isActive: true,
    );
  }

  /// Complete a set
  void completeSet(WorkoutSet set) {
    final updatedSets = [...state.completedSets, set];
    state = state.copyWith(
      completedSets: updatedSets,
      isResting: true,
      restTimeRemaining: set.restTimeSec,
    );
  }

  /// Skip exercise
  void skipExercise() {
    state = state.copyWith(
      currentExerciseIndex: state.currentExerciseIndex + 1,
      currentSetNumber: 1,
      isResting: false,
    );
  }

  /// Update rest timer
  void updateRestTime(int seconds) {
    state = state.copyWith(restTimeRemaining: seconds);
    if (seconds <= 0) {
      state = state.copyWith(isResting: false);
    }
  }

  /// Finish workout
  Future<void> finishWorkout() async {
    if (state.session == null) return;

    try {
      final completedSession = state.session!.copyWith(
        sets: state.completedSets,
        endTime: DateTime.now(),
        startTime: state.startTime,
        completed: true,
        totalVolumeKg: state.completedSets.fold<double>(0.0, (sum, set) => sum + set.volume),
        rpeAverage: state.completedSets.isEmpty
            ? null
            : state.completedSets.fold<double>(0.0, (sum, set) => sum + set.rpe.toDouble()) /
                state.completedSets.length,
      );

      await _repository.saveWorkoutSession(completedSession);
      
      state = const ActiveWorkoutState(); // Reset state
    } catch (e) {
      state = state.copyWith(error: 'Failed to save workout: $e');
    }
  }

  /// Cancel/pause workout
  void cancelWorkout() {
    state = const ActiveWorkoutState();
  }
}

/// Provider for active workout state management
final activeWorkoutProvider = StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>(
  (ref) {
    final repository = ref.watch(workoutRepositoryProvider);
    return ActiveWorkoutNotifier(repository);
  },
);

// ============================================================================
// Weekly Program State Notifier
// ============================================================================

/// State for weekly program management
class WeeklyProgramState {
  final WeeklyProgram? currentProgram;
  final List<WeeklyProgram> allPrograms;
  final bool isLoading;
  final String? error;

  const WeeklyProgramState({
    this.currentProgram,
    this.allPrograms = const [],
    this.isLoading = false,
    this.error,
  });

  WeeklyProgramState copyWith({
    WeeklyProgram? currentProgram,
    List<WeeklyProgram>? allPrograms,
    bool? isLoading,
    String? error,
  }) {
    return WeeklyProgramState(
      currentProgram: currentProgram ?? this.currentProgram,
      allPrograms: allPrograms ?? this.allPrograms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing weekly programs
class WeeklyProgramNotifier extends StateNotifier<WeeklyProgramState> {
  final WorkoutRepository _repository;

  WeeklyProgramNotifier(this._repository) : super(const WeeklyProgramState());

  /// Load current program
  Future<void> loadCurrentProgram() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final program = await _repository.getCurrentWeekProgram();
      state = state.copyWith(
        currentProgram: program,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load program: $e',
      );
    }
  }

  /// Load all programs
  Future<void> loadAllPrograms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final programs = await _repository.getAllPrograms();
      state = state.copyWith(
        allPrograms: programs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load programs: $e',
      );
    }
  }

  /// Save new program
  Future<void> saveProgram(WeeklyProgram program) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.saveWeeklyProgram(program);
      await loadCurrentProgram();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save program: $e',
      );
    }
  }

  /// Set active program
  Future<void> setActiveProgram(String programId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.setActiveProgram(programId);
      await loadCurrentProgram();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to activate program: $e',
      );
    }
  }
}

/// Provider for weekly program state management
final weeklyProgramProvider = StateNotifierProvider<WeeklyProgramNotifier, WeeklyProgramState>(
  (ref) {
    final repository = ref.watch(workoutRepositoryProvider);
    return WeeklyProgramNotifier(repository);
  },
);
