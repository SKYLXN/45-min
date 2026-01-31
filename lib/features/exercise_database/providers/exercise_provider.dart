import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/models/exercise.dart';

// ============================================================================
// Repository Provider
// ============================================================================

/// Singleton provider for ExerciseRepository
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

// ============================================================================
// Data Providers
// ============================================================================

/// Provider for all exercises
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return await repository.getAllExercises();
});

/// Provider for exercises by muscle group
final exercisesByMuscleProvider = FutureProvider.family<List<Exercise>, String>(
  (ref, muscleGroup) async {
    final repository = ref.watch(exerciseRepositoryProvider);
    return await repository.getExercisesByMuscle(muscleGroup);
  },
);

/// Provider for exercises by equipment
final exercisesByEquipmentProvider = FutureProvider.family<List<Exercise>, List<String>>(
  (ref, equipment) async {
    final repository = ref.watch(exerciseRepositoryProvider);
    return await repository.getExercisesByEquipment(equipment);
  },
);

/// Provider for compound exercises
final compoundExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return await repository.getCompoundExercises();
});

/// Provider for isolation exercises
final isolationExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return await repository.getIsolationExercises();
});

/// Provider for alternative exercises
final alternativeExercisesProvider = FutureProvider.family<List<Exercise>, String>(
  (ref, exerciseId) async {
    final repository = ref.watch(exerciseRepositoryProvider);
    return await repository.getAlternativeExercises(exerciseId);
  },
);

/// Provider to check if exercises are seeded
final hasExercisesProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return await repository.hasExercises();
});

// ============================================================================
// State Notifier for Exercise Management
// ============================================================================

/// Filters for exercise list
class ExerciseFilters {
  final String? muscleGroup;
  final List<String>? equipment;
  final String? difficulty;
  final bool? isCompound;
  final String? searchQuery;

  const ExerciseFilters({
    this.muscleGroup,
    this.equipment,
    this.difficulty,
    this.isCompound,
    this.searchQuery,
  });

  ExerciseFilters copyWith({
    String? muscleGroup,
    List<String>? equipment,
    String? difficulty,
    bool? isCompound,
    String? searchQuery,
  }) {
    return ExerciseFilters(
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      isCompound: isCompound ?? this.isCompound,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Clear all filters
  ExerciseFilters clear() {
    return const ExerciseFilters();
  }

  /// Check if any filters are active
  bool get hasActiveFilters =>
      muscleGroup != null ||
      equipment != null ||
      difficulty != null ||
      isCompound != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);
}

/// State for exercise list management
class ExerciseListState {
  final List<Exercise> exercises;
  final List<Exercise> filteredExercises;
  final ExerciseFilters filters;
  final Exercise? selectedExercise;
  final bool isLoading;
  final String? error;

  const ExerciseListState({
    this.exercises = const [],
    this.filteredExercises = const [],
    this.filters = const ExerciseFilters(),
    this.selectedExercise,
    this.isLoading = false,
    this.error,
  });

  ExerciseListState copyWith({
    List<Exercise>? exercises,
    List<Exercise>? filteredExercises,
    ExerciseFilters? filters,
    Exercise? selectedExercise,
    bool? isLoading,
    String? error,
  }) {
    return ExerciseListState(
      exercises: exercises ?? this.exercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
      filters: filters ?? this.filters,
      selectedExercise: selectedExercise ?? this.selectedExercise,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing exercise list and filters
class ExerciseListNotifier extends StateNotifier<ExerciseListState> {
  final ExerciseRepository _repository;

  ExerciseListNotifier(this._repository) : super(const ExerciseListState());

  /// Load all exercises
  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final exercises = await _repository.getAllExercises();
      state = state.copyWith(
        exercises: exercises,
        filteredExercises: exercises,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load exercises: $e',
      );
    }
  }

  /// Apply filters to exercise list
  void _applyFilters() {
    var filtered = state.exercises;

    // Apply search query
    if (state.filters.searchQuery != null && state.filters.searchQuery!.isNotEmpty) {
      final query = state.filters.searchQuery!.toLowerCase();
      filtered = filtered.where((e) => e.name.toLowerCase().contains(query)).toList();
    }

    // Apply muscle group filter
    if (state.filters.muscleGroup != null) {
      filtered = filtered.where((e) => e.muscleGroup == state.filters.muscleGroup).toList();
    }

    // Apply equipment filter
    if (state.filters.equipment != null && state.filters.equipment!.isNotEmpty) {
      filtered = filtered.where((e) {
        if (e.isBodyweightOnly) return true;
        return e.equipmentRequired.every(
          (req) => state.filters.equipment!.contains(req) || req == 'bodyweight',
        );
      }).toList();
    }

    // Apply difficulty filter
    if (state.filters.difficulty != null) {
      filtered = filtered.where((e) => e.difficulty == state.filters.difficulty).toList();
    }

    // Apply compound/isolation filter
    if (state.filters.isCompound != null) {
      filtered = filtered.where((e) => e.isCompound == state.filters.isCompound).toList();
    }

    state = state.copyWith(filteredExercises: filtered);
  }

  /// Update filters
  void updateFilters(ExerciseFilters filters) {
    state = state.copyWith(filters: filters);
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(filters: const ExerciseFilters());
    _applyFilters();
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(
      filters: state.filters.copyWith(searchQuery: query),
    );
    _applyFilters();
  }

  /// Set muscle group filter
  void setMuscleGroup(String? muscleGroup) {
    state = state.copyWith(
      filters: state.filters.copyWith(muscleGroup: muscleGroup),
    );
    _applyFilters();
  }

  /// Set equipment filter
  void setEquipment(List<String>? equipment) {
    state = state.copyWith(
      filters: state.filters.copyWith(equipment: equipment),
    );
    _applyFilters();
  }

  /// Select exercise
  void selectExercise(Exercise exercise) {
    state = state.copyWith(selectedExercise: exercise);
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(selectedExercise: null);
  }

  /// Get alternative exercises for current selection
  Future<List<Exercise>> getAlternatives() async {
    if (state.selectedExercise == null) return [];
    try {
      return await _repository.getAlternativeExercises(state.selectedExercise!.id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to get alternatives: $e');
      return [];
    }
  }
}

/// Provider for exercise list state management
final exerciseListProvider = StateNotifierProvider<ExerciseListNotifier, ExerciseListState>(
  (ref) {
    final repository = ref.watch(exerciseRepositoryProvider);
    return ExerciseListNotifier(repository);
  },
);
