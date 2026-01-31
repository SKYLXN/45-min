import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/recipe_search_provider.dart';
import '../../providers/dietary_profile_provider.dart';
import '../widgets/recipe_card.dart';

/// Recipe Search Screen - Search recipes with API integration
class RecipeSearchScreen extends ConsumerStatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  ConsumerState<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends ConsumerState<RecipeSearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Pagination removed - API returns full result set
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(recipeSearchProvider);
    final hasActiveRestrictions = ref.watch(hasActiveRestrictionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Recipe Search'),
        backgroundColor: AppColors.cardBackground,
        actions: [
          // Dietary restrictions indicator
          if (hasActiveRestrictions)
            IconButton(
              icon: Badge(
                child: Icon(Icons.filter_list),
              ),
              onPressed: () => context.push('/nutrition/dietary-restrictions'),
              tooltip: 'Dietary Restrictions Active',
            )
          else
            IconButton(
              icon: Icon(Icons.filter_list_off),
              onPressed: () => context.push('/nutrition/dietary-restrictions'),
              tooltip: 'Set Dietary Restrictions',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBackground,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(recipeSearchProvider.notifier).clearResults();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (query) {
                    if (query.isNotEmpty) {
                      ref.read(recipeSearchProvider.notifier).updateQuery(query);
                      ref.read(recipeSearchProvider.notifier).searchRecipes();
                    }
                  },
                  onChanged: (query) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 12),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Max Prep Time',
                        isActive: searchState.filters.maxPrepTime != null,
                        onTap: () => _showPrepTimeDialog(),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Max Calories',
                        isActive: searchState.filters.maxCalories != null,
                        onTap: () => _showCaloriesDialog(),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Min Protein',
                        isActive: searchState.filters.minProtein != null,
                        onTap: () => _showProteinDialog(),
                      ),
                      const SizedBox(width: 8),
                      if (searchState.filters.hasActiveFilters)
                        TextButton.icon(
                          onPressed: () =>
                              ref.read(recipeSearchProvider.notifier).clearFilters(),
                          icon: Icon(Icons.clear_all, size: 16),
                          label: Text('Clear'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: searchState.isLoading && searchState.results.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : searchState.error != null
                    ? _buildErrorState(searchState.error!)
                    : searchState.results.isEmpty
                        ? _buildEmptyState()
                        : _buildResultsGrid(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryGreen.withOpacity(0.2)
              : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primaryGreen
                : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primaryGreen : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 14,
                color: AppColors.primaryGreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsGrid(RecipeSearchState searchState) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final recipe = searchState.results[index];
        return RecipeCard(
          recipeId: recipe.id,
          title: recipe.name,
          imageUrl: recipe.imageUrl,
          calories: recipe.calories,
          prepTime: recipe.prepTimeMinutes,
          onTap: () => context.push('/recipe-detail/${recipe.id}'),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for recipes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for "chicken", "pasta", or your favorite meal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Search failed',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  ref.read(recipeSearchProvider.notifier).updateQuery(_searchController.text);
                  ref.read(recipeSearchProvider.notifier).searchRecipes();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrepTimeDialog() {
    final currentValue = ref.read(recipeSearchProvider).filters.maxPrepTime;
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        title: 'Max Prep Time',
        currentValue: currentValue,
        unit: 'minutes',
        options: [15, 30, 45, 60, 90],
        onSelected: (value) {
          ref.read(recipeSearchProvider.notifier).updateFilters(
            ref.read(recipeSearchProvider).filters.copyWith(maxPrepTime: value),
          );
          if (_searchController.text.isNotEmpty) {
            ref.read(recipeSearchProvider.notifier).updateQuery(_searchController.text);
            ref.read(recipeSearchProvider.notifier).searchRecipes();
          }
        },
      ),
    );
  }

  void _showCaloriesDialog() {
    final currentValue = ref.read(recipeSearchProvider).filters.maxCalories;
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        title: 'Max Calories',
        currentValue: currentValue,
        unit: 'kcal',
        options: [200, 300, 400, 500, 600, 800],
        onSelected: (value) {
          ref.read(recipeSearchProvider.notifier).updateFilters(
            ref.read(recipeSearchProvider).filters.copyWith(maxCalories: value),
          );
          if (_searchController.text.isNotEmpty) {
            ref.read(recipeSearchProvider.notifier).updateQuery(_searchController.text);
            ref.read(recipeSearchProvider.notifier).searchRecipes();
          }
        },
      ),
    );
  }

  void _showProteinDialog() {
    final currentValue = ref.read(recipeSearchProvider).filters.minProtein;
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        title: 'Min Protein',
        currentValue: currentValue,
        unit: 'g',
        options: [10, 20, 30, 40, 50],
        onSelected: (value) {
          ref.read(recipeSearchProvider.notifier).updateFilters(
            ref.read(recipeSearchProvider).filters.copyWith(minProtein: value),
          );
          if (_searchController.text.isNotEmpty) {
            ref.read(recipeSearchProvider.notifier).updateQuery(_searchController.text);
            ref.read(recipeSearchProvider.notifier).searchRecipes();
          }
        },
      ),
    );
  }
}

class _FilterDialog extends StatelessWidget {
  final String title;
  final int? currentValue;
  final String unit;
  final List<int> options;
  final Function(int?) onSelected;

  const _FilterDialog({
    required this.title,
    required this.currentValue,
    required this.unit,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(
        title,
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Any',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            trailing: currentValue == null
                ? Icon(Icons.check, color: AppColors.primaryGreen)
                : null,
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
          ...options.map((value) => ListTile(
                title: Text(
                  '$value $unit',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                trailing: currentValue == value
                    ? Icon(Icons.check, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  onSelected(value);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}
