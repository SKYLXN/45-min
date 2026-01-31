import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../data/models/meal.dart';
import '../data/models/recipe_detail.dart';
import '../data/services/spoonacular_api_service.dart';

// ============================================================================
// Service Provider
// ============================================================================

/// Singleton provider for SpoonacularApiService
final spoonacularApiServiceProvider = Provider<SpoonacularApiService>((ref) {
  try {
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('SPOONACULAR_API_KEY not found in .env file. Please check your .env configuration.');
    }
    return SpoonacularApiService(apiKey: apiKey);
  } catch (e) {
    if (e.toString().contains('NotInitializedError')) {
      throw Exception('Environment not initialized. Please restart the app.');
    }
    rethrow;
  }
});

// ============================================================================
// Filter State
// ============================================================================

/// Filters for recipe search
class RecipeFilters {
  final int? maxCalories;
  final int? minProtein;
  final int? maxCarbs;
  final int? maxFat;
  final int? maxPrepTime; // minutes
  final String? cuisine;
  final String? mealType; // breakfast, lunch, dinner, snack
  final bool excludeIngredients; // Use dietary restrictions from profile

  const RecipeFilters({
    this.maxCalories,
    this.minProtein,
    this.maxCarbs,
    this.maxFat,
    this.maxPrepTime,
    this.cuisine,
    this.mealType,
    this.excludeIngredients = true,
  });

  RecipeFilters copyWith({
    int? maxCalories,
    int? minProtein,
    int? maxCarbs,
    int? maxFat,
    int? maxPrepTime,
    String? cuisine,
    String? mealType,
    bool? excludeIngredients,
  }) {
    return RecipeFilters(
      maxCalories: maxCalories ?? this.maxCalories,
      minProtein: minProtein ?? this.minProtein,
      maxCarbs: maxCarbs ?? this.maxCarbs,
      maxFat: maxFat ?? this.maxFat,
      maxPrepTime: maxPrepTime ?? this.maxPrepTime,
      cuisine: cuisine ?? this.cuisine,
      mealType: mealType ?? this.mealType,
      excludeIngredients: excludeIngredients ?? this.excludeIngredients,
    );
  }

  bool get hasActiveFilters {
    return maxCalories != null ||
        minProtein != null ||
        maxCarbs != null ||
        maxFat != null ||
        maxPrepTime != null ||
        cuisine != null ||
        mealType != null;
  }

  void clear() {
    // Filters are immutable, use copyWith to reset
  }
}

// ============================================================================
// State Management
// ============================================================================

/// State for recipe search
class RecipeSearchState {
  final List<Meal> results;
  final RecipeFilters filters;
  final String searchQuery;
  final bool isLoading;
  final String? error;
  final bool hasSearched;
  final int? totalResults;

  const RecipeSearchState({
    this.results = const [],
    this.filters = const RecipeFilters(),
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
    this.totalResults,
  });

  RecipeSearchState copyWith({
    List<Meal>? results,
    RecipeFilters? filters,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool? hasSearched,
    int? totalResults,
  }) {
    return RecipeSearchState(
      results: results ?? this.results,
      filters: filters ?? this.filters,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasSearched: hasSearched ?? this.hasSearched,
      totalResults: totalResults ?? this.totalResults,
    );
  }
}

/// Notifier for recipe search management
class RecipeSearchNotifier extends StateNotifier<RecipeSearchState> {
  RecipeSearchNotifier(this._ref) : super(const RecipeSearchState());

  final Ref _ref;

  /// Search recipes with current query and filters
  Future<void> searchRecipes({String? query}) async {
    try {
      final searchQuery = query ?? state.searchQuery;
      
      if (searchQuery.isEmpty && !state.filters.hasActiveFilters) {
        // Don't search without query or filters
        return;
      }

      state = state.copyWith(
        isLoading: true,
        error: null,
        searchQuery: searchQuery,
      );

      final apiService = _ref.read(spoonacularApiServiceProvider);
      
      // Get user's dietary restrictions if enabled
      List<String>? excludeIngredients;
      String? diet;
      List<String>? intolerances;
      
      if (state.filters.excludeIngredients) {
        final userProfile = await _ref.read(userProfileProvider.future);
        if (userProfile != null) {
          excludeIngredients = userProfile.excludedIngredients;
          diet = userProfile.spoonacularDiet;
          // Convert comma-separated string to list
          if (userProfile.spoonacularIntolerances != null) {
            intolerances = userProfile.spoonacularIntolerances!.split(',').map((e) => e.trim()).toList();
          }
        }
      }

      final results = await apiService.searchRecipes(
        minProtein: state.filters.minProtein,
        maxCalories: state.filters.maxCalories,
        maxPrepTime: state.filters.maxPrepTime,
        excludeIngredients: excludeIngredients,
        diet: diet,
        intolerances: intolerances?.join(','),
        number: 20,
      );

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasSearched: true,
        totalResults: results.length,
      );
    } catch (e) {
      String errorMessage = 'Failed to search recipes';
      
      if (e.toString().contains('NotInitializedError')) {
        errorMessage = 'App not fully initialized. Please restart the app.';
      } else if (e.toString().contains('SPOONACULAR_API_KEY')) {
        errorMessage = 'API key not configured. Please check your .env file.';
      } else if (e.toString().contains('SocketException') || 
                 e.toString().contains('TimeoutException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Invalid API key. Please check your Spoonacular API key.';
      } else if (e.toString().contains('402')) {
        errorMessage = 'API quota exceeded. Please try again tomorrow or upgrade your plan.';
      } else {
        errorMessage = 'Search failed: ${e.toString()}';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        hasSearched: true,
      );
    }
  }

  /// Update search query
  void updateQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Update filters
  void updateFilters(RecipeFilters filters) {
    state = state.copyWith(filters: filters);
  }

  /// Clear filters
  void clearFilters() {
    state = state.copyWith(
      filters: const RecipeFilters(),
    );
  }

  /// Clear search results
  void clearResults() {
    state = state.copyWith(
      results: [],
      searchQuery: '',
      hasSearched: false,
      totalResults: null,
    );
  }

  /// Get quick meal suggestions
  Future<void> getQuickMeals({int maxPrepTime = 30}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final apiService = _ref.read(spoonacularApiServiceProvider);
      
      // Get user's dietary restrictions
      List<String>? excludeIngredients;
      String? diet;
      List<String>? intolerances;
      
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile != null) {
        excludeIngredients = userProfile.excludedIngredients;
        diet = userProfile.spoonacularDiet;
        if (userProfile.spoonacularIntolerances != null) {
          intolerances = userProfile.spoonacularIntolerances!.split(',').map((e) => e.trim()).toList();
        }
      }

      final results = await apiService.getQuickMeals(
        maxPrepTime: maxPrepTime,
        excludeIngredients: excludeIngredients,
        diet: diet,
        number: 10,
      );

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasSearched: true,
        totalResults: results.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get post-workout meal suggestions
  Future<void> getPostWorkoutMeals() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final apiService = _ref.read(spoonacularApiServiceProvider);
      
      // Get user's dietary restrictions
      List<String>? excludeIngredients;
      String? diet;
      List<String>? intolerances;
      
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile != null) {
        excludeIngredients = userProfile.excludedIngredients;
        diet = userProfile.spoonacularDiet;
        if (userProfile.spoonacularIntolerances != null) {
          intolerances = userProfile.spoonacularIntolerances!.split(',').map((e) => e.trim()).toList();
        }
      }

      final results = await apiService.getPostWorkoutMeals(
        excludeIngredients: excludeIngredients,
        diet: diet,
        number: 10,
      );

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasSearched: true,
        totalResults: results.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get high protein meal suggestions
  Future<void> getHighProteinMeals({int minProtein = 30}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final apiService = _ref.read(spoonacularApiServiceProvider);
      
      // Get user's dietary restrictions
      List<String>? excludeIngredients;
      String? diet;
      List<String>? intolerances;
      
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile != null) {
        excludeIngredients = userProfile.excludedIngredients;
        diet = userProfile.spoonacularDiet;
        if (userProfile.spoonacularIntolerances != null) {
          intolerances = userProfile.spoonacularIntolerances!.split(',').map((e) => e.trim()).toList();
        }
      }

      final results = await apiService.getHighProteinMeals(
        minProtein: minProtein,
        excludeIngredients: excludeIngredients,
        diet: diet,
        number: 10,
      );

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasSearched: true,
        totalResults: results.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main provider for recipe search state
final recipeSearchProvider =
    StateNotifierProvider<RecipeSearchNotifier, RecipeSearchState>((ref) {
  return RecipeSearchNotifier(ref);
});

/// Provider for recipe detail by ID
final recipeDetailProvider =
    FutureProvider.family<RecipeDetail?, String>((ref, recipeId) async {
  try {
    final apiService = ref.read(spoonacularApiServiceProvider);
    return await apiService.getRecipeById(int.parse(recipeId));
  } catch (e) {
    return null;
  }
});

/// Provider for searching recipes by ingredients
final recipesByIngredientsProvider =
    FutureProvider.family<List<Meal>, List<String>>((ref, ingredients) async {
  try {
    final apiService = ref.read(spoonacularApiServiceProvider);
    return await apiService.searchByIngredients(
      ingredients: ingredients,
      number: 10,
    );
  } catch (e) {
    return [];
  }
});

/// Provider to check if search has results
final hasSearchResultsProvider = Provider<bool>((ref) {
  final state = ref.watch(recipeSearchProvider);
  return state.hasSearched && state.results.isNotEmpty;
});

/// Provider to check if API key is configured
final isApiKeyConfiguredProvider = Provider<bool>((ref) {
  final apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';
  return apiKey.isNotEmpty;
});
