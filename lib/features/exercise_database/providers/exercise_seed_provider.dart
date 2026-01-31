import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_helper.dart';
import '../data/exercise_seed_initializer.dart';

/// Provider for SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider to trigger seed initialization on app startup
final exerciseSeedStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final databaseHelper = DatabaseHelper.instance;
  final prefs = await SharedPreferences.getInstance();
  final initializer = ExerciseSeedInitializer(databaseHelper, prefs);
  
  // Initialize exercises if needed
  await initializer.initializeIfNeeded();
  
  // Return seed info
  return await initializer.getSeedInfo();
});

/// Provider for validating seed data
final exerciseSeedValidationProvider = FutureProvider<bool>((ref) async {
  final databaseHelper = DatabaseHelper.instance;
  final prefs = await SharedPreferences.getInstance();
  final initializer = ExerciseSeedInitializer(databaseHelper, prefs);
  return await initializer.validateSeed();
});
