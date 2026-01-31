/// Dietary restrictions and food preferences model
class DietaryRestriction {
  final String id;
  final String name;
  final String category; // 'allergy', 'preference', 'religious', 'health'
  final List<String> excludedIngredients;
  final String? description;
  final bool isActive;

  const DietaryRestriction({
    required this.id,
    required this.name,
    required this.category,
    required this.excludedIngredients,
    this.description,
    this.isActive = true,
  });

  DietaryRestriction copyWith({
    String? id,
    String? name,
    String? category,
    List<String>? excludedIngredients,
    String? description,
    bool? isActive,
  }) {
    return DietaryRestriction(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      excludedIngredients: excludedIngredients ?? this.excludedIngredients,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'excludedIngredients': excludedIngredients,
      'description': description,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory DietaryRestriction.fromJson(Map<String, dynamic> json) {
    return DietaryRestriction(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      excludedIngredients: (json['excludedIngredients'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList(),
      description: json['description'] as String?,
      isActive: (json['isActive'] as int) == 1,
    );
  }
}

/// Predefined dietary restrictions
class PredefinedRestrictions {
  static const List<DietaryRestriction> all = [
    // Religious restrictions
    DietaryRestriction(
      id: 'no_pork',
      name: 'No Pork',
      category: 'religious',
      excludedIngredients: [
        'pork',
        'bacon',
        'ham',
        'prosciutto',
        'pancetta',
        'sausage',
        'pork chop',
        'pork belly',
        'lard',
        'gelatin',
      ],
      description: 'Excludes all pork products (Halal/Kosher)',
    ),
    DietaryRestriction(
      id: 'no_alcohol',
      name: 'No Alcohol',
      category: 'religious',
      excludedIngredients: [
        'wine',
        'beer',
        'whiskey',
        'vodka',
        'rum',
        'sake',
        'champagne',
        'liqueur',
        'brandy',
      ],
      description: 'Excludes all alcoholic ingredients',
    ),
    DietaryRestriction(
      id: 'halal',
      name: 'Halal',
      category: 'religious',
      excludedIngredients: [
        'pork',
        'bacon',
        'ham',
        'alcohol',
        'wine',
        'beer',
        'gelatin',
        'lard',
      ],
      description: 'Follows Islamic dietary laws',
    ),

    // Common allergies
    DietaryRestriction(
      id: 'no_dairy',
      name: 'Dairy-Free',
      category: 'allergy',
      excludedIngredients: [
        'milk',
        'cheese',
        'butter',
        'cream',
        'yogurt',
        'whey',
        'casein',
        'lactose',
        'ghee',
      ],
      description: 'Lactose intolerance or dairy allergy',
    ),
    DietaryRestriction(
      id: 'no_gluten',
      name: 'Gluten-Free',
      category: 'allergy',
      excludedIngredients: [
        'wheat',
        'barley',
        'rye',
        'bread',
        'pasta',
        'flour',
        'couscous',
        'semolina',
      ],
      description: 'Celiac disease or gluten sensitivity',
    ),
    DietaryRestriction(
      id: 'no_nuts',
      name: 'Nut-Free',
      category: 'allergy',
      excludedIngredients: [
        'peanuts',
        'almonds',
        'cashews',
        'walnuts',
        'pecans',
        'pistachios',
        'hazelnuts',
        'macadamia',
        'peanut butter',
        'almond butter',
      ],
      description: 'Nut allergy',
    ),
    DietaryRestriction(
      id: 'no_shellfish',
      name: 'Shellfish-Free',
      category: 'allergy',
      excludedIngredients: [
        'shrimp',
        'crab',
        'lobster',
        'crayfish',
        'oyster',
        'clam',
        'mussel',
        'scallop',
      ],
      description: 'Shellfish allergy',
    ),
    DietaryRestriction(
      id: 'no_soy',
      name: 'Soy-Free',
      category: 'allergy',
      excludedIngredients: [
        'soy',
        'tofu',
        'soy sauce',
        'edamame',
        'tempeh',
        'miso',
        'soy milk',
      ],
      description: 'Soy allergy',
    ),

    // Dietary preferences
    DietaryRestriction(
      id: 'vegetarian',
      name: 'Vegetarian',
      category: 'preference',
      excludedIngredients: [
        'meat',
        'chicken',
        'beef',
        'pork',
        'lamb',
        'fish',
        'seafood',
        'poultry',
        'turkey',
        'duck',
        'gelatin',
      ],
      description: 'No meat or fish',
    ),
    DietaryRestriction(
      id: 'vegan',
      name: 'Vegan',
      category: 'preference',
      excludedIngredients: [
        'meat',
        'chicken',
        'beef',
        'pork',
        'fish',
        'seafood',
        'dairy',
        'milk',
        'cheese',
        'butter',
        'eggs',
        'honey',
        'gelatin',
        'whey',
      ],
      description: 'No animal products',
    ),
    DietaryRestriction(
      id: 'pescatarian',
      name: 'Pescatarian',
      category: 'preference',
      excludedIngredients: [
        'chicken',
        'beef',
        'pork',
        'lamb',
        'turkey',
        'duck',
        'meat',
      ],
      description: 'Fish allowed, but no other meat',
    ),
    DietaryRestriction(
      id: 'no_fish',
      name: 'No Fish',
      category: 'preference',
      excludedIngredients: [
        'fish',
        'salmon',
        'tuna',
        'cod',
        'tilapia',
        'trout',
        'mackerel',
        'sardines',
        'anchovy',
        'fish sauce',
      ],
      description: 'Excludes all fish and fish products',
    ),

    // Specific vegetables/ingredients
    DietaryRestriction(
      id: 'no_onion_garlic',
      name: 'No Onion/Garlic',
      category: 'preference',
      excludedIngredients: [
        'onion',
        'garlic',
        'shallot',
        'leek',
        'scallion',
        'chives',
      ],
      description: 'Jain diet or digestive sensitivity',
    ),
    DietaryRestriction(
      id: 'no_mushrooms',
      name: 'No Mushrooms',
      category: 'preference',
      excludedIngredients: [
        'mushroom',
        'shiitake',
        'portobello',
        'button mushroom',
        'oyster mushroom',
      ],
      description: 'Excludes all mushroom varieties',
    ),
    DietaryRestriction(
      id: 'no_eggplant',
      name: 'No Eggplant',
      category: 'preference',
      excludedIngredients: [
        'eggplant',
        'aubergine',
      ],
      description: 'Excludes eggplant',
    ),

    // Health-based
    DietaryRestriction(
      id: 'low_sodium',
      name: 'Low Sodium',
      category: 'health',
      excludedIngredients: [
        'salt',
        'soy sauce',
        'fish sauce',
        'pickles',
        'olives',
        'salted butter',
      ],
      description: 'For hypertension management',
    ),
    DietaryRestriction(
      id: 'low_sugar',
      name: 'Low Sugar',
      category: 'health',
      excludedIngredients: [
        'sugar',
        'honey',
        'syrup',
        'candy',
        'chocolate',
        'sweet',
      ],
      description: 'For diabetes management',
    ),
  ];

  /// Get restrictions by category
  static List<DietaryRestriction> getByCategory(String category) {
    return all.where((r) => r.category == category).toList();
  }

  /// Get restriction by ID
  static DietaryRestriction? getById(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all excluded ingredients from multiple restrictions
  static List<String> getCombinedExclusions(List<String> restrictionIds) {
    final exclusions = <String>{};
    for (final id in restrictionIds) {
      final restriction = getById(id);
      if (restriction != null) {
        exclusions.addAll(restriction.excludedIngredients);
      }
    }
    return exclusions.toList();
  }
}

/// User's dietary profile
class DietaryProfile {
  final List<String> activeRestrictionIds;
  final List<String> customExclusions; // Custom ingredients to exclude
  final String? notes;

  const DietaryProfile({
    this.activeRestrictionIds = const [],
    this.customExclusions = const [],
    this.notes,
  });

  /// Get all excluded ingredients (predefined + custom)
  List<String> getAllExclusions() {
    final predefined =
        PredefinedRestrictions.getCombinedExclusions(activeRestrictionIds);
    return [...predefined, ...customExclusions];
  }

  /// Get active restrictions
  List<DietaryRestriction> getActiveRestrictions() {
    return activeRestrictionIds
        .map((id) => PredefinedRestrictions.getById(id))
        .whereType<DietaryRestriction>()
        .toList();
  }

  DietaryProfile copyWith({
    List<String>? activeRestrictionIds,
    List<String>? customExclusions,
    String? notes,
  }) {
    return DietaryProfile(
      activeRestrictionIds: activeRestrictionIds ?? this.activeRestrictionIds,
      customExclusions: customExclusions ?? this.customExclusions,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeRestrictionIds': activeRestrictionIds.join(','),
      'customExclusions': customExclusions.join(','),
      'notes': notes,
    };
  }

  factory DietaryProfile.fromJson(Map<String, dynamic> json) {
    return DietaryProfile(
      activeRestrictionIds: (json['activeRestrictionIds'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      customExclusions: (json['customExclusions'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  /// Empty profile
  factory DietaryProfile.empty() {
    return const DietaryProfile();
  }
}
