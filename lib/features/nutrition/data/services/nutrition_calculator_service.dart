import '../../../../core/models/body_metrics.dart';
import '../models/nutrition_target.dart';
import 'package:uuid/uuid.dart';

/// Nutrition calculator service for BMR-based meal planning
/// 
/// Calculates personalized nutrition targets based on body metrics,
/// activity level, and fitness goals
class NutritionCalculatorService {
  final _uuid = const Uuid();
  
  /// Calculate daily calorie target
  /// 
  /// Formula:
  /// - Maintenance: BMR × Activity Factor
  /// - Muscle Gain: Maintenance + 300-500 cal
  /// - Fat Loss: Maintenance - 300-500 cal
  /// 
  /// Activity factors:
  /// - Sedentary (little/no exercise): 1.2
  /// - Lightly active (1-3 days/week): 1.375
  /// - Moderately active (3-5 days/week): 1.55
  /// - Very active (6-7 days/week): 1.725
  /// - Extremely active (athlete): 1.9
  int calculateDailyCalories({
    required double bmr,
    required String goal, // 'muscle_gain', 'fat_loss', 'maintenance'
    required String activityLevel, // 'sedentary', 'light', 'moderate', 'very_active', 'athlete'
    bool isWorkoutDay = false,
  }) {
    // Get activity factor
    double activityFactor = _getActivityFactor(activityLevel);
    
    // Calculate maintenance calories
    double maintenance = bmr * activityFactor;
    
    // Adjust for goal
    double targetCalories = maintenance;
    
    switch (goal.toLowerCase()) {
      case 'muscle_gain':
      case 'bulk':
        targetCalories = maintenance + 400; // +400 cal for muscle gain
        break;
      case 'fat_loss':
      case 'cut':
        targetCalories = maintenance - 400; // -400 cal for fat loss
        break;
      case 'maintenance':
      case 'recomp':
        targetCalories = maintenance; // Maintain current weight
        break;
    }
    
    // Add extra calories on workout days (for muscle gain/maintenance)
    if (isWorkoutDay && goal != 'fat_loss') {
      targetCalories += 100; // +100 cal on workout days
    }
    
    return targetCalories.round();
  }
  
  /// Calculate macro split based on goal
  /// 
  /// Hypertrophy (Muscle Gain):
  /// - Protein: 40% (2.2g/kg bodyweight minimum)
  /// - Carbs: 35%
  /// - Fats: 25%
  /// 
  /// Fat Loss:
  /// - Protein: 45% (high to preserve muscle)
  /// - Carbs: 25%
  /// - Fats: 30%
  /// 
  /// Maintenance:
  /// - Protein: 35%
  /// - Carbs: 40%
  /// - Fats: 25%
  NutritionTarget calculateMacros({
    required int calories,
    required double weight, // in kg
    required String goal,
    bool isWorkoutDay = false,
  }) {
    double proteinGrams;
    double carbsGrams;
    double fatsGrams;
    
    switch (goal.toLowerCase()) {
      case 'muscle_gain':
      case 'bulk':
        // High protein for muscle synthesis
        proteinGrams = weight * 2.2; // 2.2g/kg bodyweight
        final proteinCalories = proteinGrams * 4;
        
        // Remaining calories split 60/40 between carbs and fats
        final remainingCalories = calories - proteinCalories;
        carbsGrams = (remainingCalories * 0.6) / 4; // 60% carbs
        fatsGrams = (remainingCalories * 0.4) / 9; // 40% fats
        break;
        
      case 'fat_loss':
      case 'cut':
        // Very high protein to preserve muscle
        proteinGrams = weight * 2.4; // 2.4g/kg bodyweight
        final proteinCalories = proteinGrams * 4;
        
        // Lower carbs, moderate fats
        final remainingCalories = calories - proteinCalories;
        carbsGrams = (remainingCalories * 0.4) / 4; // 40% carbs
        fatsGrams = (remainingCalories * 0.6) / 9; // 60% fats
        break;
        
      case 'maintenance':
      case 'recomp':
      default:
        // Balanced macros
        proteinGrams = weight * 2.0; // 2.0g/kg bodyweight
        final proteinCalories = proteinGrams * 4;
        
        final remainingCalories = calories - proteinCalories;
        carbsGrams = (remainingCalories * 0.55) / 4; // 55% carbs
        fatsGrams = (remainingCalories * 0.45) / 9; // 45% fats
        break;
    }
    
    // Adjust carbs on workout days (carb cycling)
    if (isWorkoutDay) {
      carbsGrams += 30; // +30g carbs on workout days
      fatsGrams -= 10; // -10g fats to compensate
    }
    
    return NutritionTarget(
      id: _uuid.v4(),
      userId: '', // Will be set by caller
      dailyCalories: calories,
      macros: Macros(
        protein: proteinGrams.round().toDouble(),
        carbs: carbsGrams.round().toDouble(),
        fats: fatsGrams.round().toDouble(),
      ),
      bmr: 0, // Will be set by caller if needed
      isWorkoutDay: isWorkoutDay,
      createdAt: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: 1)),
    );
  }
  
  /// Calculate nutrition target from body metrics
  NutritionTarget calculateFromBodyMetrics({
    required BodyMetrics metrics,
    required String goal,
    required String activityLevel,
    bool isWorkoutDay = false,
  }) {
    final calories = calculateDailyCalories(
      bmr: metrics.bmr.toDouble(),
      goal: goal,
      activityLevel: activityLevel,
      isWorkoutDay: isWorkoutDay,
    );
    
    return calculateMacros(
      calories: calories,
      weight: metrics.weight,
      goal: goal,
      isWorkoutDay: isWorkoutDay,
    );
  }
  
  /// Detect if today is a workout day (helper method)
  /// 
  /// Call this with WorkoutRepository to auto-adjust calories
  Future<bool> isWorkoutDay(DateTime date) async {
    // TODO: Integrate with WorkoutRepository
    // Check if there's a planned or completed workout for today
    return false; // Placeholder
  }
  
  /// Calculate post-workout meal macros
  /// 
  /// Post-workout window (30-60 min after training):
  /// - High carbs (replenish glycogen)
  /// - Moderate-high protein (muscle repair)
  /// - Low fat (speeds digestion)
  NutritionTarget calculatePostWorkoutMeal({
    required double weight,
  }) {
    final proteinGrams = weight * 0.4; // 0.4g/kg
    final carbsGrams = weight * 0.8; // 0.8g/kg
    final fatsGrams = 5.0; // Minimal fat
    
    final calories = (proteinGrams * 4 + carbsGrams * 4 + fatsGrams * 9).round();
    
    return NutritionTarget(
      id: _uuid.v4(),
      userId: '', // Will be set by caller
      dailyCalories: calories,
      macros: Macros(
        protein: proteinGrams.round().toDouble(),
        carbs: carbsGrams.round().toDouble(),
        fats: fatsGrams.round().toDouble(),
      ),
      bmr: 0,
      isWorkoutDay: false,
      createdAt: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(hours: 2)),
    );
  }
  
  /// Calculate pre-workout meal macros
  /// 
  /// Pre-workout (1-2 hours before training):
  /// - Moderate carbs (energy)
  /// - Moderate protein
  /// - Low fat (avoid sluggishness)
  NutritionTarget calculatePreWorkoutMeal({
    required double weight,
  }) {
    final proteinGrams = weight * 0.3; // 0.3g/kg
    final carbsGrams = weight * 0.6; // 0.6g/kg
    final fatsGrams = 8.0; // Low fat
    
    final calories = (proteinGrams * 4 + carbsGrams * 4 + fatsGrams * 9).round();
    
    return NutritionTarget(
      id: _uuid.v4(),
      userId: '', // Will be set by caller
      dailyCalories: calories,
      macros: Macros(
        protein: proteinGrams.round().toDouble(),
        carbs: carbsGrams.round().toDouble(),
        fats: fatsGrams.round().toDouble(),
      ),
      bmr: 0,
      isWorkoutDay: false,
      createdAt: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(hours: 2)),
    );
  }
  
  /// Get meal timing recommendations
  Map<String, String> getMealTimingRecommendations({
    required String goal,
    bool hasWorkoutToday = false,
  }) {
    if (hasWorkoutToday) {
      return {
        'pre_workout': '1-2 hours before training',
        'post_workout': '30-60 minutes after training',
        'breakfast': 'Within 1 hour of waking',
        'lunch': '4-5 hours after breakfast',
        'dinner': '3-4 hours before bed',
        'note': 'Time your biggest carb meal around your workout',
      };
    }
    
    return {
      'breakfast': 'Within 1 hour of waking',
      'lunch': '4-5 hours after breakfast',
      'snack': 'Mid-afternoon if needed',
      'dinner': '3-4 hours before bed',
      'note': 'Spread protein evenly across meals (30-40g per meal)',
    };
  }
  
  /// Get dietary recommendations based on goal
  List<String> getDietaryRecommendations(String goal) {
    switch (goal.toLowerCase()) {
      case 'muscle_gain':
      case 'bulk':
        return [
          'Prioritize whole foods over supplements',
          'Eat every 3-4 hours (5-6 meals/day)',
          'Include complex carbs with each meal',
          'Consume 30-40g protein per meal',
          'Stay hydrated (3-4L water/day)',
          'Don\'t skip post-workout nutrition',
        ];
        
      case 'fat_loss':
      case 'cut':
        return [
          'Prioritize protein to preserve muscle',
          'Include vegetables with every meal',
          'Time carbs around workouts',
          'Avoid liquid calories',
          'Track portion sizes carefully',
          'Eat slower, practice mindful eating',
        ];
        
      case 'maintenance':
      case 'recomp':
      default:
        return [
          'Maintain consistent meal timing',
          'Focus on whole, nutrient-dense foods',
          'Balance macros across the day',
          'Listen to hunger cues',
          'Stay hydrated',
          'Adjust based on energy levels',
        ];
    }
  }
  
  // Private helper methods
  
  double _getActivityFactor(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2;
      case 'light':
      case 'lightly_active':
        return 1.375;
      case 'moderate':
      case 'moderately_active':
        return 1.55;
      case 'very_active':
      case 'very':
        return 1.725;
      case 'athlete':
      case 'extremely_active':
        return 1.9;
      default:
        return 1.55; // Default to moderate
    }
  }
  
  /// Validate nutrition target (ensure minimum protein intake)
  bool validateNutritionTarget(NutritionTarget target, double weight) {
    // Minimum protein: 1.6g/kg bodyweight
    final minProtein = weight * 1.6;
    
    if (target.macros.protein < minProtein) {
      return false;
    }
    
    // Minimum calories: 1200 for women, 1500 for men (general guideline)
    if (target.dailyCalories < 1200) {
      return false;
    }
    
    return true;
  }
  
  /// Get protein quality recommendations
  List<String> getProteinSources() {
    return [
      'Chicken breast (lean)',
      'Turkey breast',
      'Lean beef (90/10)',
      'Fish (salmon, tuna, tilapia)',
      'Eggs and egg whites',
      'Greek yogurt',
      'Cottage cheese',
      'Protein powder (whey/plant-based)',
      'Tofu and tempeh',
      'Legumes (lentils, chickpeas)',
    ];
  }
  
  /// Get carb sources based on goal
  List<String> getCarbSources(String goal) {
    if (goal == 'fat_loss') {
      return [
        'Sweet potato',
        'Oatmeal',
        'Quinoa',
        'Brown rice',
        'Vegetables (broccoli, spinach)',
        'Berries',
        'Beans and lentils',
      ];
    }
    
    return [
      'Rice (white/brown)',
      'Pasta',
      'Bread',
      'Oatmeal',
      'Potatoes',
      'Sweet potato',
      'Fruits (banana, apple)',
      'Quinoa',
    ];
  }
  
  /// Get healthy fat sources
  List<String> getFatSources() {
    return [
      'Avocado',
      'Olive oil',
      'Nuts (almonds, walnuts)',
      'Nut butter',
      'Fatty fish (salmon)',
      'Eggs',
      'Chia seeds',
      'Flaxseeds',
      'Dark chocolate (85%+)',
    ];
  }
}
