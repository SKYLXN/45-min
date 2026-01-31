import 'meal.dart';

/// Daily meal plan model
class DailyMealPlan {
  final DateTime date;
  final List<Meal> meals;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const DailyMealPlan({
    required this.date,
    required this.meals,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  DailyMealPlan copyWith({
    DateTime? date,
    List<Meal>? meals,
    int? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
  }) {
    return DailyMealPlan(
      date: date ?? this.date,
      meals: meals ?? this.meals,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'meals': meals.map((m) => m.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
    };
  }

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) {
    return DailyMealPlan(
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List<dynamic>)
          .map((m) => Meal.fromJson(m as Map<String, dynamic>))
          .toList(),
      totalCalories: json['totalCalories'] as int,
      totalProtein: (json['totalProtein'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
    );
  }

  /// Get breakfast meals
  List<Meal> get breakfastMeals =>
      meals.where((m) => m.prepTimeMinutes <= 20).take(1).toList();

  /// Get lunch meals
  List<Meal> get lunchMeals =>
      meals.skip(breakfastMeals.length).take(1).toList();

  /// Get dinner meals
  List<Meal> get dinnerMeals =>
      meals.skip(breakfastMeals.length + lunchMeals.length).toList();
}
