import 'package:equatable/equatable.dart';
import 'nutrition_target.dart';

/// Ingredient in a recipe
class Ingredient extends Equatable {
  final String name;
  final double amount;
  final String unit; // 'g', 'ml', 'cup', 'tbsp', etc.

  const Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
    };
  }

  @override
  List<Object?> get props => [name, amount, unit];
}

/// Meal/Recipe with nutritional information
class Meal extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final int calories;
  final Macros macros;
  final int prepTimeMinutes;
  final String difficulty; // 'easy', 'medium', 'hard'
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final String? recipeUrl; // External link to full recipe
  final List<String> tags; // 'post-workout', 'high-protein', 'quick', etc.
  final int? servings;
  final String? cuisine;

  const Meal({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.calories,
    required this.macros,
    required this.prepTimeMinutes,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    this.recipeUrl,
    required this.tags,
    this.servings,
    this.cuisine,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      calories: json['calories'] as int,
      macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
      prepTimeMinutes: json['prep_time_minutes'] as int,
      difficulty: json['difficulty'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      recipeUrl: json['recipe_url'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      servings: json['servings'] as int?,
      cuisine: json['cuisine'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'calories': calories,
      'macros': macros.toJson(),
      'prep_time_minutes': prepTimeMinutes,
      'difficulty': difficulty,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'recipe_url': recipeUrl,
      'tags': tags,
      'servings': servings,
      'cuisine': cuisine,
    };
  }

  Meal copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? calories,
    Macros? macros,
    int? prepTimeMinutes,
    String? difficulty,
    List<Ingredient>? ingredients,
    List<String>? instructions,
    String? recipeUrl,
    List<String>? tags,
    int? servings,
    String? cuisine,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      difficulty: difficulty ?? this.difficulty,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      recipeUrl: recipeUrl ?? this.recipeUrl,
      tags: tags ?? this.tags,
      servings: servings ?? this.servings,
      cuisine: cuisine ?? this.cuisine,
    );
  }

  /// Check if meal is suitable for post-workout
  bool get isPostWorkout => tags.contains('post-workout');

  /// Check if meal is high in protein
  bool get isHighProtein => macros.proteinPercent >= 30;

  /// Check if meal is quick to prepare (< 20 min)
  bool get isQuick => prepTimeMinutes < 20;

  /// Calculate calories per serving
  int? get caloriesPerServing {
    if (servings == null || servings == 0) return null;
    return (calories / servings!).round();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        calories,
        macros,
        prepTimeMinutes,
        difficulty,
        ingredients,
        instructions,
        recipeUrl,
        tags,
        servings,
        cuisine,
      ];
}
