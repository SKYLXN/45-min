import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../models/recipe_detail.dart';
import '../models/daily_meal_plan.dart';
import '../models/nutrition_target.dart';

/// Spoonacular API service for recipe search and meal planning
/// 
/// Free tier: 150 requests/day
/// API Docs: https://spoonacular.com/food-api/docs
class SpoonacularApiService {
  final String apiKey;
  final String baseUrl = 'https://api.spoonacular.com';

  SpoonacularApiService({required this.apiKey});

  /// Search recipes by nutritional constraints
  /// 
  /// [minProtein]: Minimum protein in grams
  /// [maxCalories]: Maximum calories
  /// [maxPrepTime]: Maximum preparation time in minutes
  /// [excludeIngredients]: List of ingredients to exclude (dietary restrictions)
  /// [diet]: Diet type (e.g., 'vegetarian', 'vegan', 'ketogenic', 'paleo')
  /// [intolerances]: Comma-separated intolerances (e.g., 'dairy,gluten,egg')
  /// [cuisine]: Cuisine type (e.g., 'italian', 'asian', 'american')
  Future<List<Meal>> searchRecipes({
    int? minProtein,
    int? maxCalories,
    int? maxPrepTime,
    List<String>? excludeIngredients,
    String? diet,
    String? intolerances,
    String? cuisine,
    int number = 10,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'apiKey': apiKey,
        'number': number.toString(),
        'offset': offset.toString(),
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
        'addRecipeNutrition': 'true',
      };

      if (minProtein != null) {
        queryParams['minProtein'] = minProtein.toString();
      }
      if (maxCalories != null) {
        queryParams['maxCalories'] = maxCalories.toString();
      }
      if (maxPrepTime != null) {
        queryParams['maxReadyTime'] = maxPrepTime.toString();
      }
      if (excludeIngredients != null && excludeIngredients.isNotEmpty) {
        queryParams['excludeIngredients'] = excludeIngredients.join(',');
      }
      if (diet != null && diet.isNotEmpty) {
        queryParams['diet'] = diet;
      }
      if (intolerances != null && intolerances.isNotEmpty) {
        queryParams['intolerances'] = intolerances;
      }
      if (cuisine != null && cuisine.isNotEmpty) {
        queryParams['cuisine'] = cuisine;
      }

      final uri = Uri.parse('$baseUrl/recipes/complexSearch')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;

        return results.map((json) => _parseMealFromSearch(json)).toList();
      } else if (response.statusCode == 402) {
        throw Exception(
            'API quota exceeded. Free tier: 150 requests/day. Please try again tomorrow or upgrade your plan.');
      } else {
        throw Exception(
            'Failed to search recipes: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching recipes: $e');
    }
  }

  /// Generate a meal plan for the day
  /// 
  /// [targetCalories]: Daily calorie target
  /// [diet]: Diet preference (vegetarian, vegan, ketogenic, paleo, etc.)
  /// [excludeIngredients]: Ingredients to exclude
  /// [intolerances]: Dietary intolerances
  Future<DailyMealPlan> generateMealPlan({
    required int targetCalories,
    String? diet,
    List<String>? excludeIngredients,
    String? intolerances,
  }) async {
    try {
      final queryParams = <String, String>{
        'apiKey': apiKey,
        'timeFrame': 'day',
        'targetCalories': targetCalories.toString(),
      };

      if (diet != null && diet.isNotEmpty) {
        queryParams['diet'] = diet;
      }
      if (excludeIngredients != null && excludeIngredients.isNotEmpty) {
        queryParams['exclude'] = excludeIngredients.join(',');
      }
      if (intolerances != null && intolerances.isNotEmpty) {
        queryParams['intolerances'] = intolerances;
      }

      final uri = Uri.parse('$baseUrl/mealplanner/generate')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDailyMealPlan(data);
      } else if (response.statusCode == 402) {
        throw Exception('API quota exceeded. Please try again tomorrow.');
      } else {
        throw Exception(
            'Failed to generate meal plan: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating meal plan: $e');
    }
  }

  /// Get detailed recipe information by ID
  Future<RecipeDetail> getRecipeById(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/recipes/$id/information').replace(
        queryParameters: {
          'apiKey': apiKey,
          'includeNutrition': 'true',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseRecipeDetail(data);
      } else if (response.statusCode == 402) {
        throw Exception('API quota exceeded. Please try again tomorrow.');
      } else {
        throw Exception(
            'Failed to get recipe: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching recipe: $e');
    }
  }

  /// Search recipes by ingredients
  /// 
  /// [ingredients]: Ingredients you have available
  /// [excludeIngredients]: Ingredients to exclude
  Future<List<Meal>> searchByIngredients({
    required List<String> ingredients,
    List<String>? excludeIngredients,
    int number = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'apiKey': apiKey,
        'ingredients': ingredients.join(','),
        'number': number.toString(),
        'ranking': '2', // Maximize used ingredients
        'ignorePantry': 'true',
      };

      final uri = Uri.parse('$baseUrl/recipes/findByIngredients')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List<dynamic>;

        // Get full information for each recipe
        final meals = <Meal>[];
        for (final result in results) {
          try {
            final recipeId = result['id'] as int;
            final detail = await getRecipeById(recipeId);
            meals.add(_mealFromRecipeDetail(detail));
          } catch (e) {
            // Skip recipes that fail to load
            continue;
          }
        }

        return meals;
      } else if (response.statusCode == 402) {
        throw Exception('API quota exceeded. Please try again tomorrow.');
      } else {
        throw Exception(
            'Failed to search by ingredients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching by ingredients: $e');
    }
  }

  /// Get quick meal suggestions (< 20 minutes prep time)
  Future<List<Meal>> getQuickMeals({
    int maxPrepTime = 20,
    List<String>? excludeIngredients,
    String? diet,
    int number = 10,
  }) async {
    return searchRecipes(
      maxPrepTime: maxPrepTime,
      excludeIngredients: excludeIngredients,
      diet: diet,
      number: number,
    );
  }

  /// Get post-workout meal suggestions (high protein + carbs)
  Future<List<Meal>> getPostWorkoutMeals({
    List<String>? excludeIngredients,
    String? diet,
    int number = 10,
  }) async {
    return searchRecipes(
      minProtein: 30,
      maxCalories: 600,
      excludeIngredients: excludeIngredients,
      diet: diet,
      number: number,
    );
  }

  /// Get high protein meal suggestions
  Future<List<Meal>> getHighProteinMeals({
    int minProtein = 30,
    List<String>? excludeIngredients,
    String? diet,
    int number = 10,
  }) async {
    return searchRecipes(
      minProtein: minProtein,
      excludeIngredients: excludeIngredients,
      diet: diet,
      number: number,
    );
  }

  // Private parsing methods

  Meal _parseMealFromSearch(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] as Map<String, dynamic>?;
    final nutrients = nutrition?['nutrients'] as List<dynamic>? ?? [];

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final nutrient in nutrients) {
      final name = nutrient['name'] as String;
      final amount = (nutrient['amount'] as num).toDouble();

      switch (name) {
        case 'Calories':
          calories = amount;
          break;
        case 'Protein':
          protein = amount;
          break;
        case 'Carbohydrates':
          carbs = amount;
          break;
        case 'Fat':
          fat = amount;
          break;
      }
    }

    return Meal(
      id: json['id'].toString(),
      name: json['title'] as String,
      calories: calories.toInt(),
      macros: Macros(
        protein: protein,
        carbs: carbs,
        fats: fat,
      ),
      prepTimeMinutes: json['readyInMinutes'] as int? ?? 0,
      difficulty: 'medium', // Spoonacular doesn't provide this
      imageUrl: json['image'] as String?,
      recipeUrl: json['sourceUrl'] as String?,
      ingredients: _extractIngredients(json).map((ingredientName) => Ingredient(
        name: ingredientName,
        amount: 1,
        unit: 'unit',
      )).toList(),
      instructions: [],
      tags: [],
    );
  }

  List<String> _extractIngredients(Map<String, dynamic> json) {
    final extendedIngredients =
        json['extendedIngredients'] as List<dynamic>? ?? [];
    return extendedIngredients
        .map((i) => i['original'] as String? ?? i['name'] as String? ?? 'Unknown')
        .toList();
  }

  DailyMealPlan _parseDailyMealPlan(Map<String, dynamic> json) {
    final meals = (json['meals'] as List<dynamic>)
        .map((m) => _parseMealFromPlan(m))
        .toList();

    final nutrients = json['nutrients'] as Map<String, dynamic>;

    return DailyMealPlan(
      date: DateTime.now(),
      meals: meals,
      totalCalories: (nutrients['calories'] as num).toInt(),
      totalProtein: (nutrients['protein'] as num).toDouble(),
      totalCarbs: (nutrients['carbohydrates'] as num).toDouble(),
      totalFat: (nutrients['fat'] as num).toDouble(),
    );
  }

  Meal _parseMealFromPlan(Map<String, dynamic> json) {
    return Meal(
      id: json['id'].toString(),
      name: json['title'] as String,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      macros: Macros(
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fats: (json['fat'] as num?)?.toDouble() ?? 0,
      ),
      prepTimeMinutes: json['readyInMinutes'] as int? ?? 0,
      difficulty: 'medium',
      imageUrl: json['image'] as String?,
      recipeUrl: json['sourceUrl'] as String?,
      ingredients: [],
      instructions: [],
      tags: [],
    );
  }

  RecipeDetail _parseRecipeDetail(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] as Map<String, dynamic>?;
    final nutrients = nutrition?['nutrients'] as List<dynamic>? ?? [];

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final nutrient in nutrients) {
      final name = nutrient['name'] as String;
      final amount = (nutrient['amount'] as num).toDouble();

      switch (name) {
        case 'Calories':
          calories = amount;
          break;
        case 'Protein':
          protein = amount;
          break;
        case 'Carbohydrates':
          carbs = amount;
          break;
        case 'Fat':
          fat = amount;
          break;
      }
    }

    final instructions = <String>[];
    final analyzedInstructions =
        json['analyzedInstructions'] as List<dynamic>? ?? [];
    if (analyzedInstructions.isNotEmpty) {
      final steps =
          analyzedInstructions[0]['steps'] as List<dynamic>? ?? [];
      for (final step in steps) {
        instructions.add(step['step'] as String);
      }
    }

    return RecipeDetail(
      id: json['id'].toString(),
      name: json['title'] as String,
      imageUrl: json['image'] as String?,
      prepTime: json['readyInMinutes'] as int? ?? 0,
      servings: json['servings'] as int? ?? 1,
      calories: calories.toInt(),
      macros: Macros(
        protein: protein,
        carbs: carbs,
        fats: fat,
      ),
      ingredients: _extractIngredients(json).map((name) => Ingredient(
        name: name,
        amount: 1,
        unit: 'unit',
      )).toList(),
      instructions: instructions,
      recipeUrl: json['sourceUrl'] as String?,
      summary: json['summary'] as String?,
    );
  }

  Meal _mealFromRecipeDetail(RecipeDetail detail) {
    return Meal(
      id: detail.id,
      name: detail.name,
      calories: detail.calories,
      macros: detail.macros,
      prepTimeMinutes: detail.prepTime,
      difficulty: 'medium',
      imageUrl: detail.imageUrl,
      recipeUrl: detail.recipeUrl,
      ingredients: detail.ingredients,
      instructions: detail.instructions,
      tags: [],
      servings: detail.servings,
    );
  }
}
