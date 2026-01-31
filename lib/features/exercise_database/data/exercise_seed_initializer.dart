import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_helper.dart';
import 'exercise_seeder.dart';

/// Service to initialize exercise database on first launch
class ExerciseSeedInitializer {
  static const String _seedCompleteKey = 'exercise_seed_complete';
  static const String _seedVersionKey = 'exercise_seed_version';
  static const int _currentSeedVersion = 5; // DB v2 migration complete, re-seed with Firebase fields

  final DatabaseHelper _databaseHelper;
  final SharedPreferences _prefs;
  late final ExerciseSeeder _seeder;

  ExerciseSeedInitializer(this._databaseHelper, this._prefs) {
    _seeder = ExerciseSeeder(_databaseHelper);
  }

  /// Initialize exercises if needed (call on app startup)
  Future<bool> initializeIfNeeded() async {
    try {
      // Check if seeding is complete
      final seedComplete = _prefs.getBool(_seedCompleteKey) ?? false;
      final seedVersion = _prefs.getInt(_seedVersionKey) ?? 0;

      // First launch - seed database
      if (!seedComplete) {
        print('First launch detected - seeding exercise database...');
        final count = await _seeder.seedExercises();
        
        if (count > 0) {
          await _prefs.setBool(_seedCompleteKey, true);
          await _prefs.setInt(_seedVersionKey, _currentSeedVersion);
          print('Exercise database seeded successfully with $count exercises');
          return true;
        } else {
          print('Failed to seed exercise database');
          return false;
        }
      }
      
      // Check if seed version needs update
      if (seedVersion < _currentSeedVersion) {
        print('New seed version detected - updating exercises...');
        final count = await _seeder.updateExercisesFromSeed();
        await _prefs.setInt(_seedVersionKey, _currentSeedVersion);
        print('Updated $count exercises to version $_currentSeedVersion');
        return true;
      }

      // Verify database actually has exercises (catch corruption case)
      final exerciseCount = await _databaseHelper.getExerciseCount();
      if (exerciseCount == 0) {
        print('Database is empty despite seed status - reseeding...');
        await _prefs.remove(_seedCompleteKey);
        await _prefs.remove(_seedVersionKey);
        return await initializeIfNeeded();
      }

      // Already seeded
      print('Exercise database already initialized (version $seedVersion)');
      return true;
    } catch (e) {
      print('Error initializing exercise database: $e');
      // If there's any error, it might be data corruption - reset and reseed
      if (e.toString().contains('FormatException') || e.toString().contains('type')) {
        print('Detected data corruption - clearing and reseeding...');
        try {
          await _prefs.remove(_seedCompleteKey);
          await _prefs.remove(_seedVersionKey);
          await _seeder.reseedExercises();
          await _prefs.setBool(_seedCompleteKey, true);
          await _prefs.setInt(_seedVersionKey, _currentSeedVersion);
          print('Database cleared and reseeded successfully');
          return true;
        } catch (reseedError) {
          print('Failed to reseed after corruption: $reseedError');
          return false;
        }
      }
      return false;
    }
  }

  /// Force re-seed (for testing/debugging)
  Future<bool> forceSeed() async {
    try {
      final count = await _seeder.reseedExercises();
      if (count > 0) {
        await _prefs.setBool(_seedCompleteKey, true);
        await _prefs.setInt(_seedVersionKey, _currentSeedVersion);
        print('Force re-seeded $count exercises');
        return true;
      }
      return false;
    } catch (e) {
      print('Error force seeding: $e');
      return false;
    }
  }

  /// Reset seed status (for testing)
  Future<void> resetSeedStatus() async {
    await _prefs.remove(_seedCompleteKey);
    await _prefs.remove(_seedVersionKey);
    print('Seed status reset');
  }

  /// Get seed info
  Future<Map<String, dynamic>> getSeedInfo() async {
    final seedComplete = _prefs.getBool(_seedCompleteKey) ?? false;
    final seedVersion = _prefs.getInt(_seedVersionKey) ?? 0;
    final exerciseCount = await _databaseHelper.getExerciseCount();
    final muscleGroupCounts = await _seeder.getExerciseCountByMuscleGroup();

    return {
      'seed_complete': seedComplete,
      'seed_version': seedVersion,
      'current_version': _currentSeedVersion,
      'exercise_count': exerciseCount,
      'muscle_group_breakdown': muscleGroupCounts,
      'needs_update': seedVersion < _currentSeedVersion,
    };
  }

  /// Validate seed data integrity
  Future<bool> validateSeed() async {
    return await _seeder.validateSeedData();
  }
}
