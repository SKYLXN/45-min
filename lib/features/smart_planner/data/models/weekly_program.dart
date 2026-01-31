import 'package:equatable/equatable.dart';
import '../../../exercise_database/data/models/exercise.dart';

/// Planned workout with exercises and target sets/reps
class PlannedWorkout extends Equatable {
  final String id;
  final String workoutType; // 'A', 'B', etc.
  final String name; // e.g., "Chest & Triceps"
  final List<PlannedExercise> exercises;
  final int estimatedDuration; // minutes
  final List<String> requiredEquipment;
  final DateTime? completedAt;

  const PlannedWorkout({
    required this.id,
    required this.workoutType,
    required this.name,
    required this.exercises,
    required this.estimatedDuration,
    required this.requiredEquipment,
    this.completedAt,
  });

  factory PlannedWorkout.fromJson(Map<String, dynamic> json) {
    return PlannedWorkout(
      id: json['id'] as String,
      workoutType: json['workout_type'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => PlannedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedDuration: json['estimated_duration'] as int,
      requiredEquipment: (json['required_equipment'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_type': workoutType,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'estimated_duration': estimatedDuration,
      'required_equipment': requiredEquipment,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  PlannedWorkout copyWith({
    String? id,
    String? workoutType,
    String? name,
    List<PlannedExercise>? exercises,
    int? estimatedDuration,
    List<String>? requiredEquipment,
    DateTime? completedAt,
  }) {
    return PlannedWorkout(
      id: id ?? this.id,
      workoutType: workoutType ?? this.workoutType,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workoutType,
        name,
        exercises,
        estimatedDuration,
        requiredEquipment,
        completedAt,
      ];
}

/// Planned exercise with target sets and reps
class PlannedExercise extends Equatable {
  final Exercise exercise;
  final int sets;
  final int reps;
  final double weight; // kg
  final int restTime; // seconds
  final double targetRPE;
  final double? previousWeight;
  final double? previousRPE;

  const PlannedExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restTime,
    required this.targetRPE,
    this.previousWeight,
    this.previousRPE,
  });

  factory PlannedExercise.fromJson(Map<String, dynamic> json) {
    return PlannedExercise(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      restTime: json['rest_time'] as int,
      targetRPE: (json['target_rpe'] as num).toDouble(),
      previousWeight: json['previous_weight'] != null
          ? (json['previous_weight'] as num).toDouble()
          : null,
      previousRPE: json['previous_rpe'] != null
          ? (json['previous_rpe'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'rest_time': restTime,
      'target_rpe': targetRPE,
      'previous_weight': previousWeight,
      'previous_rpe': previousRPE,
    };
  }

  PlannedExercise copyWith({
    Exercise? exercise,
    int? sets,
    int? reps,
    double? weight,
    int? restTime,
    double? targetRPE,
    double? previousWeight,
    double? previousRPE,
  }) {
    return PlannedExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      targetRPE: targetRPE ?? this.targetRPE,
      previousWeight: previousWeight ?? this.previousWeight,
      previousRPE: previousRPE ?? this.previousRPE,
    );
  }

  /// Calculate target volume for this exercise
  double get targetVolume => weight * reps * sets;

  @override
  List<Object?> get props => [
        exercise,
        sets,
        reps,
        weight,
        restTime,
        targetRPE,
        previousWeight,
        previousRPE,
      ];
}

/// Weekly program with 4 workouts (A/B/A/B)
class WeeklyProgram extends Equatable {
  final String id;
  final String userId;
  final int weekNumber;
  final DateTime generatedDate;
  final List<PlannedWorkout> workouts;
  final String? progressionNotes;
  final bool isActive;

  const WeeklyProgram({
    required this.id,
    required this.userId,
    required this.weekNumber,
    required this.generatedDate,
    required this.workouts,
    this.progressionNotes,
    required this.isActive,
  });

  factory WeeklyProgram.fromJson(Map<String, dynamic> json) {
    return WeeklyProgram(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekNumber: json['week_number'] as int,
      generatedDate: DateTime.parse(json['generated_date'] as String),
      workouts: (json['workouts'] as List<dynamic>)
          .map((e) => PlannedWorkout.fromJson(e as Map<String, dynamic>))
          .toList(),
      progressionNotes: json['progression_notes'] as String?,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'week_number': weekNumber,
      'generated_date': generatedDate.toIso8601String(),
      'workouts': workouts.map((w) => w.toJson()).toList(),
      'progression_notes': progressionNotes,
      'is_active': isActive,
    };
  }

  WeeklyProgram copyWith({
    String? id,
    String? userId,
    int? weekNumber,
    DateTime? generatedDate,
    List<PlannedWorkout>? workouts,
    String? progressionNotes,
    bool? isActive,
  }) {
    return WeeklyProgram(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekNumber: weekNumber ?? this.weekNumber,
      generatedDate: generatedDate ?? this.generatedDate,
      workouts: workouts ?? this.workouts,
      progressionNotes: progressionNotes ?? this.progressionNotes,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get workout by type (A or B)
  PlannedWorkout? getWorkout(String type) {
    try {
      return workouts.firstWhere((w) => w.workoutType == type);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        weekNumber,
        generatedDate,
        workouts,
        progressionNotes,
        isActive,
      ];
}
