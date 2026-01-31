import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../exercise_database/data/models/exercise.dart';
import '../../../exercise_database/data/repositories/exercise_repository.dart';
import '../../../exercise_database/providers/exercise_provider.dart';
import '../../data/models/weekly_program.dart';

class ExerciseSwapDialog extends ConsumerStatefulWidget {
  final PlannedExercise currentExercise;
  final String muscleGroup;
  final Function(Exercise) onSwap;

  const ExerciseSwapDialog({
    super.key,
    required this.currentExercise,
    required this.muscleGroup,
    required this.onSwap,
  });

  @override
  ConsumerState<ExerciseSwapDialog> createState() =>
      _ExerciseSwapDialogState();
}

class _ExerciseSwapDialogState extends ConsumerState<ExerciseSwapDialog> {
  List<Exercise> _alternatives = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadAlternatives();
  }

  Future<void> _loadAlternatives() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(exerciseRepositoryProvider);
      
      // Get all exercises for the same muscle group
      final allExercises = await repository.getAllExercises();
      final alternatives = allExercises
          .where((e) =>
              e.muscleGroup == widget.muscleGroup &&
              e.id != widget.currentExercise.exercise.id)
          .toList();

      // Sort by category (compound first)
      alternatives.sort((a, b) {
        if (a.isCompound && !b.isCompound) return -1;
        if (!a.isCompound && b.isCompound) return 1;
        return a.name.compareTo(b.name);
      });

      setState(() {
        _alternatives = alternatives;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Exercise> get _filteredAlternatives {
    if (_selectedCategory == 'All') {
      return _alternatives;
    }
    return _alternatives
        .where((e) => (_selectedCategory == 'Compound' && e.isCompound) || 
                      (_selectedCategory == 'Isolation' && !e.isCompound))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Replace Exercise',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current: ${widget.currentExercise.exercise.name}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Category filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildCategoryChip('All'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Compound'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Isolation'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Divider(
              color: AppColors.textSecondary,
              height: 1,
              thickness: 0.5,
            ),

            // Exercise list
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                  ),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (_filteredAlternatives.isEmpty)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No alternative exercises found',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _filteredAlternatives.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final exercise = _filteredAlternatives[index];
                    return _buildExerciseTile(exercise);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : AppColors.textSecondary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected
                ? AppColors.backgroundDark
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseTile(Exercise exercise) {
    return InkWell(
      onTap: () {
        widget.onSwap(exercise);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Category indicator
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: exercise.isCompound
                    ? AppColors.primaryGreen
                    : AppColors.primaryGold,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        exercise.equipmentRequired.join(', '),
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        exercise.isCompound ? 'COMPOUND' : 'ISOLATION',
                        style: TextStyle(
                          color: exercise.isCompound
                              ? AppColors.primaryGreen
                              : AppColors.primaryGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Select icon
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
