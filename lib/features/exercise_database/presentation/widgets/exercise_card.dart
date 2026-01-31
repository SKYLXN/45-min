import 'package:flutter/material.dart';
import '../../data/models/exercise.dart';
import 'muscle_tag.dart';

/// Card widget displaying exercise summary
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final bool isGridView;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151B2D),
      margin: EdgeInsets.all(isGridView ? 4 : 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: isGridView ? _buildGridView() : _buildListView(),
      ),
    );
  }

  Widget _buildGridView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: exercise.gifUrl != null
                  ? Image.asset(
                      exercise.gifUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),
        ),
        // Exercise info
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              MuscleTag(muscleGroup: exercise.muscleGroup),
              const SizedBox(height: 4),
              _buildDifficultyBadge(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: exercise.gifUrl != null
                ? Image.asset(
                    exercise.gifUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                  )
                : _buildPlaceholderIcon(),
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                MuscleTag(muscleGroup: exercise.muscleGroup),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildDifficultyBadge(),
                    const SizedBox(width: 8),
                    if (exercise.isCompound)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF88).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'COMPOUND',
                          style: TextStyle(
                            color: Color(0xFF00FF88),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.equipmentRequired.isEmpty
                      ? 'Bodyweight'
                      : exercise.equipmentRequired.join(', '),
                  style: const TextStyle(
                    color: Color(0xFFB0B8C8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Chevron
          const Icon(
            Icons.chevron_right,
            color: Color(0xFFB0B8C8),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(
      _getIconForMuscleGroup(exercise.muscleGroup),
      size: 40,
      color: const Color(0xFF00FF88).withOpacity(0.3),
    );
  }

  Widget _buildDifficultyBadge() {
    Color color;
    switch (exercise.difficulty.toLowerCase()) {
      case 'beginner':
        color = const Color(0xFF00FF88);
        break;
      case 'intermediate':
        color = const Color(0xFFFFD700);
        break;
      case 'advanced':
        color = Colors.red;
        break;
      default:
        color = const Color(0xFFB0B8C8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        exercise.difficulty.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getIconForMuscleGroup(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.accessibility_new;
      case 'shoulders':
        return Icons.sports_gymnastics;
      case 'arms':
        return Icons.sports_handball;
      case 'legs':
        return Icons.directions_run;
      case 'abs':
        return Icons.grid_4x4;
      default:
        return Icons.fitness_center;
    }
  }
}
