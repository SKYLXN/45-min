import '../models/nutrition_target.dart';
import '../../../smart_planner/data/models/weekly_program.dart';
import '../../providers/nutrition_target_provider.dart';
import 'nutrition_calculator_service.dart';

/// Service for integrating nutrition with workout planning
class NutritionIntegrationService {
  final NutritionCalculatorService _calculatorService;

  NutritionIntegrationService(this._calculatorService);

  /// Adjust nutrition targets based on weekly program
  /// 
  /// Higher intensity workouts require more carbs and overall calories
  NutritionTarget adjustForWeeklyProgram({
    required NutritionTarget baseTarget,
    required WeeklyProgram program,
    required DateTime date,
  }) {
    // Find today's workout in the program
    final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    PlannedWorkout? todaysWorkout;

    for (final workout in program.workouts) {
      // Check if this workout is scheduled for today
      // Assuming workout.weekday is set (we'd need to add this to the model)
      // For now, we'll use a simple pattern: Workout A on Mon/Thu, Workout B on Tue/Fri
      if (_isWorkoutScheduledForDay(workout, dayOfWeek)) {
        todaysWorkout = workout;
        break;
      }
    }

    // If no workout today, return base target
    if (todaysWorkout == null) {
      return baseTarget;
    }

    // Calculate intensity score based on workout
    final intensityScore = _calculateWorkoutIntensity(todaysWorkout);

    // Adjust macros based on intensity
    // High intensity = more carbs, moderate protein increase
    final calorieAdjustment = (baseTarget.dailyCalories * intensityScore * 0.15).round();
    final proteinAdjustment = (baseTarget.macros.protein * intensityScore * 0.05).round();
    final carbAdjustment = (baseTarget.macros.carbs * intensityScore * 0.20).round();
    final fatAdjustment = (baseTarget.macros.fats * intensityScore * 0.05).round();

    return NutritionTarget(
      id: baseTarget.id,
      userId: baseTarget.userId,
      dailyCalories: baseTarget.dailyCalories + calorieAdjustment,
      macros: Macros(
        protein: baseTarget.macros.protein + proteinAdjustment,
        carbs: baseTarget.macros.carbs + carbAdjustment,
        fats: baseTarget.macros.fats + fatAdjustment,
      ),
      bmr: baseTarget.bmr,
      isWorkoutDay: baseTarget.isWorkoutDay,
      createdAt: baseTarget.createdAt,
      validUntil: baseTarget.validUntil,
    );
  }

  /// Calculate workout intensity score (0.0 to 1.0)
  double _calculateWorkoutIntensity(PlannedWorkout workout) {
    // Factors:
    // 1. Number of exercises (more = higher intensity)
    // 2. Number of compound exercises (compounds are more demanding)
    // 3. Average target RPE

    final exerciseCount = workout.exercises.length;
    final compoundCount = workout.exercises.where((e) => e.exercise.isCompound).length;
    final avgTargetRPE = workout.exercises.fold(0.0, (sum, e) => sum + e.targetRPE) / exerciseCount;

    // Normalize each factor
    final exerciseScore = (exerciseCount / 8).clamp(0.0, 1.0); // 8 exercises = full intensity
    final compoundScore = (compoundCount / exerciseCount).clamp(0.0, 1.0); // 100% compound = full score
    final rpeScore = (avgTargetRPE / 9.0).clamp(0.0, 1.0); // RPE 9 = full intensity

    // Weighted average
    return (exerciseScore * 0.3) + (compoundScore * 0.3) + (rpeScore * 0.4);
  }

  /// Check if workout is scheduled for a specific day
  bool _isWorkoutScheduledForDay(PlannedWorkout workout, int dayOfWeek) {
    // Simple pattern: Workout A on Mon (1) and Thu (4), Workout B on Tue (2) and Fri (5)
    // This is a placeholder - in a real app, you'd store scheduled days in the workout
    
    if (workout.workoutType.contains('A')) {
      return dayOfWeek == 1 || dayOfWeek == 4; // Monday or Thursday
    } else if (workout.workoutType.contains('B')) {
      return dayOfWeek == 2 || dayOfWeek == 5; // Tuesday or Friday
    }

    return false;
  }

  /// Get recommended meal timing around workout
  Map<String, String> getMealTimingRecommendations({
    required DateTime workoutTime,
    required NutritionTarget dailyTarget,
  }) {
    final recommendations = <String, String>{};

    // Pre-workout meal (1-2 hours before)
    final preWorkoutTime = workoutTime.subtract(const Duration(hours: 1, minutes: 30));
    recommendations['pre_workout'] = 
        '${_formatTime(preWorkoutTime)}: Pre-workout meal (${(dailyTarget.macros.carbs * 0.25).round()}g carbs, light protein)';

    // Intra-workout (optional for longer sessions)
    if (workoutTime.hour >= 17) { // Evening workout
      recommendations['intra_workout'] = 'During workout: Stay hydrated, optional BCAAs';
    }

    // Post-workout meal (30-60 min after)
    final postWorkoutTime = workoutTime.add(const Duration(minutes: 45));
    recommendations['post_workout'] = 
        '${_formatTime(postWorkoutTime)}: Post-workout meal (${(dailyTarget.macros.carbs * 0.30).round()}g carbs, ${(dailyTarget.macros.protein * 0.35).round()}g protein)';

    return recommendations;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Calculate nutrition adjustments for recovery days
  NutritionTarget adjustForRecovery({
    required NutritionTarget baseTarget,
    required double recoveryScore,
  }) {
    // Low recovery = reduce calories slightly to avoid overfeeding during low activity
    // But maintain protein to support recovery

    if (recoveryScore >= 70) {
      // Good recovery - normal targets
      return baseTarget;
    } else if (recoveryScore >= 50) {
      // Moderate recovery - slight calorie reduction, maintain protein
      return NutritionTarget(
        id: baseTarget.id,
        userId: baseTarget.userId,
        dailyCalories: (baseTarget.dailyCalories * 0.95).round(),
        macros: Macros(
          protein: baseTarget.macros.protein, // Keep protein high
          carbs: baseTarget.macros.carbs * 0.90,
          fats: baseTarget.macros.fats,
        ),
        bmr: baseTarget.bmr,
        isWorkoutDay: baseTarget.isWorkoutDay,
        createdAt: baseTarget.createdAt,
        validUntil: baseTarget.validUntil,
      );
    } else {
      // Poor recovery - reduce calories, prioritize protein
      return NutritionTarget(
        id: baseTarget.id,
        userId: baseTarget.userId,
        dailyCalories: (baseTarget.dailyCalories * 0.90).round(),
        macros: Macros(
          protein: baseTarget.macros.protein * 1.05, // Slight protein increase for recovery
          carbs: baseTarget.macros.carbs * 0.80,
          fats: baseTarget.macros.fats,
        ),
        bmr: baseTarget.bmr,
        isWorkoutDay: baseTarget.isWorkoutDay,
        createdAt: baseTarget.createdAt,
        validUntil: baseTarget.validUntil,
      );
    }
  }
}
