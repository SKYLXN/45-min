import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/nutrition_target.dart';
import '../models/daily_log.dart';
import '../models/meal.dart';
import '../models/weekly_meal_plan.dart';

/// Repository for nutrition-related operations
class NutritionRepository {
  final DatabaseHelper _dbHelper;

  NutritionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ============================================================================
  // Daily Log Operations
  // ============================================================================

  /// Save daily nutrition log with verification
  Future<void> saveDailyLog(DailyLog log) async {
    try {
      final data = <String, dynamic>{
        DatabaseConstants.colId: log.id,
        DatabaseConstants.colUserId: log.userId,
        DatabaseConstants.colDate: log.date.toIso8601String().split('T')[0],
        DatabaseConstants.colTargetCalories: log.targetCalories,
        DatabaseConstants.colActualCalories: log.meals.fold<int>(0, (sum, meal) => sum + meal.calories),
        DatabaseConstants.colProteinGrams: log.targetMacros.protein,
        DatabaseConstants.colCarbsGrams: log.targetMacros.carbs,
        DatabaseConstants.colFatsGrams: log.targetMacros.fats,
        DatabaseConstants.colMealsJson: jsonEncode(log.meals.map((m) => m.toJson()).toList()),
        DatabaseConstants.colWorkoutCompleted: log.workoutCompleted ? 1 : 0,
        DatabaseConstants.colNotes: log.notes,
      };

      await _dbHelper.insert(DatabaseConstants.tableNutritionLogs, data);
      print('🍽️ Saved daily nutrition log for ${log.date.toIso8601String().split('T')[0]}');
      
      // Verify save was successful
      final savedLog = await getDailyLogByDate(date: log.date, userId: log.userId);
      if (savedLog == null) {
        throw Exception('Failed to save daily log - verification failed');
      }
      print('✅ Nutrition log save verified successfully');
    } catch (e) {
      print('❌ Error saving daily nutrition log: $e');
      rethrow;
    }
  }

  /// Get daily log by date
  Future<DailyLog?> getDailyLogByDate({
    String userId = AppConstants.defaultUserId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first; // YYYY-MM-DD format
    
    final results = await _dbHelper.query(
      DatabaseConstants.tableNutritionLogs,
      where: '${DatabaseConstants.colUserId} = ? AND DATE(${DatabaseConstants.colDate}) = DATE(?)',
      whereArgs: [userId, dateStr],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _dailyLogFromMap(results.first);
  }

  /// Get today's log
  Future<DailyLog?> getTodayLog({String userId = AppConstants.defaultUserId}) async {
    return getDailyLogByDate(userId: userId, date: DateTime.now());
  }

  /// Get logs for date range
  Future<List<DailyLog>> getLogsInRange({
    String userId = AppConstants.defaultUserId,
    required DateTime start,
    required DateTime end,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableNutritionLogs,
      where: '''
        ${DatabaseConstants.colUserId} = ? AND 
        ${DatabaseConstants.colDate} >= ? AND 
        ${DatabaseConstants.colDate} <= ?
      ''',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: '${DatabaseConstants.colDate} DESC',
    );

    return results.map(_dailyLogFromMap).toList();
  }

  /// Get recent logs
  Future<List<DailyLog>> getRecentLogs({
    String userId = AppConstants.defaultUserId,
    int days = 7,
  }) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return getLogsInRange(userId: userId, start: start, end: end);
  }

  /// Update daily log
  Future<void> updateDailyLog(DailyLog log) async {
    final data = <String, dynamic>{
      DatabaseConstants.colUserId: log.userId,
      DatabaseConstants.colDate: log.date.toIso8601String().split('T')[0],
      DatabaseConstants.colTargetCalories: log.targetCalories,
      DatabaseConstants.colActualCalories: log.meals.fold<int>(0, (sum, meal) => sum + meal.calories),
      DatabaseConstants.colProteinGrams: log.targetMacros.protein,
      DatabaseConstants.colCarbsGrams: log.targetMacros.carbs,
      DatabaseConstants.colFatsGrams: log.targetMacros.fats,
      DatabaseConstants.colMealsJson: jsonEncode(log.meals.map((m) => m.toJson()).toList()),
      DatabaseConstants.colWorkoutCompleted: log.workoutCompleted ? 1 : 0,
      DatabaseConstants.colNotes: log.notes,
    };

    await _dbHelper.update(
      DatabaseConstants.tableNutritionLogs,
      data,
      '${DatabaseConstants.colId} = ?',
      [log.id],
    );
  }

  /// Delete daily log
  Future<void> deleteDailyLog(String id) async {
    await _dbHelper.deleteById(DatabaseConstants.tableNutritionLogs, id);
  }

  // ============================================================================
  // Nutrition Target Operations (User Preferences)
  // ============================================================================

  /// Save nutrition target to preferences
  Future<void> saveNutritionTarget(NutritionTarget target) async {
    await _dbHelper.insert(
      DatabaseConstants.tableUserPreferences,
      {
        DatabaseConstants.colKey: 'nutrition_target',
        DatabaseConstants.colValue: jsonEncode(target.toJson()),
        DatabaseConstants.colUpdatedAt: DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get nutrition target from preferences
  Future<NutritionTarget?> getNutritionTarget() async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableUserPreferences,
      where: '${DatabaseConstants.colKey} = ?',
      whereArgs: ['nutrition_target'],
      limit: 1,
    );

    if (results.isEmpty) return null;
    
    final jsonData = jsonDecode(results.first[DatabaseConstants.colValue] as String);
    return NutritionTarget.fromJson(jsonData as Map<String, dynamic>);
  }

  /// Check if target needs recalculation (based on validUntil)
  Future<bool> needsTargetRecalculation() async {
    final target = await getNutritionTarget();
    if (target == null) return true;
    return !target.isValid;
  }

  // ============================================================================
  // Statistics & Analytics
  // ============================================================================

  /// Get average daily calories over period
  Future<double?> getAverageDailyCalories({
    String userId = 'default',
    required DateTime start,
    required DateTime end,
  }) async {
    final sql = '''
      SELECT AVG(${DatabaseConstants.colActualCalories}) as average
      FROM ${DatabaseConstants.tableNutritionLogs}
      WHERE ${DatabaseConstants.colUserId} = ?
        AND ${DatabaseConstants.colDate} >= ?
        AND ${DatabaseConstants.colDate} <= ?
    ''';

    final results = await _dbHelper.rawQuery(
      sql,
      [userId, start.toIso8601String(), end.toIso8601String()],
    );

    if (results.isEmpty || results.first['average'] == null) return null;
    return (results.first['average'] as num).toDouble();
  }

  /// Get average macros over period
  Future<Macros?> getAverageMacros({
    String userId = 'default',
    required DateTime start,
    required DateTime end,
  }) async {
    final sql = '''
      SELECT 
        AVG(${DatabaseConstants.colProteinGrams}) as avg_protein,
        AVG(${DatabaseConstants.colCarbsGrams}) as avg_carbs,
        AVG(${DatabaseConstants.colFatsGrams}) as avg_fats
      FROM ${DatabaseConstants.tableNutritionLogs}
      WHERE ${DatabaseConstants.colUserId} = ?
        AND ${DatabaseConstants.colDate} >= ?
        AND ${DatabaseConstants.colDate} <= ?
    ''';

    final results = await _dbHelper.rawQuery(
      sql,
      [userId, start.toIso8601String(), end.toIso8601String()],
    );

    if (results.isEmpty) return null;
    final row = results.first;
    
    if (row['avg_protein'] == null) return null;

    return Macros(
      protein: (row['avg_protein'] as num).toDouble(),
      carbs: (row['avg_carbs'] as num).toDouble(),
      fats: (row['avg_fats'] as num).toDouble(),
    );
  }

  /// Get adherence rate (% of days meeting targets)
  Future<double> getAdherenceRate({
    String userId = 'default',
    required DateTime start,
    required DateTime end,
  }) async {
    final logs = await getLogsInRange(userId: userId, start: start, end: end);
    if (logs.isEmpty) return 0.0;

    final metTarget = logs.where((log) => log.targetMet).length;
    return (metTarget / logs.length) * 100;
  }

  /// Get workout correlation (days with workouts)
  Future<int> getWorkoutDaysCount({
    String userId = 'default',
    required DateTime start,
    required DateTime end,
  }) async {
    final count = await _dbHelper.getCount(
      DatabaseConstants.tableNutritionLogs,
      where: '''
        ${DatabaseConstants.colUserId} = ? AND 
        ${DatabaseConstants.colDate} >= ? AND 
        ${DatabaseConstants.colDate} <= ? AND
        ${DatabaseConstants.colWorkoutCompleted} = 1
      ''',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
    );
    return count ?? 0;
  }

  /// Get total logged days
  Future<int> getLoggedDaysCount({
    String userId = 'default',
    required DateTime start,
    required DateTime end,
  }) async {
    final count = await _dbHelper.getCount(
      DatabaseConstants.tableNutritionLogs,
      where: '''
        ${DatabaseConstants.colUserId} = ? AND 
        ${DatabaseConstants.colDate} >= ? AND 
        ${DatabaseConstants.colDate} <= ?
      ''',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
    );
    return count ?? 0;
  }

  /// Get macro trends (protein, carbs, fats over time)
  Future<List<Map<String, dynamic>>> getMacroTrends({
    String userId = 'default',
    required DateTime start,
    required DateTime end,
  }) async {
    final logs = await getLogsInRange(userId: userId, start: start, end: end);
    
    return logs.map((log) {
      return {
        'date': log.date,
        'protein': log.totalMacros.protein,
        'carbs': log.totalMacros.carbs,
        'fats': log.totalMacros.fats,
        'calories': log.totalCalories,
      };
    }).toList();
  }

  // ============================================================================
  // Recipe/Meal Search (External API - placeholder for integration)
  // ============================================================================

  /// Search recipes (to be implemented with API integration)
  Future<List<Meal>> searchRecipes(Map<String, dynamic> filters) async {
    // Placeholder: This will be implemented with Spoonacular API
    // For now, return empty list
    return [];
  }

  /// Get recipe by ID (to be implemented with API integration)
  Future<Meal?> getRecipeById(String id) async {
    // Placeholder: This will be implemented with Spoonacular API
    return null;
  }

  // ============================================================================
  // Favorite Recipes Operations
  // ============================================================================

  /// Save recipe to favorites
  Future<void> saveFavoriteRecipe({
    required String recipeId,
    required String recipeName,
    String? imageUrl,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    int? prepTime,
    String? recipeUrl,
    String? notes,
    String userId = 'default',
  }) async {
    final data = {
      'id': 'fav_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId,
      'recipe_id': recipeId,
      'recipe_name': recipeName,
      'image_url': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'prep_time': prepTime,
      'recipe_url': recipeUrl,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _dbHelper.insert('favorite_recipes', data);
  }

  /// Get all favorite recipes
  Future<List<Map<String, dynamic>>> getFavoriteRecipes({
    String userId = 'default',
  }) async {
    final results = await _dbHelper.query(
      'favorite_recipes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return results;
  }

  /// Check if recipe is favorited
  Future<bool> isFavoriteRecipe({
    required String recipeId,
    String userId = 'default',
  }) async {
    final count = await _dbHelper.getCount(
      'favorite_recipes',
      where: 'user_id = ? AND recipe_id = ?',
      whereArgs: [userId, recipeId],
    );

    return (count ?? 0) > 0;
  }

  /// Remove recipe from favorites
  Future<void> removeFavoriteRecipe({
    required String recipeId,
    String userId = 'default',
  }) async {
    await _dbHelper.delete(
      'favorite_recipes',
      'user_id = ? AND recipe_id = ?',
      [userId, recipeId],
    );
  }

  /// Get favorite recipes count
  Future<int> getFavoriteRecipesCount({
    String userId = 'default',
  }) async {
    final count = await _dbHelper.getCount(
      'favorite_recipes',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return count ?? 0;
  }

  /// Search favorite recipes
  Future<List<Map<String, dynamic>>> searchFavoriteRecipes({
    required String query,
    String userId = 'default',
  }) async {
    final results = await _dbHelper.query(
      'favorite_recipes',
      where: 'user_id = ? AND (recipe_name LIKE ? OR notes LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );

    return results;
  }

  // ============================================================================
  // Cached Recipes Operations
  // ============================================================================

  /// Save recipe to cache
  Future<void> cacheRecipe({
    required String recipeId,
    required String recipeData,
    int cacheDurationHours = 24,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: cacheDurationHours));

    final data = {
      'recipe_id': recipeId,
      'recipe_data': recipeData,
      'cached_at': now.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };

    // Use replace to update if already exists
    final db = await _dbHelper.database;
    await db.insert('cached_recipes', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get cached recipe
  Future<String?> getCachedRecipe(String recipeId) async {
    final results = await _dbHelper.query(
      'cached_recipes',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final cached = results.first;
    final expiresAt = DateTime.parse(cached['expires_at'] as String);

    // Check if cache is still valid
    if (DateTime.now().isAfter(expiresAt)) {
      // Cache expired, delete it
      await _dbHelper.delete(
        'cached_recipes',
        'recipe_id = ?',
        [recipeId],
      );
      return null;
    }

    return cached['recipe_data'] as String;
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    final now = DateTime.now().toIso8601String();
    await _dbHelper.delete(
      'cached_recipes',
      'expires_at < ?',
      [now],
    );
  }

  /// Clear all cached recipes
  Future<void> clearAllCache() async {
    await _dbHelper.delete('cached_recipes', '1=1', []);
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    final count = await _dbHelper.getCount('cached_recipes');
    return count ?? 0;
  }

  // ============================================================================
  // Meal Plans Operations
  // ============================================================================

  /// Save meal plan
  Future<void> saveMealPlan({
    required DateTime date,
    required List<Map<String, dynamic>> meals,
    required int totalCalories,
    required int totalProtein,
    required int totalCarbs,
    required int totalFat,
    String userId = 'default',
  }) async {
    final data = {
      'id': 'plan_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId,
      'date': date.toIso8601String().split('T').first, // YYYY-MM-DD format
      'meals_json': jsonEncode(meals),
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'generated_at': DateTime.now().toIso8601String(),
    };

    // Use replace to update if plan already exists for this date
    final db = await _dbHelper.database;
    await db.insert('meal_plans', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get meal plan by date
  Future<Map<String, dynamic>?> getMealPlan({
    required DateTime date,
    String userId = 'default',
  }) async {
    final dateStr = date.toIso8601String().split('T').first;

    final results = await _dbHelper.query(
      'meal_plans',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, dateStr],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final plan = results.first;
    // Decode meals JSON
    plan['meals'] = jsonDecode(plan['meals_json'] as String);
    plan.remove('meals_json');

    return plan;
  }

  /// Get meal plans for date range
  Future<List<Map<String, dynamic>>> getMealPlansInRange({
    required DateTime start,
    required DateTime end,
    String userId = 'default',
  }) async {
    final startStr = start.toIso8601String().split('T').first;
    final endStr = end.toIso8601String().split('T').first;

    final results = await _dbHelper.query(
      'meal_plans',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startStr, endStr],
      orderBy: 'date ASC',
    );

    return results.map((plan) {
      plan['meals'] = jsonDecode(plan['meals_json'] as String);
      plan.remove('meals_json');
      return plan;
    }).toList();
  }

  /// Check if meal plan exists for date
  Future<bool> hasMealPlanForDate({
    required DateTime date,
    String userId = 'default',
  }) async {
    final dateStr = date.toIso8601String().split('T').first;

    final count = await _dbHelper.getCount(
      'meal_plans',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, dateStr],
    );

    return (count ?? 0) > 0;
  }

  /// Delete meal plan
  Future<void> deleteMealPlan({
    required DateTime date,
    String userId = 'default',
  }) async {
    final dateStr = date.toIso8601String().split('T').first;

    await _dbHelper.delete(
      'meal_plans',
      'user_id = ? AND date = ?',
      [userId, dateStr],
    );
  }

  /// Get all saved meal plans count
  Future<int> getMealPlansCount({
    String userId = 'default',
  }) async {
    final count = await _dbHelper.getCount(
      'meal_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return count ?? 0;
  }

  /// Clear old meal plans (older than specified days)
  Future<void> clearOldMealPlans({
    int olderThanDays = 30,
    String userId = 'default',
  }) async {
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: olderThanDays))
        .toIso8601String()
        .split('T')
        .first;

    await _dbHelper.delete(
      'meal_plans',
      'user_id = ? AND date < ?',
      [userId, cutoffDate],
    );
  }

  // ============================================================================
  // Weekly Meal Plan Operations
  // ============================================================================

  /// Save weekly meal plan
  Future<void> saveWeeklyMealPlan(WeeklyMealPlan plan) async {
    final data = {
      'id': plan.id,
      'user_id': 'default',
      'start_date': plan.startDate.toIso8601String().split('T').first,
      'end_date': plan.endDate.toIso8601String().split('T').first,
      'daily_plans_json': jsonEncode(plan.toJson()['daily_plans']),
      'total_meals': plan.totalMeals,
      'weekly_calories': plan.weeklyCalories,
      'weekly_protein': plan.weeklyProtein,
      'weekly_carbs': plan.weeklyCarbs,
      'weekly_fat': plan.weeklyFat,
      'created_at': plan.createdAt.toIso8601String(),
      'last_modified': plan.lastModified?.toIso8601String(),
    };

    await _dbHelper.insert('weekly_meal_plans', data);
  }

  /// Get weekly meal plan by ID
  Future<WeeklyMealPlan?> getWeeklyMealPlan(String planId) async {
    final results = await _dbHelper.query(
      'weekly_meal_plans',
      where: 'id = ?',
      whereArgs: [planId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _weeklyMealPlanFromMap(results.first);
  }

  /// Get all weekly meal plans
  Future<List<WeeklyMealPlan>> getWeeklyMealPlans({String userId = 'default'}) async {
    final results = await _dbHelper.query(
      'weekly_meal_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_date DESC',
    );

    return results.map(_weeklyMealPlanFromMap).toList();
  }

  /// Get current weekly meal plan (covers today's date)
  Future<WeeklyMealPlan?> getCurrentWeeklyMealPlan({String userId = 'default'}) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    
    final results = await _dbHelper.query(
      'weekly_meal_plans',
      where: 'user_id = ? AND start_date <= ? AND end_date >= ?',
      whereArgs: [userId, today, today],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _weeklyMealPlanFromMap(results.first);
  }

  /// Delete weekly meal plan
  Future<void> deleteWeeklyMealPlan(String planId) async {
    await _dbHelper.delete(
      'weekly_meal_plans',
      'id = ?',
      [planId],
    );
  }

  /// Clear all weekly meal plans
  Future<void> clearAllWeeklyMealPlans({String userId = 'default'}) async {
    await _dbHelper.delete(
      'weekly_meal_plans',
      'user_id = ?',
      [userId],
    );
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  DailyLog _dailyLogFromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    
    // Decode meals JSON
    final mealsJson = jsonDecode(map[DatabaseConstants.colMealsJson] as String) as List;
    data['meals'] = mealsJson;
    
    // Build target macros from individual columns
    data['target_macros'] = {
      'protein': map[DatabaseConstants.colProteinGrams] ?? 0.0,
      'carbs': map[DatabaseConstants.colCarbsGrams] ?? 0.0,
      'fats': map[DatabaseConstants.colFatsGrams] ?? 0.0,
    };
    
    // Convert integer to boolean
    data[DatabaseConstants.colWorkoutCompleted] = 
        map[DatabaseConstants.colWorkoutCompleted] == 1;

    return DailyLog.fromJson(data);
  }

  WeeklyMealPlan _weeklyMealPlanFromMap(Map<String, dynamic> map) {
    final jsonData = {
      'id': map['id'],
      'start_date': map['start_date'],
      'end_date': map['end_date'],
      'daily_plans': jsonDecode(map['daily_plans_json'] as String),
      'created_at': map['created_at'],
      'last_modified': map['last_modified'],
      'total_meals': map['total_meals'],
      'weekly_calories': map['weekly_calories'],
      'weekly_protein': map['weekly_protein'],
      'weekly_carbs': map['weekly_carbs'],
      'weekly_fat': map['weekly_fat'],
    };

    return WeeklyMealPlan.fromJson(jsonData);
  }
}

// Provider for NutritionRepository
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository();
});
