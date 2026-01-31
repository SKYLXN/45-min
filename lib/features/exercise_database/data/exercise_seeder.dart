import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/database/database_helper.dart';
import 'models/exercise.dart';
import 'repositories/exercise_repository.dart';

/// Service class for seeding the exercise database with initial data
class ExerciseSeeder {
  final DatabaseHelper _databaseHelper;
  late final ExerciseRepository _repository;

  ExerciseSeeder(this._databaseHelper) {
    _repository = ExerciseRepository(dbHelper: _databaseHelper);
  }

  /// Seeds the database with exercises from the JSON file
  /// Returns the number of exercises added
  Future<int> seedExercises() async {
    try {
      // Check if exercises already exist
      final existingCount = await _repository.getExerciseCount();
      if (existingCount > 0) {
        print('Database already contains $existingCount exercises. Skipping seed.');
        return 0;
      }

      // Load JSON file
      final jsonString = await rootBundle.loadString(
        'lib/features/exercise_database/data/exercises_seed_mapped.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      // Convert JSON to Exercise objects and insert
      int insertedCount = 0;
      for (final exerciseJson in jsonData) {
        try {
          final exercise = Exercise.fromJson(exerciseJson);
          await _repository.saveExercise(exercise);
          insertedCount++;
        } catch (e) {
          print('Error inserting exercise ${exerciseJson['name']}: $e');
        }
      }

      print('Successfully seeded $insertedCount exercises');
      return insertedCount;
    } catch (e) {
      print('Error seeding exercises: $e');
      
      // If there's a format error, clear and retry once
      if (e.toString().contains('FormatException')) {
        print('Detected format error - clearing database and retrying...');
        await _repository.clearExercises();
        return await _retrySeed();
      }
      
      rethrow;
    }
  }

  /// Retry seeding after clearing database
  Future<int> _retrySeed() async {
    final jsonString = await rootBundle.loadString(
      'lib/features/exercise_database/data/exercises_seed_mapped.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);

    int insertedCount = 0;
    for (final exerciseJson in jsonData) {
      try {
        final exercise = Exercise.fromJson(exerciseJson);
        await _repository.saveExercise(exercise);
        insertedCount++;
      } catch (e) {
        print('Error inserting exercise ${exerciseJson['name']}: $e');
      }
    }

    print('Successfully reseeded $insertedCount exercises');
    return insertedCount;
  }

  /// Re-seeds the database (clears existing exercises and re-adds from JSON)
  /// Use with caution - this will delete all exercise data
  Future<int> reseedExercises() async {
    try {
      // Clear existing exercises
      await _repository.clearExercises();
      print('Cleared existing exercises');

      // Load and insert new data
      return await _retrySeed();
    } catch (e) {
      print('Error re-seeding exercises: $e');
      rethrow;
    }
  }

  /// Updates specific exercises from JSON without deleting all data
  /// Useful for updating exercise details without losing user data
  Future<int> updateExercisesFromSeed() async {
    try {
      // Load JSON file
      final jsonString = await rootBundle.loadString(
        'lib/features/exercise_database/data/exercises_seed_mapped.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      int updatedCount = 0;
      for (final exerciseJson in jsonData) {
        try {
          final exercise = Exercise.fromJson(exerciseJson);
          final existing = await _repository.getExerciseById(exercise.id);
          
          if (existing != null) {
            // Update existing exercise
            await _repository.updateExercise(exercise);
            updatedCount++;
          } else {
            // Insert new exercise
            await _repository.saveExercise(exercise);
            updatedCount++;
          }
        } catch (e) {
          print('Error updating exercise ${exerciseJson['name']}: $e');
        }
      }

      print('Successfully updated $updatedCount exercises');
      return updatedCount;
    } catch (e) {
      print('Error updating exercises: $e');
      rethrow;
    }
  }

  /// Validates the seed data integrity
  /// Returns true if all exercises have required fields
  Future<bool> validateSeedData() async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/features/exercise_database/data/exercises_seed_mapped.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      for (final exerciseJson in jsonData) {
        // Check required fields
        if (!exerciseJson.containsKey('id') ||
            !exerciseJson.containsKey('name') ||
            !exerciseJson.containsKey('muscle_group') ||
            !exerciseJson.containsKey('equipment') ||
            !exerciseJson.containsKey('difficulty')) {
          print('Invalid exercise data: Missing required fields in ${exerciseJson['name']}');
          return false;
        }
      }

      print('Seed data validation passed for ${jsonData.length} exercises');
      return true;
    } catch (e) {
      print('Error validating seed data: $e');
      return false;
    }
  }

  /// Gets exercise count by muscle group from seed data
  Future<Map<String, int>> getExerciseCountByMuscleGroup() async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/features/exercise_database/data/exercises_seed_mapped.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      final Map<String, int> counts = {};
      for (final exerciseJson in jsonData) {
        final muscleGroup = exerciseJson['muscle_group'] as String;
        counts[muscleGroup] = (counts[muscleGroup] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting exercise counts: $e');
      return {};
    }
  }
}
