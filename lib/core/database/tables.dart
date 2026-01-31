import 'database_constants.dart';

/// SQL table creation statements
class DatabaseTables {
  DatabaseTables._();

  /// Body metrics table - stores body composition data from PDF or manual entry
  static const String createBodyMetricsTable = '''
    CREATE TABLE ${DatabaseConstants.tableBodyMetrics} (
      ${DatabaseConstants.colId} TEXT PRIMARY KEY,
      ${DatabaseConstants.colUserId} TEXT NOT NULL,
      ${DatabaseConstants.colWeight} REAL NOT NULL,
      ${DatabaseConstants.colBmi} REAL NOT NULL,
      ${DatabaseConstants.colSkeletalMuscle} REAL NOT NULL,
      ${DatabaseConstants.colBodyFat} REAL NOT NULL,
      ${DatabaseConstants.colBmr} INTEGER NOT NULL,
      ${DatabaseConstants.colLeanBodyMass} REAL,
      ${DatabaseConstants.colHeight} REAL,
      ${DatabaseConstants.colWaistCircumference} REAL,
      ${DatabaseConstants.colVisceralFat} INTEGER,
      ${DatabaseConstants.colBoneMass} REAL,
      ${DatabaseConstants.colWaterPercentage} REAL,
      ${DatabaseConstants.colMetabolicAge} INTEGER,
      ${DatabaseConstants.colProtein} REAL,
      ${DatabaseConstants.colTimestamp} TEXT NOT NULL,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Segmental analysis table - left/right limb muscle distribution
  static const String createSegmentalAnalysisTable = '''
    CREATE TABLE ${DatabaseConstants.tableSegmentalAnalysis} (
      ${DatabaseConstants.colId} TEXT PRIMARY KEY,
      ${DatabaseConstants.colBodyMetricsId} TEXT NOT NULL,
      ${DatabaseConstants.colLeftArm} REAL NOT NULL,
      ${DatabaseConstants.colRightArm} REAL NOT NULL,
      ${DatabaseConstants.colLeftLeg} REAL NOT NULL,
      ${DatabaseConstants.colRightLeg} REAL NOT NULL,
      ${DatabaseConstants.colTorso} REAL NOT NULL,
      ${DatabaseConstants.colTimestamp} TEXT NOT NULL,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (${DatabaseConstants.colBodyMetricsId}) 
        REFERENCES ${DatabaseConstants.tableBodyMetrics}(${DatabaseConstants.colId})
        ON DELETE CASCADE
    )
  ''';

  /// Exercises table - master exercise library
  static const String createExercisesTable = '''
    CREATE TABLE ${DatabaseConstants.tableExercises} (
      ${DatabaseConstants.colId} TEXT PRIMARY KEY,
      ${DatabaseConstants.colName} TEXT NOT NULL,
      ${DatabaseConstants.colMuscleGroup} TEXT NOT NULL,
      ${DatabaseConstants.colSecondaryMuscles} TEXT NOT NULL,
      ${DatabaseConstants.colEquipmentRequired} TEXT NOT NULL,
      ${DatabaseConstants.colDifficulty} TEXT NOT NULL,
      ${DatabaseConstants.colVideoUrl} TEXT,
      ${DatabaseConstants.colGifUrl} TEXT,
      ${DatabaseConstants.colInstructions} TEXT NOT NULL,
      ${DatabaseConstants.colTempo} TEXT NOT NULL,
      ${DatabaseConstants.colIsCompound} INTEGER NOT NULL,
      ${DatabaseConstants.colAlternatives} TEXT NOT NULL,
      ${DatabaseConstants.colFirebaseId} TEXT,
      ${DatabaseConstants.colFirebaseName} TEXT,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Workout sessions table - completed workout records
  static const String createWorkoutSessionsTable = '''
    CREATE TABLE ${DatabaseConstants.tableWorkoutSessions} (
      ${DatabaseConstants.colId} TEXT PRIMARY KEY,
      ${DatabaseConstants.colUserId} TEXT NOT NULL,
      ${DatabaseConstants.colWorkoutType} TEXT NOT NULL,
      ${DatabaseConstants.colWeekNumber} INTEGER NOT NULL,
      ${DatabaseConstants.colStartTime} TEXT,
      ${DatabaseConstants.colEndTime} TEXT,
      ${DatabaseConstants.colTotalVolumeKg} REAL NOT NULL,
      ${DatabaseConstants.colRpeAverage} REAL,
      ${DatabaseConstants.colNotes} TEXT,
      ${DatabaseConstants.colCompleted} INTEGER NOT NULL,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Workout sets table - individual set records within sessions
  static const String createWorkoutSetsTable = '''
    CREATE TABLE ${DatabaseConstants.tableWorkoutSets} (
      ${DatabaseConstants.colId} TEXT PRIMARY KEY,
      ${DatabaseConstants.colSessionId} TEXT NOT NULL,
      ${DatabaseConstants.colExerciseId} TEXT NOT NULL,
      ${DatabaseConstants.colExerciseName} TEXT NOT NULL,
      ${DatabaseConstants.colSetNumber} INTEGER NOT NULL,
      ${DatabaseConstants.colTargetReps} INTEGER NOT NULL,
      ${DatabaseConstants.colActualReps} INTEGER NOT NULL,
      ${DatabaseConstants.colTargetWeight} REAL NOT NULL,
      ${DatabaseConstants.colActualWeight} REAL NOT NULL,
      ${DatabaseConstants.colRpe} INTEGER NOT NULL,
      ${DatabaseConstants.colRestTimeSec} INTEGER NOT NULL,
      ${DatabaseConstants.colTimestamp} TEXT NOT NULL,
      ${DatabaseConstants.colNotes} TEXT,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (${DatabaseConstants.colSessionId}) 
        REFERENCES ${DatabaseConstants.tableWorkoutSessions}(${DatabaseConstants.colId})
        ON DELETE CASCADE,
      FOREIGN KEY (${DatabaseConstants.colExerciseId}) 
        REFERENCES ${DatabaseConstants.tableExercises}(${DatabaseConstants.colId})
    )
  ''';

  /// Weekly programs table - generated workout plans
  static const String createWeeklyProgramsTable = '''
    CREATE TABLE ${DatabaseConstants.tableWeeklyPrograms} (
      ${DatabaseConstants.colId} TEXT PRIMARY KEY,
      ${DatabaseConstants.colUserId} TEXT NOT NULL,
      ${DatabaseConstants.colWeekNumber} INTEGER NOT NULL,
      ${DatabaseConstants.colGeneratedDate} TEXT NOT NULL,
      ${DatabaseConstants.colWorkoutsJson} TEXT NOT NULL,
      ${DatabaseConstants.colProgressionNotes} TEXT,
      ${DatabaseConstants.colIsActive} INTEGER NOT NULL,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Nutrition logs table - daily food tracking
  static const String createNutritionLogsTable = '''
    CREATE TABLE ${DatabaseConstants.tableNutritionLogs} (
      ${DatabaseConstants.colId} TEXT PRIMARY KEY,
      ${DatabaseConstants.colUserId} TEXT NOT NULL,
      ${DatabaseConstants.colDate} TEXT NOT NULL,
      ${DatabaseConstants.colTargetCalories} INTEGER NOT NULL,
      ${DatabaseConstants.colActualCalories} INTEGER NOT NULL,
      ${DatabaseConstants.colProteinGrams} REAL NOT NULL,
      ${DatabaseConstants.colCarbsGrams} REAL NOT NULL,
      ${DatabaseConstants.colFatsGrams} REAL NOT NULL,
      ${DatabaseConstants.colMealsJson} TEXT NOT NULL,
      ${DatabaseConstants.colWorkoutCompleted} INTEGER NOT NULL,
      ${DatabaseConstants.colNotes} TEXT,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// User preferences table - key-value store for settings
  static const String createUserPreferencesTable = '''
    CREATE TABLE ${DatabaseConstants.tableUserPreferences} (
      ${DatabaseConstants.colKey} TEXT PRIMARY KEY,
      ${DatabaseConstants.colValue} TEXT NOT NULL,
      ${DatabaseConstants.colUpdatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Favorite recipes table - user's saved favorite recipes
  static const String createFavoriteRecipesTable = '''
    CREATE TABLE favorite_recipes (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'default',
      recipe_id TEXT NOT NULL,
      recipe_name TEXT NOT NULL,
      image_url TEXT,
      calories INTEGER NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fats REAL NOT NULL,
      prep_time INTEGER,
      recipe_url TEXT,
      notes TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id, recipe_id)
    )
  ''';

  /// Cached recipes table - offline recipe cache with expiration
  static const String createCachedRecipesTable = '''
    CREATE TABLE cached_recipes (
      recipe_id TEXT PRIMARY KEY,
      recipe_data TEXT NOT NULL,
      cached_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expires_at TEXT NOT NULL
    )
  ''';

  /// Meal plans table - saved meal plans by date
  static const String createMealPlansTable = '''
    CREATE TABLE meal_plans (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'default',
      date TEXT NOT NULL,
      meals_json TEXT NOT NULL,
      total_calories INTEGER NOT NULL,
      total_protein INTEGER NOT NULL,
      total_carbs INTEGER NOT NULL,
      total_fat INTEGER NOT NULL,
      generated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id, date)
    )
  ''';

  /// Weekly meal plans table - weekly plans (2 meals/day × 7 days)
  static const String createWeeklyMealPlansTable = '''
    CREATE TABLE weekly_meal_plans (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'default',
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      daily_plans_json TEXT NOT NULL,
      total_meals INTEGER NOT NULL,
      weekly_calories REAL NOT NULL,
      weekly_protein REAL NOT NULL,
      weekly_carbs REAL NOT NULL,
      weekly_fat REAL NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      last_modified TEXT,
      UNIQUE(user_id, start_date)
    )
  ''';

  /// Create indexes for frequently queried columns
  static const List<String> createIndexes = [
    // Body metrics indexes
    '''CREATE INDEX idx_body_metrics_user_timestamp 
       ON ${DatabaseConstants.tableBodyMetrics}(${DatabaseConstants.colUserId}, ${DatabaseConstants.colTimestamp})''',
    
    // Workout sessions indexes
    '''CREATE INDEX idx_workout_sessions_user_week 
       ON ${DatabaseConstants.tableWorkoutSessions}(${DatabaseConstants.colUserId}, ${DatabaseConstants.colWeekNumber})''',
    
    '''CREATE INDEX idx_workout_sessions_user_type 
       ON ${DatabaseConstants.tableWorkoutSessions}(${DatabaseConstants.colUserId}, ${DatabaseConstants.colWorkoutType})''',
    
    // Workout sets indexes
    '''CREATE INDEX idx_workout_sets_session 
       ON ${DatabaseConstants.tableWorkoutSets}(${DatabaseConstants.colSessionId})''',
    
    '''CREATE INDEX idx_workout_sets_exercise 
       ON ${DatabaseConstants.tableWorkoutSets}(${DatabaseConstants.colExerciseId})''',
    
    // Exercises indexes
    '''CREATE INDEX idx_exercises_muscle_group 
       ON ${DatabaseConstants.tableExercises}(${DatabaseConstants.colMuscleGroup})''',
    
    // Weekly programs indexes
    '''CREATE INDEX idx_weekly_programs_user_active 
       ON ${DatabaseConstants.tableWeeklyPrograms}(${DatabaseConstants.colUserId}, ${DatabaseConstants.colIsActive})''',
    
    // Nutrition logs indexes
    '''CREATE INDEX idx_nutrition_logs_user_date 
       ON ${DatabaseConstants.tableNutritionLogs}(${DatabaseConstants.colUserId}, ${DatabaseConstants.colDate})''',
    
    // Favorite recipes indexes
    '''CREATE INDEX idx_favorite_recipes_user 
       ON favorite_recipes(user_id)''',
    
    // Cached recipes indexes
    '''CREATE INDEX idx_cached_recipes_expires 
       ON cached_recipes(expires_at)''',
    
    // Meal plans indexes
    '''CREATE INDEX idx_meal_plans_user_date 
       ON meal_plans(user_id, date)''',
    
    // Weekly meal plans indexes
    '''CREATE INDEX idx_weekly_meal_plans_user 
       ON weekly_meal_plans(user_id)''',
    
    '''CREATE INDEX idx_weekly_meal_plans_dates 
       ON weekly_meal_plans(start_date, end_date)''',
  ];

  /// Get all table creation statements in order
  static List<String> get allTableCreationStatements => [
        createBodyMetricsTable,
        createSegmentalAnalysisTable,
        createExercisesTable,
        createWorkoutSessionsTable,
        createWorkoutSetsTable,
        createWeeklyProgramsTable,
        createNutritionLogsTable,
        createUserPreferencesTable,
        createFavoriteRecipesTable,
        createCachedRecipesTable,
        createMealPlansTable,
        createWeeklyMealPlansTable,
      ];
}
