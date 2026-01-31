import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../../../smart_planner/data/models/weekly_program.dart';

/// Repository for workout-related operations
class WorkoutRepository {
  final DatabaseHelper _dbHelper;

  WorkoutRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ============================================================================
  // Workout Session Operations
  // ============================================================================

  /// Save workout session (insert or update) with auto-backup
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Save session (use INSERT OR REPLACE to handle updates)
      final sessionData = session.toJson();
      sessionData.remove('sets'); // Don't store sets in session JSON
      
      // Check if session exists
      final existing = await txn.query(
        DatabaseConstants.tableWorkoutSessions,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [session.id],
      );
      
      if (existing.isNotEmpty) {
        // Update existing session
        await txn.update(
          DatabaseConstants.tableWorkoutSessions,
          sessionData,
          where: '${DatabaseConstants.colId} = ?',
          whereArgs: [session.id],
        );
        print('📊 Updated workout session: ${session.id}');
      } else {
        // Insert new session
        await txn.insert(
          DatabaseConstants.tableWorkoutSessions,
          sessionData,
        );
        print('📊 Saved new workout session: ${session.id}');
      }

      // Delete existing sets for this session first
      await txn.delete(
        DatabaseConstants.tableWorkoutSets,
        where: '${DatabaseConstants.colSessionId} = ?',
        whereArgs: [session.id],
      );

      // Save all sets
      for (final set in session.sets) {
        await txn.insert(DatabaseConstants.tableWorkoutSets, set.toJson());
      }
      
      print('📊 Saved ${session.sets.length} workout sets for session ${session.id}');
    });
    
    // Verify save completed successfully
    final savedSession = await getSessionById(session.id);
    if (savedSession == null) {
      throw Exception('Failed to save workout session - verification failed');
    }
  }

  /// Get workout session by ID
  Future<WorkoutSession?> getSessionById(String id) async {
    final sessionData = await _dbHelper.getById(
      DatabaseConstants.tableWorkoutSessions,
      id,
    );
    if (sessionData == null) return null;

    // Get all sets for this session
    final sets = await getSetsBySessionId(id);
    sessionData['sets'] = sets.map((s) => s.toJson()).toList();

    return WorkoutSession.fromJson(sessionData);
  }

  /// Get workout session by ID (alias for getSessionById)
  Future<WorkoutSession?> getSession(String id) => getSessionById(id);

  /// Get all workout sessions for user
  Future<List<WorkoutSession>> getSessionHistory({
    String userId = AppConstants.defaultUserId,
    int? limit,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableWorkoutSessions,
      where: '${DatabaseConstants.colUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseConstants.colStartTime} DESC',
      limit: limit,
    );

    final sessions = <WorkoutSession>[];
    for (final sessionData in results) {
      final sets = await getSetsBySessionId(sessionData[DatabaseConstants.colId] as String);
      sessionData['sets'] = sets.map((s) => s.toJson()).toList();
      sessions.add(WorkoutSession.fromJson(sessionData));
    }

    return sessions;
  }

  /// Get sessions by week number
  Future<List<WorkoutSession>> getSessionsByWeek({
    String userId = AppConstants.defaultUserId,
    required int weekNumber,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableWorkoutSessions,
      where: '${DatabaseConstants.colUserId} = ? AND ${DatabaseConstants.colWeekNumber} = ?',
      whereArgs: [userId, weekNumber],
      orderBy: '${DatabaseConstants.colStartTime} ASC',
    );

    final sessions = <WorkoutSession>[];
    for (final sessionData in results) {
      final sets = await getSetsBySessionId(sessionData[DatabaseConstants.colId] as String);
      sessionData['sets'] = sets.map((s) => s.toJson()).toList();
      sessions.add(WorkoutSession.fromJson(sessionData));
    }

    return sessions;
  }

  /// Get sessions by workout type (A or B)
  Future<List<WorkoutSession>> getSessionsByType({
    String userId = AppConstants.defaultUserId,
    required String workoutType,
    int? limit,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableWorkoutSessions,
      where: '${DatabaseConstants.colUserId} = ? AND ${DatabaseConstants.colWorkoutType} = ?',
      whereArgs: [userId, workoutType],
      orderBy: '${DatabaseConstants.colStartTime} DESC',
      limit: limit,
    );

    final sessions = <WorkoutSession>[];
    for (final sessionData in results) {
      final sets = await getSetsBySessionId(sessionData[DatabaseConstants.colId] as String);
      sessionData['sets'] = sets.map((s) => s.toJson()).toList();
      sessions.add(WorkoutSession.fromJson(sessionData));
    }

    return sessions;
  }

  /// Get completed sessions only
  Future<List<WorkoutSession>> getCompletedSessions({
    String userId = AppConstants.defaultUserId,
    int? limit,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableWorkoutSessions,
      where: '${DatabaseConstants.colUserId} = ? AND ${DatabaseConstants.colCompleted} = ?',
      whereArgs: [userId, 1],
      orderBy: '${DatabaseConstants.colStartTime} DESC',
      limit: limit,
    );

    final sessions = <WorkoutSession>[];
    for (final sessionData in results) {
      final sets = await getSetsBySessionId(sessionData[DatabaseConstants.colId] as String);
      sessionData['sets'] = sets.map((s) => s.toJson()).toList();
      sessions.add(WorkoutSession.fromJson(sessionData));
    }

    return sessions;
  }

  /// Update workout session
  Future<void> updateSession(WorkoutSession session) async {
    final data = session.toJson();
    data.remove('sets'); // Don't update sets here

    await _dbHelper.update(
      DatabaseConstants.tableWorkoutSessions,
      data,
      '${DatabaseConstants.colId} = ?',
      [session.id],
    );
  }

  /// Delete workout session (cascade deletes sets)
  Future<void> deleteSession(String id) async {
    await _dbHelper.deleteById(DatabaseConstants.tableWorkoutSessions, id);
  }

  // ============================================================================
  // Workout Set Operations
  // ============================================================================

  /// Save a single workout set
  Future<void> saveWorkoutSet(WorkoutSet set) async {
    await _dbHelper.insert(DatabaseConstants.tableWorkoutSets, set.toJson());
  }

  /// Get all sets for a session
  Future<List<WorkoutSet>> getSetsBySessionId(String sessionId) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableWorkoutSets,
      where: '${DatabaseConstants.colSessionId} = ?',
      whereArgs: [sessionId],
      orderBy: '${DatabaseConstants.colSetNumber} ASC',
    );

    return results.map((json) => WorkoutSet.fromJson(json)).toList();
  }

  /// Get sets for a specific exercise
  Future<List<WorkoutSet>> getSetsByExerciseId(
    String exerciseId, {
    int? limit,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableWorkoutSets,
      where: '${DatabaseConstants.colExerciseId} = ?',
      whereArgs: [exerciseId],
      orderBy: '${DatabaseConstants.colTimestamp} DESC',
      limit: limit,
    );

    return results.map((json) => WorkoutSet.fromJson(json)).toList();
  }

  /// Get last performance for an exercise (for progress tracking)
  Future<List<WorkoutSet>?> getLastExercisePerformance(
    String exerciseId, {
    String userId = AppConstants.defaultUserId,
  }) async {
    // Get the most recent session that included this exercise
    final sql = '''
      SELECT ws.* 
      FROM ${DatabaseConstants.tableWorkoutSets} ws
      INNER JOIN ${DatabaseConstants.tableWorkoutSessions} sess 
        ON ws.${DatabaseConstants.colSessionId} = sess.${DatabaseConstants.colId}
      WHERE ws.${DatabaseConstants.colExerciseId} = ? 
        AND sess.${DatabaseConstants.colUserId} = ?
        AND sess.${DatabaseConstants.colCompleted} = 1
      ORDER BY ws.${DatabaseConstants.colTimestamp} DESC
      LIMIT 10
    ''';

    final results = await _dbHelper.rawQuery(sql, [exerciseId, userId]);
    if (results.isEmpty) return null;

    return results.map((json) => WorkoutSet.fromJson(json)).toList();
  }

  // ============================================================================
  // Weekly Program Operations
  // ============================================================================

  /// Save weekly program
  Future<void> saveWeeklyProgram(WeeklyProgram program) async {
    // Prepare data for SQLite (only primitive types)
    final data = {
      DatabaseConstants.colId: program.id,
      DatabaseConstants.colUserId: program.userId,
      DatabaseConstants.colWeekNumber: program.weekNumber,
      DatabaseConstants.colGeneratedDate: program.generatedDate.toIso8601String(),
      DatabaseConstants.colWorkoutsJson: jsonEncode(program.workouts.map((w) => w.toJson()).toList()),
      DatabaseConstants.colProgressionNotes: program.progressionNotes,
      DatabaseConstants.colIsActive: program.isActive ? 1 : 0, // Convert bool to int
    };

    await _dbHelper.insert(DatabaseConstants.tableWeeklyPrograms, data);
  }

  /// Get current active program
  Future<WeeklyProgram?> getCurrentWeekProgram({
    String userId = AppConstants.defaultUserId,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableWeeklyPrograms,
      where: '${DatabaseConstants.colUserId} = ? AND ${DatabaseConstants.colIsActive} = ?',
      whereArgs: [userId, 1],
      orderBy: '${DatabaseConstants.colWeekNumber} DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _weeklyProgramFromMap(results.first);
  }

  /// Get program by week number
  Future<WeeklyProgram?> getProgramByWeek({
    String userId = AppConstants.defaultUserId,
    required int weekNumber,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableWeeklyPrograms,
      where: '${DatabaseConstants.colUserId} = ? AND ${DatabaseConstants.colWeekNumber} = ?',
      whereArgs: [userId, weekNumber],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _weeklyProgramFromMap(results.first);
  }

  /// Get all programs for user
  Future<List<WeeklyProgram>> getAllPrograms({
    String userId = AppConstants.defaultUserId,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableWeeklyPrograms,
      where: '${DatabaseConstants.colUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseConstants.colWeekNumber} DESC',
    );

    return results.map(_weeklyProgramFromMap).toList();
  }

  /// Deactivate all programs and activate new one
  Future<void> setActiveProgram(String programId, {String userId = AppConstants.defaultUserId}) async {
    await _dbHelper.transaction((txn) async {
      // Deactivate all programs for user
      await txn.update(
        DatabaseConstants.tableWeeklyPrograms,
        {DatabaseConstants.colIsActive: 0},
        where: '${DatabaseConstants.colUserId} = ?',
        whereArgs: [userId],
      );

      // Activate selected program
      await txn.update(
        DatabaseConstants.tableWeeklyPrograms,
        {DatabaseConstants.colIsActive: 1},
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [programId],
      );
    });
  }

  /// Update weekly program
  Future<void> updateProgram(WeeklyProgram program) async {
    // Prepare data for SQLite (only primitive types)
    final data = {
      DatabaseConstants.colId: program.id,
      DatabaseConstants.colUserId: program.userId,
      DatabaseConstants.colWeekNumber: program.weekNumber,
      DatabaseConstants.colGeneratedDate: program.generatedDate.toIso8601String(),
      DatabaseConstants.colWorkoutsJson: jsonEncode(program.workouts.map((w) => w.toJson()).toList()),
      DatabaseConstants.colProgressionNotes: program.progressionNotes,
      DatabaseConstants.colIsActive: program.isActive ? 1 : 0, // Convert bool to int
    };

    await _dbHelper.update(
      DatabaseConstants.tableWeeklyPrograms,
      data,
      '${DatabaseConstants.colId} = ?',
      [program.id],
    );
  }

  /// Delete weekly program
  Future<void> deleteProgram(String id) async {
    await _dbHelper.deleteById(DatabaseConstants.tableWeeklyPrograms, id);
  }

  /// Get a specific planned workout by ID from any week program
  Future<PlannedWorkout?> getWorkout(String workoutId) async {
    final db = await _dbHelper.database;
    
    print('🔍 Looking for workout: $workoutId');
    
    // Get all programs and search for the workout
    final programsData = await db.query(
      DatabaseConstants.tableWeeklyPrograms,
      orderBy: '${DatabaseConstants.colWeekNumber} DESC',
    );

    print('🔍 Found ${programsData.length} programs in database');

    for (final programData in programsData) {
      final program = _programFromMap(programData);
      print('🔍 Program week ${program.weekNumber} has ${program.workouts.length} workouts');
      
      try {
        final workout = program.workouts.firstWhere(
          (w) => w.id == workoutId,
        );
        print('✅ Found workout: ${workout.name}');
        return workout;
      } catch (e) {
        // Workout not found in this program, continue to next
        continue;
      }
    }
    
    print('❌ Workout $workoutId not found in any program');
    return null;
  }

  // ============================================================================
  // Statistics & Analytics
  // ============================================================================

  /// Get total volume lifted in a period
  Future<double> getTotalVolumeLifted({
    String userId = AppConstants.defaultUserId,
    required DateTime start,
    required DateTime end,
  }) async {
    final sql = '''
      SELECT SUM(${DatabaseConstants.colTotalVolumeKg}) as total
      FROM ${DatabaseConstants.tableWorkoutSessions}
      WHERE ${DatabaseConstants.colUserId} = ?
        AND ${DatabaseConstants.colStartTime} >= ?
        AND ${DatabaseConstants.colStartTime} <= ?
        AND ${DatabaseConstants.colCompleted} = 1
    ''';

    final results = await _dbHelper.rawQuery(
      sql,
      [userId, start.toIso8601String(), end.toIso8601String()],
    );

    if (results.isEmpty || results.first['total'] == null) return 0.0;
    return (results.first['total'] as num).toDouble();
  }

  /// Get workout completion count for week
  Future<int> getWeekCompletionCount({
    String userId = AppConstants.defaultUserId,
    required int weekNumber,
  }) async {
    final count = await _dbHelper.getCount(
      DatabaseConstants.tableWorkoutSessions,
      where: '${DatabaseConstants.colUserId} = ? AND ${DatabaseConstants.colWeekNumber} = ? AND ${DatabaseConstants.colCompleted} = ?',
      whereArgs: [userId, weekNumber, 1],
    );
    return count ?? 0;
  }

  /// Get average RPE for period
  Future<double?> getAverageRPE({
    String userId = AppConstants.defaultUserId,
    required DateTime start,
    required DateTime end,
  }) async {
    final sql = '''
      SELECT AVG(${DatabaseConstants.colRpeAverage}) as average
      FROM ${DatabaseConstants.tableWorkoutSessions}
      WHERE ${DatabaseConstants.colUserId} = ?
        AND ${DatabaseConstants.colStartTime} >= ?
        AND ${DatabaseConstants.colStartTime} <= ?
        AND ${DatabaseConstants.colCompleted} = 1
    ''';

    final results = await _dbHelper.rawQuery(
      sql,
      [userId, start.toIso8601String(), end.toIso8601String()],
    );

    if (results.isEmpty || results.first['average'] == null) return null;
    return (results.first['average'] as num).toDouble();
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  WeeklyProgram _weeklyProgramFromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    
    // Decode workouts JSON
    final workoutsJson = jsonDecode(map[DatabaseConstants.colWorkoutsJson] as String) as List;
    data['workouts'] = workoutsJson.map((w) => w as Map<String, dynamic>).toList();
    
    // Convert int to bool for isActive
    data['is_active'] = (map[DatabaseConstants.colIsActive] as int) == 1;

    return WeeklyProgram.fromJson(data);
  }

  // Alias for consistency
  WeeklyProgram _programFromMap(Map<String, dynamic> map) {
    return _weeklyProgramFromMap(map);
  }
}

// ============================================================================
// Provider
// ============================================================================

/// Provider for WorkoutRepository
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});
