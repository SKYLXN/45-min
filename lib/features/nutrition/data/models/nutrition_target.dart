import 'package:equatable/equatable.dart';

/// Macronutrient information
class Macros extends Equatable {
  final double protein; // grams
  final double carbs; // grams
  final double fats; // grams

  const Macros({
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory Macros.fromJson(Map<String, dynamic> json) {
    return Macros(
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  Macros copyWith({
    double? protein,
    double? carbs,
    double? fats,
  }) {
    return Macros(
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
    );
  }

  /// Calculate total calories (4-4-9 rule)
  int get totalCalories {
    return ((protein * 4) + (carbs * 4) + (fats * 9)).round();
  }

  /// Get protein percentage
  double get proteinPercent {
    final total = totalCalories;
    if (total == 0) return 0;
    return (protein * 4 / total) * 100;
  }

  /// Get carbs percentage
  double get carbsPercent {
    final total = totalCalories;
    if (total == 0) return 0;
    return (carbs * 4 / total) * 100;
  }

  /// Get fats percentage
  double get fatsPercent {
    final total = totalCalories;
    if (total == 0) return 0;
    return (fats * 9 / total) * 100;
  }

  @override
  List<Object?> get props => [protein, carbs, fats];
}

/// Daily nutrition targets based on BMR and activity
class NutritionTarget extends Equatable {
  final String id;
  final String userId;
  final int dailyCalories;
  final Macros macros;
  final int bmr; // Base Metabolic Rate
  final bool isWorkoutDay;
  final DateTime createdAt;
  final DateTime validUntil; // Targets should be recalculated periodically

  const NutritionTarget({
    required this.id,
    required this.userId,
    required this.dailyCalories,
    required this.macros,
    required this.bmr,
    required this.isWorkoutDay,
    required this.createdAt,
    required this.validUntil,
  });

  factory NutritionTarget.fromJson(Map<String, dynamic> json) {
    return NutritionTarget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dailyCalories: json['daily_calories'] as int,
      macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
      bmr: json['bmr'] as int,
      isWorkoutDay: json['is_workout_day'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'daily_calories': dailyCalories,
      'macros': macros.toJson(),
      'bmr': bmr,
      'is_workout_day': isWorkoutDay,
      'created_at': createdAt.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
    };
  }

  NutritionTarget copyWith({
    String? id,
    String? userId,
    int? dailyCalories,
    Macros? macros,
    int? bmr,
    bool? isWorkoutDay,
    DateTime? createdAt,
    DateTime? validUntil,
  }) {
    return NutritionTarget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      macros: macros ?? this.macros,
      bmr: bmr ?? this.bmr,
      isWorkoutDay: isWorkoutDay ?? this.isWorkoutDay,
      createdAt: createdAt ?? this.createdAt,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  /// Check if target is still valid
  bool get isValid => DateTime.now().isBefore(validUntil);

  /// Calculate surplus/deficit from BMR
  int get calorieAdjustment => dailyCalories - bmr;

  @override
  List<Object?> get props => [
        id,
        userId,
        dailyCalories,
        macros,
        bmr,
        isWorkoutDay,
        createdAt,
        validUntil,
      ];
}
