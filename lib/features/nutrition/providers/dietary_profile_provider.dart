import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../data/models/dietary_restriction.dart';

// ============================================================================
// State Management
// ============================================================================

/// State for dietary profile management
class DietaryProfileState {
  final DietaryProfile profile;
  final bool isLoading;
  final String? error;
  final List<DietaryRestriction> availableRestrictions;
  final Map<String, List<DietaryRestriction>> restrictionsByCategory;

  const DietaryProfileState({
    this.profile = const DietaryProfile(),
    this.isLoading = false,
    this.error,
    List<DietaryRestriction>? availableRestrictions,
    Map<String, List<DietaryRestriction>>? restrictionsByCategory,
  })  : availableRestrictions = availableRestrictions ?? const [],
        restrictionsByCategory = restrictionsByCategory ?? const {};

  DietaryProfileState copyWith({
    DietaryProfile? profile,
    bool? isLoading,
    String? error,
    List<DietaryRestriction>? availableRestrictions,
    Map<String, List<DietaryRestriction>>? restrictionsByCategory,
  }) {
    return DietaryProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      availableRestrictions: availableRestrictions ?? this.availableRestrictions,
      restrictionsByCategory: restrictionsByCategory ?? this.restrictionsByCategory,
    );
  }

  /// Get active restrictions
  List<DietaryRestriction> get activeRestrictions {
    return profile.getActiveRestrictions();
  }

  /// Get all excluded ingredients
  List<String> get allExcludedIngredients {
    return profile.getAllExclusions();
  }

  /// Check if a restriction is active
  bool isRestrictionActive(String restrictionId) {
    return profile.activeRestrictionIds.contains(restrictionId);
  }
}

/// Notifier for dietary profile management
class DietaryProfileNotifier extends StateNotifier<DietaryProfileState> {
  DietaryProfileNotifier(this._ref) : super(const DietaryProfileState()) {
    _initialize();
  }

  final Ref _ref;

  /// Initialize with available restrictions and load user's profile
  Future<void> _initialize() async {
    try {
      // Load all available restrictions
      final allRestrictions = PredefinedRestrictions.all;
      final categories = <String, List<DietaryRestriction>>{};

      // Group by category
      for (var category in ['religious', 'allergy', 'preference', 'health']) {
        categories[category] = PredefinedRestrictions.getByCategory(category);
      }

      state = state.copyWith(
        availableRestrictions: allRestrictions,
        restrictionsByCategory: categories,
      );

      // Load user's dietary profile
      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load dietary profile from user profile
  Future<void> loadProfile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      state = state.copyWith(
        profile: userProfile.dietaryProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Toggle a dietary restriction
  Future<void> toggleRestriction(String restrictionId) async {
    try {
      final activeIds = List<String>.from(state.profile.activeRestrictionIds);

      if (activeIds.contains(restrictionId)) {
        activeIds.remove(restrictionId);
      } else {
        activeIds.add(restrictionId);
      }

      final updatedProfile = state.profile.copyWith(
        activeRestrictionIds: activeIds,
      );

      state = state.copyWith(profile: updatedProfile);

      // Save to user profile
      await _saveToUserProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add multiple restrictions at once
  Future<void> addRestrictions(List<String> restrictionIds) async {
    try {
      final activeIds = Set<String>.from(state.profile.activeRestrictionIds);
      activeIds.addAll(restrictionIds);

      final updatedProfile = state.profile.copyWith(
        activeRestrictionIds: activeIds.toList(),
      );

      state = state.copyWith(profile: updatedProfile);

      // Save to user profile
      await _saveToUserProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove multiple restrictions at once
  Future<void> removeRestrictions(List<String> restrictionIds) async {
    try {
      final activeIds = Set<String>.from(state.profile.activeRestrictionIds);
      activeIds.removeAll(restrictionIds);

      final updatedProfile = state.profile.copyWith(
        activeRestrictionIds: activeIds.toList(),
      );

      state = state.copyWith(profile: updatedProfile);

      // Save to user profile
      await _saveToUserProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear all restrictions
  Future<void> clearAllRestrictions() async {
    try {
      final updatedProfile = state.profile.copyWith(
        activeRestrictionIds: [],
      );

      state = state.copyWith(profile: updatedProfile);

      // Save to user profile
      await _saveToUserProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add custom excluded ingredient
  Future<void> addCustomExclusion(String ingredient) async {
    try {
      if (ingredient.trim().isEmpty) return;

      final customExclusions = List<String>.from(state.profile.customExclusions);
      
      // Avoid duplicates
      if (!customExclusions.contains(ingredient.toLowerCase())) {
        customExclusions.add(ingredient.toLowerCase());

        final updatedProfile = state.profile.copyWith(
          customExclusions: customExclusions,
        );

        state = state.copyWith(profile: updatedProfile);

        // Save to user profile
        await _saveToUserProfile(updatedProfile);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove custom excluded ingredient
  Future<void> removeCustomExclusion(String ingredient) async {
    try {
      final customExclusions = List<String>.from(state.profile.customExclusions);
      customExclusions.remove(ingredient.toLowerCase());

      final updatedProfile = state.profile.copyWith(
        customExclusions: customExclusions,
      );

      state = state.copyWith(profile: updatedProfile);

      // Save to user profile
      await _saveToUserProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update notes
  Future<void> updateNotes(String notes) async {
    try {
      final updatedProfile = state.profile.copyWith(
        notes: notes,
      );

      state = state.copyWith(profile: updatedProfile);

      // Save to user profile
      await _saveToUserProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Save dietary profile to user profile
  Future<void> _saveToUserProfile(DietaryProfile dietaryProfile) async {
    try {
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final updatedUserProfile = userProfile.copyWith(
        dietaryProfile: dietaryProfile,
      );

      // Note: UserProfile updates would need proper StateNotifier implementation
      // For now, dietary profile is saved locally
      // TODO: Integrate with user profile management when available
    } catch (e) {
      throw Exception('Failed to save dietary profile: $e');
    }
  }

  /// Get restrictions by category
  List<DietaryRestriction> getRestrictionsByCategory(String category) {
    return state.restrictionsByCategory[category] ?? [];
  }

  /// Search restrictions
  List<DietaryRestriction> searchRestrictions(String query) {
    if (query.isEmpty) return state.availableRestrictions;

    final lowerQuery = query.toLowerCase();
    return state.availableRestrictions.where((restriction) {
      return restriction.name.toLowerCase().contains(lowerQuery) ||
          (restriction.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get restriction by ID
  DietaryRestriction? getRestrictionById(String id) {
    return PredefinedRestrictions.getById(id);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh profile
  Future<void> refresh() async {
    await loadProfile();
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main provider for dietary profile state
final dietaryProfileProvider =
    StateNotifierProvider<DietaryProfileNotifier, DietaryProfileState>((ref) {
  return DietaryProfileNotifier(ref);
});

/// Provider for active restrictions
final activeRestrictionsProvider = Provider<List<DietaryRestriction>>((ref) {
  final state = ref.watch(dietaryProfileProvider);
  return state.activeRestrictions;
});

/// Provider for all excluded ingredients
final excludedIngredientsProvider = Provider<List<String>>((ref) {
  final state = ref.watch(dietaryProfileProvider);
  return state.allExcludedIngredients;
});

/// Provider for restrictions by category
final restrictionsByCategoryProvider =
    Provider.family<List<DietaryRestriction>, String>((ref, category) {
  final state = ref.watch(dietaryProfileProvider);
  return state.restrictionsByCategory[category] ?? [];
});

/// Provider to check if any restrictions are active
final hasActiveRestrictionsProvider = Provider<bool>((ref) {
  final state = ref.watch(dietaryProfileProvider);
  return state.profile.activeRestrictionIds.isNotEmpty ||
      state.profile.customExclusions.isNotEmpty;
});

/// Provider to check if a specific restriction is active
final isRestrictionActiveProvider =
    Provider.family<bool, String>((ref, restrictionId) {
  final state = ref.watch(dietaryProfileProvider);
  return state.isRestrictionActive(restrictionId);
});

/// Provider for custom exclusions count
final customExclusionsCountProvider = Provider<int>((ref) {
  final state = ref.watch(dietaryProfileProvider);
  return state.profile.customExclusions.length;
});

/// Provider for total restrictions count (predefined + custom)
final totalRestrictionsCountProvider = Provider<int>((ref) {
  final state = ref.watch(dietaryProfileProvider);
  return state.profile.activeRestrictionIds.length +
      state.profile.customExclusions.length;
});
