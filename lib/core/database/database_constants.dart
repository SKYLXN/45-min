/// Database constants for table and column names
class DatabaseConstants {
  DatabaseConstants._();

  // Database info
  static const String databaseName = '45min.db';
  static const int databaseVersion = 3; // Updated: Added new BodyMetrics columns

  // Table names
  static const String tableBodyMetrics = 'body_metrics';
  static const String tableSegmentalAnalysis = 'segmental_analysis';
  static const String tableExercises = 'exercises';
  static const String tableWorkoutSessions = 'workout_sessions';
  static const String tableWorkoutSets = 'workout_sets';
  static const String tableWeeklyPrograms = 'weekly_programs';
  static const String tableNutritionLogs = 'nutrition_logs';
  static const String tableUserPreferences = 'user_preferences';

  // Body Metrics columns
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colWeight = 'weight';
  static const String colBmi = 'bmi';
  static const String colSkeletalMuscle = 'skeletal_muscle';
  static const String colBodyFat = 'body_fat';
  static const String colBmr = 'bmr';
  static const String colLeanBodyMass = 'lean_body_mass';
  static const String colHeight = 'height';
  static const String colWaistCircumference = 'waist_circumference';
  static const String colVisceralFat = 'visceral_fat';
  static const String colBoneMass = 'bone_mass';
  static const String colWaterPercentage = 'water_percentage';
  static const String colMetabolicAge = 'metabolic_age';
  static const String colProtein = 'protein';
  static const String colTimestamp = 'timestamp';

  // Segmental Analysis columns
  static const String colBodyMetricsId = 'body_metrics_id';
  static const String colLeftArm = 'left_arm';
  static const String colRightArm = 'right_arm';
  static const String colLeftLeg = 'left_leg';
  static const String colRightLeg = 'right_leg';
  static const String colTorso = 'torso';

  // Exercise columns
  static const String colName = 'name';
  static const String colMuscleGroup = 'muscle_group';
  static const String colSecondaryMuscles = 'secondary_muscles';
  static const String colEquipmentRequired = 'equipment_required';
  static const String colDifficulty = 'difficulty';
  static const String colVideoUrl = 'video_url';
  static const String colGifUrl = 'gif_url';
  static const String colInstructions = 'instructions';
  static const String colTempo = 'tempo';
  static const String colIsCompound = 'is_compound';
  static const String colAlternatives = 'alternatives';
  static const String colFirebaseId = 'firebase_id';
  static const String colFirebaseName = 'firebase_name';

  // Workout Session columns
  static const String colWorkoutType = 'workout_type';
  static const String colWeekNumber = 'week_number';
  static const String colStartTime = 'start_time';
  static const String colEndTime = 'end_time';
  static const String colTotalVolumeKg = 'total_volume_kg';
  static const String colRpeAverage = 'rpe_average';
  static const String colNotes = 'notes';
  static const String colCompleted = 'completed';

  // Workout Set columns
  static const String colSessionId = 'session_id';
  static const String colExerciseId = 'exercise_id';
  static const String colExerciseName = 'exercise_name';
  static const String colSetNumber = 'set_number';
  static const String colTargetReps = 'target_reps';
  static const String colActualReps = 'actual_reps';
  static const String colTargetWeight = 'target_weight';
  static const String colActualWeight = 'actual_weight';
  static const String colRpe = 'rpe';
  static const String colRestTimeSec = 'rest_time_sec';

  // Weekly Program columns
  static const String colGeneratedDate = 'generated_date';
  static const String colWorkoutsJson = 'workouts_json';
  static const String colProgressionNotes = 'progression_notes';
  static const String colIsActive = 'is_active';

  // Nutrition Log columns
  static const String colDate = 'date';
  static const String colTargetCalories = 'target_calories';
  static const String colActualCalories = 'actual_calories';
  static const String colProteinGrams = 'protein';
  static const String colCarbsGrams = 'carbs';
  static const String colFatsGrams = 'fats';
  static const String colMealsJson = 'meals_json';
  static const String colWorkoutCompleted = 'workout_completed';

  // User Preferences columns
  static const String colKey = 'key';
  static const String colValue = 'value';
  static const String colUpdatedAt = 'updated_at';

  // Common columns
  static const String colCreatedAt = 'created_at';
}
