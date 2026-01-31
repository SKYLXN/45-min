import 'dart:convert';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';
import '../models/exercise.dart';

/// Repository for exercise database operations
class ExerciseRepository {
  final DatabaseHelper _dbHelper;

  ExerciseRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  /// Save exercise to database
  Future<void> saveExercise(Exercise exercise) async {
    final data = {
      DatabaseConstants.colId: exercise.id,
      DatabaseConstants.colName: exercise.name,
      DatabaseConstants.colMuscleGroup: exercise.muscleGroup,
      DatabaseConstants.colSecondaryMuscles: jsonEncode(exercise.secondaryMuscles),
      DatabaseConstants.colEquipmentRequired: jsonEncode(exercise.equipmentRequired),
      DatabaseConstants.colDifficulty: exercise.difficulty,
      DatabaseConstants.colVideoUrl: exercise.videoUrl,
      DatabaseConstants.colGifUrl: exercise.gifUrl,
      DatabaseConstants.colInstructions: jsonEncode(exercise.instructions),
      DatabaseConstants.colTempo: exercise.tempo,
      DatabaseConstants.colIsCompound: exercise.isCompound ? 1 : 0,
      DatabaseConstants.colAlternatives: jsonEncode(exercise.alternatives),
      DatabaseConstants.colFirebaseId: exercise.firebaseId,
      DatabaseConstants.colFirebaseName: exercise.firebaseName,
    };

    await _dbHelper.insert(DatabaseConstants.tableExercises, data);
  }

  /// Save multiple exercises (bulk insert)
  Future<void> saveExercises(List<Exercise> exercises) async {
    final records = exercises.map((exercise) {
      return {
        DatabaseConstants.colId: exercise.id,
        DatabaseConstants.colName: exercise.name,
        DatabaseConstants.colMuscleGroup: exercise.muscleGroup,
        DatabaseConstants.colSecondaryMuscles: jsonEncode(exercise.secondaryMuscles),
        DatabaseConstants.colEquipmentRequired: jsonEncode(exercise.equipmentRequired),
        DatabaseConstants.colDifficulty: exercise.difficulty,
        DatabaseConstants.colVideoUrl: exercise.videoUrl,
        DatabaseConstants.colGifUrl: exercise.gifUrl,
        DatabaseConstants.colInstructions: jsonEncode(exercise.instructions),
        DatabaseConstants.colTempo: exercise.tempo,
        DatabaseConstants.colIsCompound: exercise.isCompound ? 1 : 0,
        DatabaseConstants.colAlternatives: jsonEncode(exercise.alternatives),
      };
    }).toList();

    await _dbHelper.insertBatch(DatabaseConstants.tableExercises, records);
  }

  /// Get exercise by ID
  Future<Exercise?> getExerciseById(String id) async {
    final result = await _dbHelper.getById(DatabaseConstants.tableExercises, id);
    if (result == null) return null;
    return _exerciseFromMap(result);
  }

  /// Get all exercises
  Future<List<Exercise>> getAllExercises() async {
    try {
      final results = await _dbHelper.getAll(
        DatabaseConstants.tableExercises,
        orderBy: DatabaseConstants.colName,
      );
      return results.map(_exerciseFromMap).toList();
    } catch (e) {
      // If we hit a format error, the database has corrupted data
      if (e.toString().contains('FormatException')) {
        print('Format error detected in getAllExercises - database needs clearing');
        // Clear corrupted data
        await clearExercises();
        // Return empty list so app can trigger reseed
        return [];
      }
      rethrow;
    }
  }

  /// Update exercise
  Future<void> updateExercise(Exercise exercise) async {
    final data = {
      DatabaseConstants.colName: exercise.name,
      DatabaseConstants.colMuscleGroup: exercise.muscleGroup,
      DatabaseConstants.colSecondaryMuscles: jsonEncode(exercise.secondaryMuscles),
      DatabaseConstants.colEquipmentRequired: jsonEncode(exercise.equipmentRequired),
      DatabaseConstants.colDifficulty: exercise.difficulty,
      DatabaseConstants.colVideoUrl: exercise.videoUrl,
      DatabaseConstants.colGifUrl: exercise.gifUrl,
      DatabaseConstants.colInstructions: jsonEncode(exercise.instructions),
      DatabaseConstants.colTempo: exercise.tempo,
      DatabaseConstants.colIsCompound: exercise.isCompound ? 1 : 0,
      DatabaseConstants.colAlternatives: jsonEncode(exercise.alternatives),
      DatabaseConstants.colFirebaseId: exercise.firebaseId,
      DatabaseConstants.colFirebaseName: exercise.firebaseName,
    };

    await _dbHelper.update(
      DatabaseConstants.tableExercises,
      data,
      '${DatabaseConstants.colId} = ?',
      [exercise.id],
    );
  }

  /// Delete exercise
  Future<void> deleteExercise(String id) async {
    await _dbHelper.deleteById(DatabaseConstants.tableExercises, id);
  }

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// Get exercises by muscle group
  Future<List<Exercise>> getExercisesByMuscle(String muscleGroup) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableExercises,
      where: '${DatabaseConstants.colMuscleGroup} = ?',
      whereArgs: [muscleGroup],
      orderBy: DatabaseConstants.colName,
    );
    return results.map(_exerciseFromMap).toList();
  }

  /// Get exercises by equipment (supports multiple equipment types)
  Future<List<Exercise>> getExercisesByEquipment(
    List<String> equipment,
  ) async {
    if (equipment.isEmpty) return getAllExercises();

    // Get all exercises and filter by equipment
    final allExercises = await getAllExercises();
    
    return allExercises.where((exercise) {
      // Exercise is valid if it requires no equipment or all required equipment is available
      if (exercise.isBodyweightOnly) return true;
      
      return exercise.equipmentRequired.every(
        (required) => equipment.contains(required) || required == 'bodyweight',
      );
    }).toList();
  }

  /// Search exercises by name
  Future<List<Exercise>> searchExercises(String query) async {
    if (query.isEmpty) return getAllExercises();

    final results = await _dbHelper.query(
      DatabaseConstants.tableExercises,
      where: '${DatabaseConstants.colName} LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: DatabaseConstants.colName,
    );
    return results.map(_exerciseFromMap).toList();
  }

  /// Get alternative exercises for a given exercise ID
  Future<List<Exercise>> getAlternativeExercises(String exerciseId) async {
    final exercise = await getExerciseById(exerciseId);
    if (exercise == null || exercise.alternatives.isEmpty) return [];

    // Get all alternative exercises by IDs
    final alternatives = <Exercise>[];
    for (final altId in exercise.alternatives) {
      final alt = await getExerciseById(altId);
      if (alt != null) alternatives.add(alt);
    }
    return alternatives;
  }

  /// Get exercises by difficulty level
  Future<List<Exercise>> getExercisesByDifficulty(String difficulty) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableExercises,
      where: '${DatabaseConstants.colDifficulty} = ?',
      whereArgs: [difficulty],
      orderBy: DatabaseConstants.colName,
    );
    return results.map(_exerciseFromMap).toList();
  }

  /// Get compound exercises only
  Future<List<Exercise>> getCompoundExercises() async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableExercises,
      where: '${DatabaseConstants.colIsCompound} = ?',
      whereArgs: [1],
      orderBy: DatabaseConstants.colName,
    );
    return results.map(_exerciseFromMap).toList();
  }

  /// Get isolation exercises only
  Future<List<Exercise>> getIsolationExercises() async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableExercises,
      where: '${DatabaseConstants.colIsCompound} = ?',
      whereArgs: [0],
      orderBy: DatabaseConstants.colName,
    );
    return results.map(_exerciseFromMap).toList();
  }

  // ============================================================================
  // Advanced Queries
  // ============================================================================

  /// Get exercises by multiple filters
  Future<List<Exercise>> getExercisesFiltered({
    String? muscleGroup,
    List<String>? equipment,
    String? difficulty,
    bool? isCompound,
  }) async {
    var exercises = await getAllExercises();

    if (muscleGroup != null) {
      exercises = exercises
          .where((e) => e.muscleGroup == muscleGroup)
          .toList();
    }

    if (equipment != null && equipment.isNotEmpty) {
      exercises = exercises.where((e) {
        if (e.isBodyweightOnly) return true;
        return e.equipmentRequired.every(
          (req) => equipment.contains(req) || req == 'bodyweight',
        );
      }).toList();
    }

    if (difficulty != null) {
      exercises = exercises
          .where((e) => e.difficulty == difficulty)
          .toList();
    }

    if (isCompound != null) {
      exercises = exercises
          .where((e) => e.isCompound == isCompound)
          .toList();
    }

    return exercises;
  }

  /// Get exercises that target secondary muscle
  Future<List<Exercise>> getExercisesBySecondaryMuscle(
    String muscle,
  ) async {
    final allExercises = await getAllExercises();
    return allExercises
        .where((e) => e.secondaryMuscles.contains(muscle))
        .toList();
  }

  /// Get exercise count by muscle group
  Future<Map<String, int>> getExerciseCountByMuscle() async {
    final exercises = await getAllExercises();
    final counts = <String, int>{};

    for (final exercise in exercises) {
      counts[exercise.muscleGroup] = (counts[exercise.muscleGroup] ?? 0) + 1;
    }

    return counts;
  }

  // ============================================================================
  // Utility Methods
  // ============================================================================

  /// Check if exercises table is populated
  Future<bool> hasExercises() async {
    final count = await _dbHelper.getCount(DatabaseConstants.tableExercises);
    return count != null && count > 0;
  }

  /// Get total exercise count
  Future<int> getExerciseCount() async {
    final count = await _dbHelper.getCount(DatabaseConstants.tableExercises);
    return count ?? 0;
  }

  /// Clear all exercises (for re-seeding)
  Future<void> clearExercises() async {
    await _dbHelper.clearTable(DatabaseConstants.tableExercises);
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Convert database map to Exercise model
  Exercise _exerciseFromMap(Map<String, dynamic> map) {
    // Convert database column names to JSON format expected by Exercise.fromJson
    return Exercise(
      id: map[DatabaseConstants.colId] as String,
      name: map[DatabaseConstants.colName] as String,
      muscleGroup: map[DatabaseConstants.colMuscleGroup] as String,
      secondaryMuscles: (jsonDecode(map[DatabaseConstants.colSecondaryMuscles] as String) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      equipmentRequired: (jsonDecode(map[DatabaseConstants.colEquipmentRequired] as String) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      difficulty: map[DatabaseConstants.colDifficulty] as String,
      videoUrl: map[DatabaseConstants.colVideoUrl] as String?,
      gifUrl: map[DatabaseConstants.colGifUrl] as String?,
      instructions: (jsonDecode(map[DatabaseConstants.colInstructions] as String) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tempo: map[DatabaseConstants.colTempo] as String,
      isCompound: (map[DatabaseConstants.colIsCompound] as int) == 1,
      alternatives: (jsonDecode(map[DatabaseConstants.colAlternatives] as String) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      firebaseId: map[DatabaseConstants.colFirebaseId] as String?,
      firebaseName: map[DatabaseConstants.colFirebaseName] as String?,
    );
  }
}
