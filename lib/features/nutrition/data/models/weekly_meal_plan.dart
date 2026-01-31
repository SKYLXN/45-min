import 'daily_meal_plan.dart';
import 'meal.dart';

/// Weekly meal plan model (2 meals per day × 7 days = 14 meals)
class WeeklyMealPlan {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, DayMealPlan> dailyPlans; // Map of date to day plan
  final DateTime createdAt;
  final DateTime? lastModified;
  final int totalMeals;
  final double weeklyCalories;
  final double weeklyProtein;
  final double weeklyCarbs;
  final double weeklyFat;

  const WeeklyMealPlan({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.dailyPlans,
    required this.createdAt,
    this.lastModified,
    required this.totalMeals,
    required this.weeklyCalories,
    required this.weeklyProtein,
    required this.weeklyCarbs,
    required this.weeklyFat,
  });

  /// Create a weekly plan with 2 meals per day
  factory WeeklyMealPlan.create({
    required DateTime startDate,
    required Map<DateTime, DayMealPlan> dailyPlans,
  }) {
    final endDate = startDate.add(const Duration(days: 6));
    
    // Calculate totals
    int totalMeals = 0;
    double weeklyCalories = 0;
    double weeklyProtein = 0;
    double weeklyCarbs = 0;
    double weeklyFat = 0;

    for (final dayPlan in dailyPlans.values) {
      totalMeals += dayPlan.meals.length;
      weeklyCalories += dayPlan.totalCalories;
      weeklyProtein += dayPlan.totalProtein;
      weeklyCarbs += dayPlan.totalCarbs;
      weeklyFat += dayPlan.totalFat;
    }

    return WeeklyMealPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: startDate,
      endDate: endDate,
      dailyPlans: dailyPlans,
      createdAt: DateTime.now(),
      totalMeals: totalMeals,
      weeklyCalories: weeklyCalories,
      weeklyProtein: weeklyProtein,
      weeklyCarbs: weeklyCarbs,
      weeklyFat: weeklyFat,
    );
  }

  WeeklyMealPlan copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    Map<DateTime, DayMealPlan>? dailyPlans,
    DateTime? createdAt,
    DateTime? lastModified,
    int? totalMeals,
    double? weeklyCalories,
    double? weeklyProtein,
    double? weeklyCarbs,
    double? weeklyFat,
  }) {
    return WeeklyMealPlan(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyPlans: dailyPlans ?? this.dailyPlans,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      totalMeals: totalMeals ?? this.totalMeals,
      weeklyCalories: weeklyCalories ?? this.weeklyCalories,
      weeklyProtein: weeklyProtein ?? this.weeklyProtein,
      weeklyCarbs: weeklyCarbs ?? this.weeklyCarbs,
      weeklyFat: weeklyFat ?? this.weeklyFat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'daily_plans': dailyPlans.map((date, plan) => MapEntry(
        date.toIso8601String(),
        plan.toJson(),
      )),
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'total_meals': totalMeals,
      'weekly_calories': weeklyCalories,
      'weekly_protein': weeklyProtein,
      'weekly_carbs': weeklyCarbs,
      'weekly_fat': weeklyFat,
    };
  }

  factory WeeklyMealPlan.fromJson(Map<String, dynamic> json) {
    final dailyPlansMap = json['daily_plans'] as Map<String, dynamic>;
    final dailyPlans = dailyPlansMap.map((dateStr, planJson) => MapEntry(
      DateTime.parse(dateStr),
      DayMealPlan.fromJson(planJson as Map<String, dynamic>),
    ));

    return WeeklyMealPlan(
      id: json['id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      dailyPlans: dailyPlans,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastModified: json['last_modified'] != null 
          ? DateTime.parse(json['last_modified'] as String)
          : null,
      totalMeals: json['total_meals'] as int,
      weeklyCalories: (json['weekly_calories'] as num).toDouble(),
      weeklyProtein: (json['weekly_protein'] as num).toDouble(),
      weeklyCarbs: (json['weekly_carbs'] as num).toDouble(),
      weeklyFat: (json['weekly_fat'] as num).toDouble(),
    );
  }

  /// Get all unique ingredients across the week for shopping list
  List<Ingredient> getAllIngredients() {
    final allIngredients = <Ingredient>[];
    
    for (final dayPlan in dailyPlans.values) {
      for (final meal in dayPlan.meals) {
        allIngredients.addAll(meal.ingredients);
      }
    }
    
    return allIngredients;
  }

  /// Get aggregated shopping list (combining duplicate ingredients)
  Map<String, AggregatedIngredient> getShoppingList() {
    final shoppingMap = <String, AggregatedIngredient>{};
    
    for (final ingredient in getAllIngredients()) {
      final key = ingredient.name.toLowerCase();
      
      if (shoppingMap.containsKey(key)) {
        shoppingMap[key] = shoppingMap[key]!.add(ingredient);
      } else {
        shoppingMap[key] = AggregatedIngredient(
          name: ingredient.name,
          totalAmount: ingredient.amount,
          unit: ingredient.unit,
          count: 1,
        );
      }
    }
    
    return shoppingMap;
  }

  /// Get meals for a specific day
  DayMealPlan? getMealPlanForDay(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return dailyPlans[dateKey];
  }

  /// Get all dates in the weekly plan
  List<DateTime> getAllDates() {
    return List.generate(7, (index) => startDate.add(Duration(days: index)));
  }

  /// Average daily calories
  double get averageDailyCalories => weeklyCalories / 7;

  /// Average daily protein
  double get averageDailyProtein => weeklyProtein / 7;

  /// Check if plan is current (start date is within this week)
  bool get isCurrent {
    final now = DateTime.now();
    return startDate.isBefore(now) && endDate.isAfter(now);
  }
}

/// Daily meal plan for weekly planning (2 meals per day)
class DayMealPlan {
  final DateTime date;
  final Meal meal1; // Main meal (e.g., lunch)
  final Meal meal2; // Second meal (e.g., dinner)
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String? notes;

  const DayMealPlan({
    required this.date,
    required this.meal1,
    required this.meal2,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.notes,
  });

  /// Create from two meals
  factory DayMealPlan.fromMeals({
    required DateTime date,
    required Meal meal1,
    required Meal meal2,
    String? notes,
  }) {
    return DayMealPlan(
      date: date,
      meal1: meal1,
      meal2: meal2,
      totalCalories: meal1.calories + meal2.calories,
      totalProtein: meal1.macros.protein + meal2.macros.protein,
      totalCarbs: meal1.macros.carbs + meal2.macros.carbs,
        totalFat: meal1.macros.fats + meal2.macros.fats,
      notes: notes,
    );
  }

  List<Meal> get meals => [meal1, meal2];

  DayMealPlan copyWith({
    DateTime? date,
    Meal? meal1,
    Meal? meal2,
    int? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    String? notes,
  }) {
    return DayMealPlan(
      date: date ?? this.date,
      meal1: meal1 ?? this.meal1,
      meal2: meal2 ?? this.meal2,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'meal1': meal1.toJson(),
      'meal2': meal2.toJson(),
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'notes': notes,
    };
  }

  factory DayMealPlan.fromJson(Map<String, dynamic> json) {
    return DayMealPlan(
      date: DateTime.parse(json['date'] as String),
      meal1: Meal.fromJson(json['meal1'] as Map<String, dynamic>),
      meal2: Meal.fromJson(json['meal2'] as Map<String, dynamic>),
      totalCalories: json['total_calories'] as int,
      totalProtein: (json['total_protein'] as num).toDouble(),
      totalCarbs: (json['total_carbs'] as num).toDouble(),
      totalFat: (json['total_fat'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// Aggregated ingredient for shopping list
class AggregatedIngredient {
  final String name;
  final double totalAmount;
  final String unit;
  final int count; // Number of recipes using this ingredient

  const AggregatedIngredient({
    required this.name,
    required this.totalAmount,
    required this.unit,
    required this.count,
  });

  /// Add another ingredient to this one
  AggregatedIngredient add(Ingredient ingredient) {
    // Simple addition - assumes same unit
    // In production, you'd want unit conversion
    return AggregatedIngredient(
      name: name,
      totalAmount: totalAmount + ingredient.amount,
      unit: unit,
      count: count + 1,
    );
  }

  AggregatedIngredient copyWith({
    String? name,
    double? totalAmount,
    String? unit,
    int? count,
  }) {
    return AggregatedIngredient(
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      unit: unit ?? this.unit,
      count: count ?? this.count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'total_amount': totalAmount,
      'unit': unit,
      'count': count,
    };
  }

  factory AggregatedIngredient.fromJson(Map<String, dynamic> json) {
    return AggregatedIngredient(
      name: json['name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      unit: json['unit'] as String,
      count: json['count'] as int,
    );
  }

  /// Format for display (e.g., "2.5 cups")
  String get displayText => '${totalAmount.toStringAsFixed(1)} $unit';
}
