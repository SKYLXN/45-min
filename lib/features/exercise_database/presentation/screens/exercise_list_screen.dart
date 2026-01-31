import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/exercise_card.dart';
import '../widgets/exercise_filter_chip.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/models/exercise.dart';
import 'exercise_detail_screen.dart';

/// Main screen for browsing exercises
class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMuscle;
  String? _selectedDifficulty;
  bool? _compoundOnly;
  bool _isGridView = false;
  
  final List<String> _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Abs',
  ];

  final List<String> _difficulties = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseRepository = ExerciseRepository();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B2D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Exercise Library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: const Color(0xFF00FF88),
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFF151B2D),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: const TextStyle(color: Color(0xFFB0B8C8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF88)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFFB0B8C8)),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0A0E1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Muscle group filters
          Container(
            height: 50,
            color: const Color(0xFF151B2D),
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final muscle = _muscleGroups[index];
                final isAll = muscle == 'All';
                final isSelected = isAll
                    ? _selectedMuscle == null
                    : _selectedMuscle == muscle;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ExerciseFilterChip(
                    label: muscle,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedMuscle = isAll ? null : muscle;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Difficulty filters
          Container(
            height: 50,
            color: const Color(0xFF151B2D),
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _difficulties.length + 1,
              itemBuilder: (context, index) {
                if (index == _difficulties.length) {
                  // Compound filter
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ExerciseFilterChip(
                      label: 'Compound Only',
                      isSelected: _compoundOnly == true,
                      icon: Icons.bolt,
                      onTap: () {
                        setState(() {
                          _compoundOnly = _compoundOnly == true ? null : true;
                        });
                      },
                    ),
                  );
                }

                final difficulty = _difficulties[index];
                final isAll = difficulty == 'All';
                final isSelected = isAll
                    ? _selectedDifficulty == null
                    : _selectedDifficulty == difficulty;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ExerciseFilterChip(
                    label: difficulty,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedDifficulty = isAll ? null : difficulty;
                      });
                    },
                    selectedColor: _getDifficultyColor(difficulty),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Color(0xFF151B2D)),

          // Exercise list
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: _fetchFilteredExercises(exerciseRepository),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00FF88),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading exercises',
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                            color: Color(0xFFB0B8C8),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final exercises = snapshot.data ?? [];

                if (exercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: const Color(0xFFB0B8C8).withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No exercises found',
                          style: TextStyle(
                            color: Color(0xFFB0B8C8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            color: Color(0xFFB0B8C8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return ExerciseCard(
                        exercise: exercise,
                        isGridView: true,
                        onTap: () => _navigateToDetail(context, exercise),
                      );
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return ExerciseCard(
                      exercise: exercise,
                      isGridView: false,
                      onTap: () => _navigateToDetail(context, exercise),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Exercise>> _fetchFilteredExercises(ExerciseRepository repository) async {
    List<Exercise> exercises;

    if (_searchQuery.isNotEmpty) {
      exercises = await repository.searchExercises(_searchQuery);
    } else if (_selectedMuscle != null || _selectedDifficulty != null || _compoundOnly != null) {
      exercises = await repository.getExercisesFiltered(
        muscleGroup: _selectedMuscle,
        difficulty: _selectedDifficulty,
        isCompound: _compoundOnly,
      );
    } else {
      exercises = await repository.getAllExercises();
    }

    return exercises;
  }

  void _navigateToDetail(BuildContext context, Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF00FF88);
      case 'intermediate':
        return const Color(0xFFFFD700);
      case 'advanced':
        return Colors.red;
      default:
        return const Color(0xFFB0B8C8);
    }
  }
}
