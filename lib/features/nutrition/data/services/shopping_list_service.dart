import '../models/weekly_meal_plan.dart';
import '../models/meal.dart';

/// Service for managing shopping lists from meal plans
class ShoppingListService {
  /// Generate shopping list from weekly meal plan
  Map<String, AggregatedIngredient> generateShoppingList(
    WeeklyMealPlan weeklyPlan,
  ) {
    return weeklyPlan.getShoppingList();
  }

  /// Generate shopping list from multiple weekly plans
  Map<String, AggregatedIngredient> generateCombinedShoppingList(
    List<WeeklyMealPlan> plans,
  ) {
    final combinedMap = <String, AggregatedIngredient>{};

    for (final plan in plans) {
      final planList = plan.getShoppingList();
      
      for (final entry in planList.entries) {
        if (combinedMap.containsKey(entry.key)) {
          // Combine with existing ingredient
          final existing = combinedMap[entry.key]!;
          final ingredient = Ingredient(
            name: entry.value.name,
            amount: entry.value.totalAmount,
            unit: entry.value.unit,
          );
          combinedMap[entry.key] = existing.add(ingredient);
        } else {
          combinedMap[entry.key] = entry.value;
        }
      }
    }

    return combinedMap;
  }

  /// Group shopping list by category
  Map<String, List<AggregatedIngredient>> groupByCategory(
    Map<String, AggregatedIngredient> shoppingList,
  ) {
    final grouped = <String, List<AggregatedIngredient>>{
      'Produce': [],
      'Protein': [],
      'Dairy': [],
      'Grains': [],
      'Pantry': [],
      'Spices': [],
      'Other': [],
    };

    for (final ingredient in shoppingList.values) {
      final category = _categorizeIngredient(ingredient.name);
      grouped[category]!.add(ingredient);
    }

    // Remove empty categories
    grouped.removeWhere((key, value) => value.isEmpty);

    // Sort ingredients within each category alphabetically
    for (final category in grouped.keys) {
      grouped[category]!.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  }

  /// Categorize ingredient by name (simple heuristic)
  String _categorizeIngredient(String name) {
    final nameLower = name.toLowerCase();

    // Produce
    if (_isInCategory(nameLower, [
      'lettuce', 'tomato', 'onion', 'garlic', 'potato', 'carrot', 
      'broccoli', 'spinach', 'pepper', 'cucumber', 'celery', 'mushroom',
      'zucchini', 'eggplant', 'cabbage', 'kale', 'avocado', 'lemon',
      'lime', 'apple', 'banana', 'orange', 'berry', 'fruit', 'vegetable',
    ])) {
      return 'Produce';
    }

    // Protein
    if (_isInCategory(nameLower, [
      'chicken', 'beef', 'pork', 'turkey', 'fish', 'salmon', 'tuna',
      'shrimp', 'egg', 'tofu', 'tempeh', 'meat', 'steak', 'ground',
    ])) {
      return 'Protein';
    }

    // Dairy
    if (_isInCategory(nameLower, [
      'milk', 'cheese', 'yogurt', 'butter', 'cream', 'sour cream',
      'cottage cheese', 'mozzarella', 'cheddar', 'parmesan', 'feta',
    ])) {
      return 'Dairy';
    }

    // Grains
    if (_isInCategory(nameLower, [
      'rice', 'pasta', 'bread', 'flour', 'oat', 'quinoa', 'couscous',
      'noodle', 'tortilla', 'cereal', 'grain', 'wheat', 'barley',
    ])) {
      return 'Grains';
    }

    // Spices & Herbs
    if (_isInCategory(nameLower, [
      'salt', 'pepper', 'paprika', 'cumin', 'oregano', 'basil',
      'thyme', 'rosemary', 'cilantro', 'parsley', 'cinnamon', 'ginger',
      'curry', 'chili', 'spice', 'herb', 'bay leaf',
    ])) {
      return 'Spices';
    }

    // Pantry
    if (_isInCategory(nameLower, [
      'oil', 'olive oil', 'coconut oil', 'vinegar', 'soy sauce',
      'sauce', 'stock', 'broth', 'tomato paste', 'can', 'canned',
      'beans', 'chickpea', 'lentil', 'peanut butter', 'honey', 'sugar',
    ])) {
      return 'Pantry';
    }

    return 'Other';
  }

  /// Helper to check if name contains any keyword
  bool _isInCategory(String name, List<String> keywords) {
    return keywords.any((keyword) => name.contains(keyword));
  }

  /// Format shopping list as plain text
  String formatAsText(Map<String, AggregatedIngredient> shoppingList) {
    final grouped = groupByCategory(shoppingList);
    final buffer = StringBuffer();

    buffer.writeln('🛒 Shopping List\n');
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}\n');
    buffer.writeln('Total items: ${shoppingList.length}\n');
    buffer.writeln('━' * 40);
    buffer.writeln();

    for (final entry in grouped.entries) {
      buffer.writeln('📦 ${entry.key}');
      buffer.writeln('─' * 40);
      
      for (final ingredient in entry.value) {
        buffer.writeln('  ☐ ${ingredient.name} - ${ingredient.displayText}');
      }
      
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Format shopping list as markdown
  String formatAsMarkdown(Map<String, AggregatedIngredient> shoppingList) {
    final grouped = groupByCategory(shoppingList);
    final buffer = StringBuffer();

    buffer.writeln('# 🛒 Shopping List\n');
    buffer.writeln('**Generated:** ${DateTime.now().toString().split('.')[0]}\n');
    buffer.writeln('**Total items:** ${shoppingList.length}\n');
    buffer.writeln('---\n');

    for (final entry in grouped.entries) {
      buffer.writeln('## 📦 ${entry.key}\n');
      
      for (final ingredient in entry.value) {
        buffer.writeln('- [ ] **${ingredient.name}** - ${ingredient.displayText}');
      }
      
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get ingredient list for Apple Reminders (one item per line)
  List<String> getRemindersItems(Map<String, AggregatedIngredient> shoppingList) {
    final grouped = groupByCategory(shoppingList);
    final items = <String>[];

    for (final entry in grouped.entries) {
      // Add category header (will be shown in reminder notes)
      items.add('${entry.key}:');
      
      for (final ingredient in entry.value) {
        items.add('${ingredient.name} - ${ingredient.displayText}');
      }
    }

    return items;
  }

  /// Calculate estimated shopping cost (very rough estimate)
  double estimateTotalCost(Map<String, AggregatedIngredient> shoppingList) {
    // Very basic cost estimation - in production, use a proper pricing API
    double totalCost = 0.0;

    for (final ingredient in shoppingList.values) {
      final category = _categorizeIngredient(ingredient.name);
      final baseCost = _getBaseCostForCategory(category);
      
      // Multiply by amount (simplified, assumes per unit cost)
      totalCost += baseCost * (ingredient.totalAmount / 100); // Rough scaling
    }

    return totalCost;
  }

  /// Get base cost per category (in local currency)
  double _getBaseCostForCategory(String category) {
    switch (category) {
      case 'Protein':
        return 8.0; // Average per unit
      case 'Produce':
        return 3.0;
      case 'Dairy':
        return 4.0;
      case 'Grains':
        return 2.0;
      case 'Pantry':
        return 5.0;
      case 'Spices':
        return 3.0;
      default:
        return 3.0;
    }
  }

  /// Remove checked/completed items from shopping list
  Map<String, AggregatedIngredient> removeItems(
    Map<String, AggregatedIngredient> shoppingList,
    List<String> itemsToRemove,
  ) {
    final updated = Map<String, AggregatedIngredient>.from(shoppingList);
    
    for (final itemName in itemsToRemove) {
      updated.removeWhere((key, value) => 
        value.name.toLowerCase() == itemName.toLowerCase()
      );
    }
    
    return updated;
  }

  /// Merge multiple shopping lists (useful for combining weekly plans)
  Map<String, AggregatedIngredient> mergeLists(
    List<Map<String, AggregatedIngredient>> lists,
  ) {
    final merged = <String, AggregatedIngredient>{};

    for (final list in lists) {
      for (final entry in list.entries) {
        if (merged.containsKey(entry.key)) {
          final ingredient = Ingredient(
            name: entry.value.name,
            amount: entry.value.totalAmount,
            unit: entry.value.unit,
          );
          merged[entry.key] = merged[entry.key]!.add(ingredient);
        } else {
          merged[entry.key] = entry.value;
        }
      }
    }

    return merged;
  }

  /// Scale shopping list by multiplier (e.g., 1.5x for extra servings)
  Map<String, AggregatedIngredient> scaleList(
    Map<String, AggregatedIngredient> shoppingList,
    double multiplier,
  ) {
    return shoppingList.map((key, value) => MapEntry(
      key,
      value.copyWith(
        totalAmount: value.totalAmount * multiplier,
      ),
    ));
  }
}
