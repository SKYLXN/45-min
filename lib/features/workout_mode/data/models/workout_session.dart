import 'package:equatable/equatable.dart';
import 'workout_set.dart';

/// Complete workout session with all sets
class WorkoutSession extends Equatable {
  final String id;
  final String userId;
  final String workoutType; // 'A', 'B', etc.
  final int weekNumber;
  final List<WorkoutSet> sets;
  final DateTime? startTime;
  final DateTime? endTime;
  final double totalVolumeKg; // Total weight × reps
  final double? rpeAverage; // Average RPE across all sets
  final String? notes;
  final bool completed;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.workoutType,
    required this.weekNumber,
    required this.sets,
    this.startTime,
    this.endTime,
    required this.totalVolumeKg,
    this.rpeAverage,
    this.notes,
    required this.completed,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutType: json['workout_type'] as String,
      weekNumber: json['week_number'] as int,
      sets: (json['sets'] as List<dynamic>)
          .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      totalVolumeKg: (json['total_volume_kg'] as num).toDouble(),
      rpeAverage: json['rpe_average'] != null
          ? (json['rpe_average'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      completed: json['completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_type': workoutType,
      'week_number': weekNumber,
      'sets': sets.map((s) => s.toJson()).toList(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_volume_kg': totalVolumeKg,
      'rpe_average': rpeAverage,
      'notes': notes,
      'completed': completed ? 1 : 0, // Convert bool to int for SQLite
    };
  }

  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? workoutType,
    int? weekNumber,
    List<WorkoutSet>? sets,
    DateTime? startTime,
    DateTime? endTime,
    double? totalVolumeKg,
    double? rpeAverage,
    String? notes,
    bool? completed,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutType: workoutType ?? this.workoutType,
      weekNumber: weekNumber ?? this.weekNumber,
      sets: sets ?? this.sets,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      rpeAverage: rpeAverage ?? this.rpeAverage,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }

  /// Calculate workout duration in minutes
  int? get durationMinutes {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!).inMinutes;
  }

  /// Get unique exercises in this session
  List<String> get exerciseIds {
    return sets.map((s) => s.exerciseId).toSet().toList();
  }

  /// Get number of unique exercises
  int get exerciseCount => exerciseIds.length;

  /// Get total number of sets
  int get totalSets => sets.length;

  /// Check if workout met the 45-minute target
  bool get metTimeTarget {
    final duration = durationMinutes;
    if (duration == null) return false;
    return duration <= 45;
  }

  /// Calculate recalculated total volume from sets
  double calculateTotalVolume() {
    return sets.fold(0.0, (sum, set) => sum + set.volume);
  }

  /// Calculate average RPE from sets
  double calculateAverageRPE() {
    if (sets.isEmpty) return 0.0;
    final totalRPE = sets.fold(0, (sum, set) => sum + set.rpe);
    return totalRPE / sets.length;
  }

  /// Group sets by exercise
  Map<String, List<WorkoutSet>> get setsByExercise {
    final grouped = <String, List<WorkoutSet>>{};
    for (final set in sets) {
      grouped.putIfAbsent(set.exerciseId, () => []).add(set);
    }
    return grouped;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        workoutType,
        weekNumber,
        sets,
        startTime,
        endTime,
        totalVolumeKg,
        rpeAverage,
        notes,
        completed,
      ];
}
