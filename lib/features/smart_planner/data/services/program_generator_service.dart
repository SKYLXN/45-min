import '../../../../core/models/body_metrics.dart';
import '../../../body_analytics/data/repositories/body_analytics_repository.dart';
import '../../../exercise_database/data/models/exercise.dart';
import '../../../exercise_database/data/repositories/exercise_repository.dart';
import '../../../workout_mode/data/repositories/workout_repository.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/equipment.dart';
import '../models/weekly_program.dart';
import 'workout_template_service.dart';
import 'package:uuid/uuid.dart';

/// Service for generating adaptive workout programs with progressive overload
class ProgramGeneratorService {
  final ExerciseRepository _exerciseRepository;
  final WorkoutRepository _workoutRepository;
  final WorkoutTemplateService _templateService;

  ProgramGeneratorService({
    ExerciseRepository? exerciseRepository,
    WorkoutRepository? workoutRepository,
    WorkoutTemplateService? templateService,
  })  : _exerciseRepository = exerciseRepository ?? ExerciseRepository(),
        _workoutRepository = workoutRepository ?? WorkoutRepository(),
        _templateService = templateService ?? WorkoutTemplateService();

  /// Generate a complete week of workouts (A/B/A/B split)
  Future<WeeklyProgram> generateWeek({
    required int weekNumber,
    required UserProfile profile,
    required List<Equipment> equipment,
    BodyMetrics? latestMetrics,
    int? recoveryScore,
  }) async {
    try {
      // Get available exercises filtered by equipment
      final availableExercises = await _getAvailableExercises(equipment);

      // Get previous week's data for progressive overload
      WeeklyProgram? previousWeek;
      if (weekNumber > 1) {
        previousWeek = await _workoutRepository.getProgramByWeek(
          weekNumber: weekNumber - 1,
          userId: profile.id,
        );
      }

      // Generate 4 workouts for the week (A/B/A/B)
      final workouts = <PlannedWorkout>[];
      
      // Workout A (Monday) - Chest/Triceps/Shoulders
      workouts.add(await _generateWorkoutA(
        availableExercises,
        previousWeek,
        weekNumber,
        recoveryScore,
      ));

      // Workout B (Wednesday) - Back/Biceps
      workouts.add(await _generateWorkoutB(
        availableExercises,
        previousWeek,
        weekNumber,
        recoveryScore,
      ));

      // Workout A (Friday) - Chest/Triceps/Shoulders
      workouts.add(await _generateWorkoutA(
        availableExercises,
        previousWeek,
        weekNumber,
        recoveryScore,
      ));

      // Workout B (Saturday) - Back/Biceps/Legs
      workouts.add(await _generateWorkoutB(
        availableExercises,
        previousWeek,
        weekNumber,
        recoveryScore,
        includeLegs: true,
      ));

      // Create weekly program
      final program = WeeklyProgram(
        id: const Uuid().v4(),
        userId: profile.id,
        weekNumber: weekNumber,
        workouts: workouts,
        generatedDate: DateTime.now(),
        progressionNotes: _generateProgressionNotes(previousWeek, weekNumber),
        isActive: true,
      );

      print('🎯 Weekly program generated:');
      print('   Week: $weekNumber');
      print('   Workouts: ${program.workouts.length}');
      for (var i = 0; i < program.workouts.length; i++) {
        final w = program.workouts[i];
        print('   ${i + 1}. ${w.name} (${w.exercises.length} exercises)');
      }

      return program;
    } catch (e) {
      print('Error generating week $weekNumber: $e');
      rethrow;
    }
  }

  /// Generate Workout A (Chest/Triceps/Shoulders)
  Future<PlannedWorkout> _generateWorkoutA(
    List<Exercise> availableExercises,
    WeeklyProgram? previousWeek,
    int weekNumber,
    int? recoveryScore,
  ) async {
    final exercises = <PlannedExercise>[];

    // 1. Compound Chest Exercise (4 sets x 8-10 reps)
    final chestCompound = _selectExercise(
      availableExercises,
      muscleGroup: 'Chest',
      isCompound: true,
    );
    if (chestCompound != null) {
      exercises.add(_createPlannedExercise(
        chestCompound,
        sets: 4,
        targetReps: 10,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    // 2. Secondary Chest Exercise (3 sets x 10-12 reps)
    final chestSecondary = _selectExercise(
      availableExercises,
      muscleGroup: 'Chest',
      exclude: [chestCompound?.id],
    );
    if (chestSecondary != null) {
      exercises.add(_createPlannedExercise(
        chestSecondary,
        sets: 3,
        targetReps: 12,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    // 3. Shoulder Compound (3 sets x 8-10 reps)
    final shoulderCompound = _selectExercise(
      availableExercises,
      muscleGroup: 'Shoulders',
      isCompound: true,
    );
    if (shoulderCompound != null) {
      exercises.add(_createPlannedExercise(
        shoulderCompound,
        sets: 3,
        targetReps: 10,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    // 4. Lateral Shoulder (3 sets x 12-15 reps)
    final shoulderLateral = _selectExercise(
      availableExercises,
      muscleGroup: 'Shoulders',
      exclude: [shoulderCompound?.id],
    );
    if (shoulderLateral != null) {
      exercises.add(_createPlannedExercise(
        shoulderLateral,
        sets: 3,
        targetReps: 12,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    // 5. Triceps (3 sets x 10-12 reps)
    final triceps = _selectExercise(
      availableExercises,
      muscleGroup: 'Arms',
      secondaryMuscleContains: 'Triceps',
    );
    if (triceps != null) {
      exercises.add(_createPlannedExercise(
        triceps,
        sets: 3,
        targetReps: 12,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    // 6. Core/Abs (3 sets x 15-20 reps)
    final abs = _selectExercise(
      availableExercises,
      muscleGroup: 'Abs',
    );
    if (abs != null) {
      exercises.add(_createPlannedExercise(
        abs,
        sets: 3,
        targetReps: 20,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    print('💪 Workout A generated with ${exercises.length} exercises');
    
    return PlannedWorkout(
      id: const Uuid().v4(),
      workoutType: 'A',
      name: 'Push (Chest/Shoulders/Triceps)',
      exercises: exercises,
      estimatedDuration: 45,
      requiredEquipment: exercises
          .map((e) => e.exercise.equipmentRequired)
          .expand((e) => e)
          .toSet()
          .toList(),
      completedAt: null,
    );
  }

  /// Generate Workout B (Back/Biceps/Legs optional)
  Future<PlannedWorkout> _generateWorkoutB(
    List<Exercise> availableExercises,
    WeeklyProgram? previousWeek,
    int weekNumber,
    int? recoveryScore, {
    bool includeLegs = false,
  }) async {
    final exercises = <PlannedExercise>[];

    // 1. Compound Back Exercise (4 sets x 8-10 reps)
    final backCompound = _selectExercise(
      availableExercises,
      muscleGroup: 'Back',
      isCompound: true,
    );
    if (backCompound != null) {
      exercises.add(_createPlannedExercise(
        backCompound,
        sets: 4,
        targetReps: 10,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    // 2. Secondary Back Exercise (3 sets x 10-12 reps)
    final backSecondary = _selectExercise(
      availableExercises,
      muscleGroup: 'Back',
      exclude: [backCompound?.id],
    );
    if (backSecondary != null) {
      exercises.add(_createPlannedExercise(
        backSecondary,
        sets: 3,
        targetReps: 12,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    // 3. Biceps (3 sets x 10-12 reps)
    final biceps = _selectExercise(
      availableExercises,
      muscleGroup: 'Arms',
      secondaryMuscleContains: 'Biceps',
    );
    if (biceps != null) {
      exercises.add(_createPlannedExercise(
        biceps,
        sets: 3,
        targetReps: 12,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    // 4. If Saturday workout, add legs
    if (includeLegs) {
      // Leg Compound (3 sets x 10-12 reps)
      final legCompound = _selectExercise(
        availableExercises,
        muscleGroup: 'Legs',
        isCompound: true,
      );
      if (legCompound != null) {
        exercises.add(_createPlannedExercise(
          legCompound,
          sets: 3,
          targetReps: 12,
          previousWeek: previousWeek,
          recoveryScore: recoveryScore,
        ));
      }

      // Leg Secondary (3 sets x 12-15 reps)
      final legSecondary = _selectExercise(
        availableExercises,
        muscleGroup: 'Legs',
        exclude: [legCompound?.id],
      );
      if (legSecondary != null) {
        exercises.add(_createPlannedExercise(
          legSecondary,
          sets: 3,
          targetReps: 15,
          previousWeek: previousWeek,
          recoveryScore: recoveryScore,
        ));
      }
    }

    // 5. Core/Abs (3 sets x 15-20 reps)
    final abs = _selectExercise(
      availableExercises,
      muscleGroup: 'Abs',
    );
    if (abs != null) {
      exercises.add(_createPlannedExercise(
        abs,
        sets: 3,
        targetReps: 20,
        previousWeek: previousWeek,
        recoveryScore: recoveryScore,
      ));
    }

    print('💪 Workout B generated with ${exercises.length} exercises (includeLegs: $includeLegs)');

    return PlannedWorkout(
      id: const Uuid().v4(),
      workoutType: 'B',
      name: includeLegs
          ? 'Pull + Legs (Back/Biceps/Legs)'
          : 'Pull (Back/Biceps)',
      exercises: exercises,
      estimatedDuration: includeLegs ? 60 : 45,
      requiredEquipment: exercises
          .map((e) => e.exercise.equipmentRequired)
          .expand((e) => e)
          .toSet()
          .toList(),
      completedAt: null,
    );
  }

  /// Create planned exercise with progressive overload logic
  PlannedExercise _createPlannedExercise(
    Exercise exercise, {
    required int sets,
    required int targetReps,
    WeeklyProgram? previousWeek,
    int? recoveryScore,
  }) {
    // Base weight calculation (simplified - should be personalized)
    double baseWeight = _calculateBaseWeight(exercise);

    // Apply progressive overload if we have previous week data
    Map<String, dynamic>? previousPerformance;
    if (previousWeek != null) {
      previousPerformance = _findPreviousPerformance(
        exercise.id,
        previousWeek,
      );
      if (previousPerformance != null) {
        baseWeight = _applyProgressiveOverload(
          previousPerformance,
          baseWeight,
        );
      }
    }

    // Apply recovery score adjustments
    if (recoveryScore != null) {
      baseWeight = _applyRecoveryAdjustment(baseWeight, recoveryScore);
    }

    return PlannedExercise(
      exercise: exercise,
      sets: recoveryScore != null && recoveryScore < 50 ? sets - 1 : sets,
      reps: targetReps,
      weight: baseWeight,
      restTime: 90, // seconds
      targetRPE: 8.0, // Default target RPE
      previousWeight: previousPerformance?['weight'] as double?,
      previousRPE: previousPerformance?['rpe'] as double?,
    );
  }

  /// Apply progressive overload based on previous performance
  double _applyProgressiveOverload(
    Map<String, dynamic> previousPerformance,
    double baseWeight,
  ) {
    final avgRPE = previousPerformance['avgRPE'] as double? ?? 8.0;
    final lastWeight = previousPerformance['weight'] as double? ?? baseWeight;

    // Progressive overload rules from roadmap
    if (avgRPE <= 7.0) {
      // Easy - increase weight by 2kg
      return lastWeight + 2.0;
    } else if (avgRPE >= 9.0) {
      // Very hard - reduce weight by 5%
      return lastWeight * 0.95;
    } else {
      // Moderate (7.0-8.5) - keep same weight
      return lastWeight;
    }
  }

  /// Apply recovery score adjustments
  double _applyRecoveryAdjustment(double weight, int recoveryScore) {
    if (recoveryScore < 50) {
      // Poor recovery - reduce by 20%
      return weight * 0.8;
    } else if (recoveryScore >= 50 && recoveryScore < 70) {
      // Moderate recovery - reduce by 10%
      return weight * 0.9;
    }
    // Excellent recovery (>= 70) - no adjustment
    return weight;
  }

  /// Find previous performance for an exercise
  Map<String, dynamic>? _findPreviousPerformance(
    String exerciseId,
    WeeklyProgram previousWeek,
  ) {
    // Search through all workouts in previous week
    for (final workout in previousWeek.workouts) {
      try {
        final exercise = workout.exercises.firstWhere(
          (e) => e.exercise.id == exerciseId,
        );
        // Return performance data
        return {
          'weight': exercise.weight,
          'reps': exercise.reps,
          'rpe': exercise.targetRPE,
        };
      } catch (e) {
        // Exercise not found in this workout, continue
        continue;
      }
    }
    return null;
  }

  /// Calculate base weight for an exercise (simplified)
  double _calculateBaseWeight(Exercise exercise) {
    // This is a simplified calculation
    // In production, this should be based on user's strength level and exercise type
    if (exercise.isBodyweightOnly) {
      return 0.0;
    }

    // Default starting weights by muscle group
    switch (exercise.muscleGroup) {
      case 'Chest':
        return exercise.isCompound ? 20.0 : 15.0;
      case 'Back':
        return exercise.isCompound ? 20.0 : 15.0;
      case 'Shoulders':
        return exercise.isCompound ? 15.0 : 10.0;
      case 'Arms':
        return 10.0;
      case 'Legs':
        return exercise.isCompound ? 25.0 : 20.0;
      default:
        return 10.0;
    }
  }

  /// Get exercises available based on user's equipment
  Future<List<Exercise>> _getAvailableExercises(
    List<Equipment> equipment,
  ) async {
    final allExercises = await _exerciseRepository.getAllExercises();
    print('💪 Total exercises in database: ${allExercises.length}');
    
    // Convert EquipmentType enums to string names for comparison
    final equipmentTypes = equipment.map((e) => e.type.name).toList();
    print('💪 User equipment: $equipmentTypes');
    
    // Create normalized equipment map for flexible matching
    final normalizedEquipment = <String, String>{};
    for (final eq in equipmentTypes) {
      final normalized = eq.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
      normalizedEquipment[normalized] = eq;
    }
    
    // Add common aliases
    normalizedEquipment['adjustablebench'] = 'bench';
    normalizedEquipment['declinebench'] = 'bench';
    normalizedEquipment['inclinebench'] = 'bench';
    normalizedEquipment['pullupbar'] = 'pullupBar';
    normalizedEquipment['chinupbar'] = 'pullupBar';

    final available = allExercises.where((exercise) {
      // Bodyweight exercises are always available
      if (exercise.equipmentRequired.isEmpty || 
          exercise.equipmentRequired.every((req) => 
            req.toLowerCase() == 'bodyweight' || req.toLowerCase() == 'none')) {
        return true;
      }

      // Check if user has all required equipment
      final hasEquipment = exercise.equipmentRequired.every((req) {
        final normalized = req.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
        return normalizedEquipment.containsKey(normalized) ||
               req.toLowerCase() == 'bodyweight' ||
               req.toLowerCase() == 'none';
      });
      
      if (!hasEquipment) {
        print('💪   Excluded ${exercise.name}: needs ${exercise.equipmentRequired}');
      }
      
      return hasEquipment;
    }).toList();
    
    print('💪 Available exercises after equipment filter: ${available.length}');
    if (available.isEmpty && allExercises.isNotEmpty) {
      print('💪 ⚠️  Sample exercise equipment format: ${allExercises.first.equipmentRequired}');
    }
    return available;
  }

  /// Select an exercise based on criteria
  Exercise? _selectExercise(
    List<Exercise> exercises, {
    String? muscleGroup,
    bool? isCompound,
    List<String?>? exclude,
    String? secondaryMuscleContains,
  }) {
    var filtered = exercises;

    if (muscleGroup != null) {
      filtered = filtered.where((e) => e.muscleGroup == muscleGroup).toList();
    }

    if (isCompound != null) {
      filtered = filtered.where((e) => e.isCompound == isCompound).toList();
    }

    if (exclude != null && exclude.isNotEmpty) {
      filtered = filtered.where((e) => !exclude.contains(e.id)).toList();
    }

    if (secondaryMuscleContains != null) {
      filtered = filtered.where((e) {
        return e.secondaryMuscles.any(
          (m) => m.contains(secondaryMuscleContains),
        );
      }).toList();
    }

    if (filtered.isEmpty) {
      // Fallback: try without compound requirement
      if (isCompound != null && muscleGroup != null) {
        return _selectExercise(
          exercises,
          muscleGroup: muscleGroup,
          exclude: exclude,
        );
      }
      return null;
    }

    // Return first match (in production, could randomize or rotate)
    return filtered.first;
  }

  /// Generate progression notes for the week
  String _generateProgressionNotes(
    WeeklyProgram? previousWeek,
    int weekNumber,
  ) {
    if (previousWeek == null || weekNumber == 1) {
      return 'Week 1: Establishing baseline strength levels. Focus on form and tempo.';
    }

    return 'Week $weekNumber: Progressive overload applied based on Week ${weekNumber - 1} performance. '
        'Continue pushing for strength gains while maintaining proper form.';
  }

  /// Adjust program based on completed sessions
  Future<WeeklyProgram> adjustProgram(
    WeeklyProgram current,
    List<dynamic> completedSessions,
  ) async {
    // Calculate average RPE from completed sessions
    final avgRPE = completedSessions.isEmpty
        ? 8.0
        : completedSessions
                .map((s) => (s as Map<String, dynamic>)['rpe_average'] as double? ?? 8.0)
                .reduce((a, b) => a + b) /
            completedSessions.length;

    // If RPE is consistently high (>8.5), suggest deload week
    if (avgRPE > 8.5 && completedSessions.length >= 2) {
      // Create deload week (reduce weights by 10%, reduce sets by 1)
      final adjustedWorkouts = current.workouts.map((workout) {
        final adjustedExercises = workout.exercises.map((exercise) {
          return PlannedExercise(
            exercise: exercise.exercise,
            sets: exercise.sets > 1 ? exercise.sets - 1 : exercise.sets,
            reps: exercise.reps,
            weight: exercise.weight * 0.9,
            restTime: exercise.restTime,
            targetRPE: exercise.targetRPE,
            previousWeight: exercise.previousWeight,
            previousRPE: exercise.previousRPE,
          );
        }).toList();

        return PlannedWorkout(
          id: workout.id,
          workoutType: workout.workoutType,
          name: workout.name,
          exercises: adjustedExercises,
          estimatedDuration: workout.estimatedDuration,
          requiredEquipment: workout.requiredEquipment,
          completedAt: workout.completedAt,
        );
      }).toList();

      return WeeklyProgram(
        id: current.id,
        userId: current.userId,
        weekNumber: current.weekNumber,
        workouts: adjustedWorkouts,
        generatedDate: current.generatedDate,
        progressionNotes:
            'Deload week recommended due to high RPE (${avgRPE.toStringAsFixed(1)}). '
            'Reduced weights and volume to promote recovery.',
        isActive: current.isActive,
      );
    }

    return current; // No adjustments needed
  }
}
