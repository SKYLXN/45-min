import 'meal.dart';
import 'nutrition_target.dart';

/// Recipe detail model with full information
class RecipeDetail {
  final String id;
  final String name;
  final String? imageUrl;
  final int prepTime;
  final int servings;
  final int calories;
  final Macros macros;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final String? recipeUrl;
  final String? summary;

  const RecipeDetail({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.prepTime,
    required this.servings,
    required this.calories,
    required this.macros,
    required this.ingredients,
    required this.instructions,
    this.recipeUrl,
    this.summary,
  });

  RecipeDetail copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? prepTime,
    int? servings,
    int? calories,
    Macros? macros,
    List<Ingredient>? ingredients,
    List<String>? instructions,
    String? recipeUrl,
    String? summary,
  }) {
    return RecipeDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      prepTime: prepTime ?? this.prepTime,
      servings: servings ?? this.servings,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      recipeUrl: recipeUrl ?? this.recipeUrl,
      summary: summary ?? this.summary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'prepTime': prepTime,
      'servings': servings,
      'calories': calories,
      'macros': macros.toJson(),
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'recipeUrl': recipeUrl,
      'summary': summary,
    };
  }

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      prepTime: json['prepTime'] as int,
      servings: json['servings'] as int,
      calories: json['calories'] as int,
      macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      recipeUrl: json['recipeUrl'] as String?,
      summary: json['summary'] as String?,
    );
  }
}
