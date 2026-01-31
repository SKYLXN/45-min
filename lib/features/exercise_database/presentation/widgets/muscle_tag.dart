import 'package:flutter/material.dart';

/// Color-coded badge for muscle groups
class MuscleTag extends StatelessWidget {
  final String muscleGroup;
  final bool small;

  const MuscleTag({
    super.key,
    required this.muscleGroup,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorData = _getColorForMuscle(muscleGroup);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: colorData.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorData.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            colorData.icon,
            size: small ? 12 : 14,
            color: colorData.color,
          ),
          const SizedBox(width: 4),
          Text(
            muscleGroup.toUpperCase(),
            style: TextStyle(
              color: colorData.color,
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  _MuscleColorData _getColorForMuscle(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':
        return _MuscleColorData(
          color: const Color(0xFFFF6B6B),
          icon: Icons.favorite,
        );
      case 'back':
        return _MuscleColorData(
          color: const Color(0xFF4ECDC4),
          icon: Icons.accessibility_new,
        );
      case 'shoulders':
        return _MuscleColorData(
          color: const Color(0xFFFFD93D),
          icon: Icons.sports_gymnastics,
        );
      case 'arms':
        return _MuscleColorData(
          color: const Color(0xFFFF8B94),
          icon: Icons.sports_handball,
        );
      case 'legs':
        return _MuscleColorData(
          color: const Color(0xFF95E1D3),
          icon: Icons.directions_run,
        );
      case 'abs':
        return _MuscleColorData(
          color: const Color(0xFFA8E6CF),
          icon: Icons.grid_4x4,
        );
      default:
        return _MuscleColorData(
          color: const Color(0xFFB0B8C8),
          icon: Icons.fitness_center,
        );
    }
  }
}

class _MuscleColorData {
  final Color color;
  final IconData icon;

  _MuscleColorData({required this.color, required this.icon});
}
