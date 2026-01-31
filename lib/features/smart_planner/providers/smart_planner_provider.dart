import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/weekly_program.dart';
import '../../workout_mode/data/repositories/workout_repository.dart';
import '../../exercise_database/data/repositories/exercise_repository.dart';
import '../../exercise_database/data/models/exercise.dart';
import '../../body_analytics/data/repositories/body_analytics_repository.dart';
import '../../body_analytics/providers/recovery_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../data/services/program_generator_service.dart';
import 'equipment_provider.dart';

// ============================================================================
// Smart Planner State
// ============================================================================

class SmartPlannerState {
  final WeeklyProgram? currentProgram;
  final int currentWeek;
  final bool isGenerating;
  final bool isLoading;
  final String? error;
  final DateTime? lastGenerated;

  const SmartPlannerState({
    this.currentProgram,
    this.currentWeek = 1,
    this.isGenerating = false,
    this.isLoading = false,
    this.error,
    this.lastGenerated,
  });

  SmartPlannerState copyWith({
    WeeklyProgram? currentProgram,
    int? currentWeek,
    bool? isGenerating,
    bool? isLoading,
    String? error,
    DateTime? lastGenerated,
  }) {
    return SmartPlannerState(
      currentProgram: currentProgram ?? this.currentProgram,
      currentWeek: currentWeek ?? this.currentWeek,
      isGenerating: isGenerating ?? this.isGenerating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastGenerated: lastGenerated ?? this.lastGenerated,
    );
  }
}

// ============================================================================
// Smart Planner Notifier
// ============================================================================

class SmartPlannerNotifier extends StateNotifier<SmartPlannerState> {
  final ProgramGeneratorService _generatorService;
  final WorkoutRepository _workoutRepository;
  final BodyAnalyticsRepository _bodyAnalyticsRepository;
  final Ref _ref;

  SmartPlannerNotifier(
    this._generatorService,
    this._workoutRepository,
    this._bodyAnalyticsRepository,
    this._ref,
  ) : super(const SmartPlannerState());

  /// Initialize - load current week's program
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Determine current week number
      final weekNumber = await _getCurrentWeekNumber();
      
      // Try to load existing program for this week
      final existingProgram = await _workoutRepository.getProgramByWeek(
        userId: AppConstants.defaultUserId,
        weekNumber: weekNumber,
      );
      
      if (existingProgram != null) {
        state = state.copyWith(
          currentProgram: existingProgram,
          currentWeek: weekNumber,
          isLoading: false,
        );
      } else {
        // No program exists - prompt to generate
        state = state.copyWith(
          currentWeek: weekNumber,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize: $e',
      );
    }
  }

  /// Generate new weekly program
  Future<void> generateProgram({bool forceRegenerate = false}) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      // Get user profile
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        throw Exception('User profile not found. Please complete onboarding.');
      }

      // Get user's equipment
      final equipmentState = _ref.read(equipmentProvider);
      if (equipmentState.userEquipment.isEmpty) {
        throw Exception('No equipment configured. Please set up your equipment.');
      }

      // Get latest body metrics (optional)
      final latestMetrics = await _bodyAnalyticsRepository.getLatestMetrics();

      // Get recovery score (optional)
      final recoveryState = _ref.read(recoveryProvider);
      final recoveryScore = recoveryState.recoveryScore;

      // Determine week number
      int weekNumber = state.currentWeek;
      if (forceRegenerate && state.currentProgram != null) {
        // Keep same week number but regenerate
        weekNumber = state.currentProgram!.weekNumber;
      }

      // Generate program
      final program = await _generatorService.generateWeek(
        weekNumber: weekNumber,
        profile: userProfile,
        equipment: equipmentState.userEquipment.where((e) => e.isAvailable).toList(),
        latestMetrics: latestMetrics,
        recoveryScore: recoveryScore?.round(),
      );

      // Save to database
      await _workoutRepository.saveWeeklyProgram(program);

      state = state.copyWith(
        currentProgram: program,
        currentWeek: weekNumber,
        isGenerating: false,
        lastGenerated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate program: $e',
      );
    }
  }

  /// Generate next week's program
  Future<void> generateNextWeek() async {
    final nextWeek = state.currentWeek + 1;
    state = state.copyWith(currentWeek: nextWeek);
    await generateProgram();
  }

  /// Replace exercise in workout
  Future<void> replaceExerciseInWorkout(
    String workoutId,
    int exerciseIndex,
    Exercise newExercise,
  ) async {
    if (state.currentProgram == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedWorkouts = state.currentProgram!.workouts.map((workout) {
        if (workout.id == workoutId) {
          final updatedExercises = List<PlannedExercise>.from(workout.exercises);
          final oldExercise = updatedExercises[exerciseIndex];
          
          // Keep same parameters but swap exercise
          updatedExercises[exerciseIndex] = PlannedExercise(
            exercise: newExercise,
            sets: oldExercise.sets,
            reps: oldExercise.reps,
            weight: oldExercise.weight,
            restTime: oldExercise.restTime,
            targetRPE: oldExercise.targetRPE,
            previousWeight: oldExercise.previousWeight,
            previousRPE: oldExercise.previousRPE,
          );
          
          return workout.copyWith(exercises: updatedExercises);
        }
        return workout;
      }).toList();

      final updatedProgram = state.currentProgram!.copyWith(
        workouts: updatedWorkouts,
      );

      // Save updated program
      await _workoutRepository.updateProgram(updatedProgram);

      state = state.copyWith(
        currentProgram: updatedProgram,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to replace exercise: $e',
      );
    }
  }

  /// Mark workout as completed
  Future<void> markWorkoutCompleted(String workoutId) async {
    if (state.currentProgram == null) return;

    try {
      final updatedWorkouts = state.currentProgram!.workouts.map((workout) {
        if (workout.id == workoutId) {
          return workout.copyWith(completedAt: DateTime.now());
        }
        return workout;
      }).toList();

      final updatedProgram = state.currentProgram!.copyWith(
        workouts: updatedWorkouts,
      );

      await _workoutRepository.saveWeeklyProgram(updatedProgram);

      state = state.copyWith(currentProgram: updatedProgram);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to mark workout as completed: $e',
      );
    }
  }

  /// Get next scheduled workout
  PlannedWorkout? getNextWorkout() {
    if (state.currentProgram == null) return null;
    
    // Find first incomplete workout
    return state.currentProgram!.workouts.firstWhere(
      (workout) => workout.completedAt == null,
      orElse: () => state.currentProgram!.workouts.first,
    );
  }

  /// Get workout completion percentage
  double getCompletionPercentage() {
    if (state.currentProgram == null) return 0.0;
    
    final total = state.currentProgram!.workouts.length;
    final completed = state.currentProgram!.workouts
        .where((w) => w.completedAt != null)
        .length;
    
    return total > 0 ? (completed / total) * 100 : 0.0;
  }

  /// Determine current week number based on program history
  Future<int> _getCurrentWeekNumber() async {
    try {
      // Get all programs ordered by week number (descending)
      final allPrograms = await _workoutRepository.getAllPrograms();
      
      if (allPrograms.isEmpty) {
        return 1; // First week
      }

      // Get latest program (first in list since ordered DESC)
      final latestProgram = allPrograms.first;
      
      // Check if latest week is completed
      final allCompleted = latestProgram.workouts.every((w) => w.completedAt != null);
      if (allCompleted) {
        return latestProgram.weekNumber + 1; // Move to next week
      }

      return latestProgram.weekNumber; // Continue with current week
    } catch (e) {
      print('Error determining week number: $e');
      return 1;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh current program
  Future<void> refresh() async {
    await initialize();
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Repository providers
final programGeneratorServiceProvider = Provider<ProgramGeneratorService>((ref) {
  return ProgramGeneratorService();
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

/// Smart Planner state provider
final smartPlannerProvider =
    StateNotifierProvider<SmartPlannerNotifier, SmartPlannerState>((ref) {
  final generatorService = ref.watch(programGeneratorServiceProvider);
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  final bodyAnalyticsRepository = ref.watch(bodyAnalyticsRepositoryProvider);
  
  return SmartPlannerNotifier(
    generatorService,
    workoutRepository,
    bodyAnalyticsRepository,
    ref,
  )..initialize();
});

/// Current program provider
final currentProgramProvider = Provider<WeeklyProgram?>((ref) {
  final state = ref.watch(smartPlannerProvider);
  return state.currentProgram;
});

/// Next workout provider
final nextWorkoutProvider = Provider<PlannedWorkout?>((ref) {
  final notifier = ref.watch(smartPlannerProvider.notifier);
  return notifier.getNextWorkout();
});

/// Program completion percentage provider
final programCompletionProvider = Provider<double>((ref) {
  final notifier = ref.watch(smartPlannerProvider.notifier);
  return notifier.getCompletionPercentage();
});

/// Has active program provider
final hasActiveProgramProvider = Provider<bool>((ref) {
  final state = ref.watch(smartPlannerProvider);
  return state.currentProgram != null;
});

/// Current week number provider
final currentWeekNumberProvider = Provider<int>((ref) {
  final state = ref.watch(smartPlannerProvider);
  return state.currentWeek;
});
