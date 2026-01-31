/// App-wide constants
class AppConstants {
  AppConstants._();

  // Workout Constants
  static const int defaultRestTimeSec = 90;
  static const int maxRestTimeSec = 300;
  static const int minRestTimeSec = 30;
  static const int workoutDurationMin = 45;
  
  // Progressive Overload
  static const double weightIncrementKg = 2.0;
  static const int repsIncrement = 2;
  static const double easyThresholdRPE = 7.0;
  static const double hardThresholdRPE = 9.0;
  
  // Body Metrics
  static const double minHealthyBodyFat = 10.0;
  static const double maxHealthyBodyFat = 20.0;
  static const double targetBodyFatPercentage = 12.0;
  
  // Equipment Ranges
  static const double minDumbbellWeightKg = 2.0;
  static const double maxDumbbellWeightKg = 40.0;
  
  // API Keys (Should be moved to .env in production)
  static const String spoonacularApiKey = 'YOUR_SPOONACULAR_API_KEY';
  static const String edamamApiKey = 'YOUR_EDAMAM_API_KEY';
  static const String edamamAppId = 'YOUR_EDAMAM_APP_ID';
  
  // Database
  static const String dbName = 'fortyfivemin.db';
  static const int dbVersion = 1;
  
  // User Management
  static const String defaultUserId = 'user_id'; // TODO: Replace with proper user management
  
  // Shared Preferences Keys
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyUserProfile = 'user_profile';
  static const String keyEquipment = 'user_equipment';
  static const String keyCurrentWeek = 'current_week';
  
  // Muscle Groups
  static const List<String> muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Abs',
    'Legs',
  ];
  
  // Exercise Tempos
  static const String hypertrophyTempo = '3-0-1-0';
  static const String strengthTempo = '2-1-X-0';
  static const String enduranceTempo = '1-0-1-0';
}
