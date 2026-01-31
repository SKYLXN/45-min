import 'package:equatable/equatable.dart';
import 'meal.dart';
import 'nutrition_target.dart';

/// Logged meal entry for a specific time
class MealEntry extends Equatable {
  final String id;
  final String mealId;
  final String mealName;
  final int calories;
  final Macros macros;
  final DateTime timestamp;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final double servings; // 1.0, 1.5, 2.0, etc.

  const MealEntry({
    required this.id,
    required this.mealId,
    required this.mealName,
    required this.calories,
    required this.macros,
    required this.timestamp,
    required this.mealType,
    this.servings = 1.0,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'] as String,
      mealId: json['meal_id'] as String,
      mealName: json['meal_name'] as String,
      calories: json['calories'] as int,
      macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      mealType: json['meal_type'] as String,
      servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_id': mealId,
      'meal_name': mealName,
      'calories': calories,
      'macros': macros.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'meal_type': mealType,
      'servings': servings,
    };
  }

  /// Create meal entry from a Meal
  factory MealEntry.fromMeal({
    required String id,
    required Meal meal,
    required String mealType,
    double servings = 1.0,
  }) {
    return MealEntry(
      id: id,
      mealId: meal.id,
      mealName: meal.name,
      calories: (meal.calories * servings).round(),
      macros: Macros(
        protein: meal.macros.protein * servings,
        carbs: meal.macros.carbs * servings,
        fats: meal.macros.fats * servings,
      ),
      timestamp: DateTime.now(),
      mealType: mealType,
      servings: servings,
    );
  }

  MealEntry copyWith({
    String? id,
    String? mealId,
    String? mealName,
    int? calories,
    Macros? macros,
    DateTime? timestamp,
    String? mealType,
    double? servings,
  }) {
    return MealEntry(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      mealName: mealName ?? this.mealName,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      timestamp: timestamp ?? this.timestamp,
      mealType: mealType ?? this.mealType,
      servings: servings ?? this.servings,
    );
  }

  @override
  List<Object?> get props => [
        id,
        mealId,
        mealName,
        calories,
        macros,
        timestamp,
        mealType,
        servings,
      ];
}

/// Daily nutrition log with all meals
class DailyLog extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final List<MealEntry> meals;
  final int targetCalories;
  final Macros targetMacros;
  final bool workoutCompleted;
  final String? notes;

  const DailyLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.meals,
    required this.targetCalories,
    required this.targetMacros,
    required this.workoutCompleted,
    this.notes,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List<dynamic>)
          .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      targetCalories: json['target_calories'] as int,
      targetMacros: Macros.fromJson(json['target_macros'] as Map<String, dynamic>),
      workoutCompleted: json['workout_completed'] as bool,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'meals': meals.map((m) => m.toJson()).toList(),
      'target_calories': targetCalories,
      'target_macros': targetMacros.toJson(),
      'workout_completed': workoutCompleted,
      'notes': notes,
    };
  }

  DailyLog copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<MealEntry>? meals,
    int? targetCalories,
    Macros? targetMacros,
    bool? workoutCompleted,
    String? notes,
  }) {
    return DailyLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      targetCalories: targetCalories ?? this.targetCalories,
      targetMacros: targetMacros ?? this.targetMacros,
      workoutCompleted: workoutCompleted ?? this.workoutCompleted,
      notes: notes ?? this.notes,
    );
  }

  /// Calculate total calories consumed
  int get totalCalories {
    return meals.fold(0, (sum, meal) => sum + meal.calories);
  }

  /// Calculate total macros consumed
  Macros get totalMacros {
    return Macros(
      protein: meals.fold(0.0, (sum, meal) => sum + meal.macros.protein),
      carbs: meals.fold(0.0, (sum, meal) => sum + meal.macros.carbs),
      fats: meals.fold(0.0, (sum, meal) => sum + meal.macros.fats),
    );
  }

  /// Calculate remaining calories
  int get remainingCalories => targetCalories - totalCalories;

  /// Calculate calorie progress percentage (0-100+)
  double get calorieProgress {
    if (targetCalories == 0) return 0;
    return (totalCalories / targetCalories) * 100;
  }

  /// Calculate protein progress percentage
  double get proteinProgress {
    if (targetMacros.protein == 0) return 0;
    return (totalMacros.protein / targetMacros.protein) * 100;
  }

  /// Calculate carbs progress percentage
  double get carbsProgress {
    if (targetMacros.carbs == 0) return 0;
    return (totalMacros.carbs / targetMacros.carbs) * 100;
  }

  /// Calculate fats progress percentage
  double get fatsProgress {
    if (targetMacros.fats == 0) return 0;
    return (totalMacros.fats / targetMacros.fats) * 100;
  }

  /// Check if daily target is met
  bool get targetMet {
    return totalCalories >= targetCalories * 0.95 && 
           totalCalories <= targetCalories * 1.05;
  }

  /// Get meal count by type
  int getMealCount(String mealType) {
    return meals.where((m) => m.mealType == mealType).length;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        meals,
        targetCalories,
        targetMacros,
        workoutCompleted,
        notes,
      ];
}
