import 'package:equatable/equatable.dart';

/// Single set performed during a workout
class WorkoutSet extends Equatable {
  final String id;
  final String sessionId;
  final String exerciseId;
  final String exerciseName; // Denormalized for quick access
  final int setNumber; // 1, 2, 3, 4...
  final int targetReps;
  final int actualReps;
  final double targetWeight; // kg
  final double actualWeight; // kg
  final int rpe; // Rate of Perceived Exertion (1-10)
  final int restTimeSec; // Seconds rested after this set
  final DateTime timestamp;
  final String? notes;

  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.targetReps,
    required this.actualReps,
    required this.targetWeight,
    required this.actualWeight,
    required this.rpe,
    required this.restTimeSec,
    required this.timestamp,
    this.notes,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String,
      setNumber: json['set_number'] as int,
      targetReps: json['target_reps'] as int,
      actualReps: json['actual_reps'] as int,
      targetWeight: (json['target_weight'] as num).toDouble(),
      actualWeight: (json['actual_weight'] as num).toDouble(),
      rpe: json['rpe'] as int,
      restTimeSec: json['rest_time_sec'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'set_number': setNumber,
      'target_reps': targetReps,
      'actual_reps': actualReps,
      'target_weight': targetWeight,
      'actual_weight': actualWeight,
      'rpe': rpe,
      'rest_time_sec': restTimeSec,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  WorkoutSet copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    String? exerciseName,
    int? setNumber,
    int? targetReps,
    int? actualReps,
    double? targetWeight,
    double? actualWeight,
    int? rpe,
    int? restTimeSec,
    DateTime? timestamp,
    String? notes,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      setNumber: setNumber ?? this.setNumber,
      targetReps: targetReps ?? this.targetReps,
      actualReps: actualReps ?? this.actualReps,
      targetWeight: targetWeight ?? this.targetWeight,
      actualWeight: actualWeight ?? this.actualWeight,
      rpe: rpe ?? this.rpe,
      restTimeSec: restTimeSec ?? this.restTimeSec,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }

  /// Calculate volume for this set (weight × reps)
  double get volume => actualWeight * actualReps;

  /// Check if set was completed as prescribed
  bool get isComplete => actualReps >= targetReps && actualWeight >= targetWeight;

  /// Check if set exceeded target
  bool get exceededTarget => actualReps > targetReps || actualWeight > targetWeight;

  /// Difficulty assessment based on RPE
  String get difficultyLevel {
    if (rpe <= 7) return 'Easy';
    if (rpe <= 8) return 'Moderate';
    return 'Hard';
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        exerciseId,
        exerciseName,
        setNumber,
        targetReps,
        actualReps,
        targetWeight,
        actualWeight,
        rpe,
        restTimeSec,
        timestamp,
        notes,
      ];
}
